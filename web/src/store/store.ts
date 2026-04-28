import { create } from "zustand";
import type { Difficulty, PlantState, ChecklistStepId, SaveData } from "../sim/types";
import { makeInitialPlantState } from "../sim/initialState";
import { stepReactor, pushLog, clamp } from "../sim/reactor";
import { evaluateAlarms, ackAllAlarms } from "../sim/alarms";
import { tickFaults } from "../sim/faults";
import { tickScore } from "../sim/scoring";
import { tickChecklist } from "../sim/checklist";
import { DIFFICULTY_FACTORS, HISTORY_SECONDS, TICK_HZ } from "../sim/constants";
import { loadSave, reconcileSave, resetSave, writeSave } from "../sim/save";

export interface StoreState {
  plant: PlantState;
  save: SaveData;
  selectedScreen: ScreenId;

  setScreen: (id: ScreenId) => void;
  setDifficulty: (d: Difficulty) => void;
  setPaused: (p: boolean) => void;

  // Control mutators
  setControl: <K extends keyof PlantState["controls"]>(
    key: K,
    value: PlantState["controls"][K],
  ) => void;
  toggleControl: (key: ToggleControl) => void;

  // High-level actions
  scram: () => void;
  resetScram: () => void;
  resetTurbine: () => void;
  syncGenerator: () => void;
  ackAlarms: () => void;
  newSession: () => void;
  finishShift: () => void;
  toggleStep: (id: ChecklistStepId) => void;
  resetSaveData: () => void;

  // Engine
  tick: () => void;
}

export type ScreenId =
  | "overview"
  | "reactor"
  | "coolant"
  | "feedwater"
  | "turbine"
  | "alarms"
  | "checklist";

type ToggleControl =
  | "controlPower"
  | "recircPumps"
  | "coolantPumpA"
  | "coolantPumpB"
  | "feedwaterPumpA"
  | "feedwaterPumpB"
  | "condensatePumpA"
  | "condensatePumpB"
  | "makeupWaterPump"
  | "scramArmed"
  | "alarmAudio"
  | "rodMode";

export const useStore = create<StoreState>((set, get) => ({
  plant: makeInitialPlantState(),
  save: loadSave(),
  selectedScreen: "overview",

  setScreen: (id) => set({ selectedScreen: id }),
  setDifficulty: (d) =>
    set((s) => ({
      plant: { ...s.plant, difficulty: d },
    })),
  setPaused: (p) =>
    set((s) => ({
      plant: { ...s.plant, paused: p },
    })),

  setControl: (key, value) =>
    set((s) => ({
      plant: { ...s.plant, controls: { ...s.plant.controls, [key]: value } },
    })),

  toggleControl: (key) =>
    set((s) => {
      const controls = { ...s.plant.controls };
      if (key === "rodMode") {
        controls.rodMode = controls.rodMode === "auto" ? "manual" : "auto";
      } else {
        controls[key] = !controls[key];
      }
      return { plant: { ...s.plant, controls } };
    }),

  scram: () =>
    set((s) => {
      const plant = { ...s.plant };
      if (!plant.reactor.scrammed) {
        plant.reactor = { ...plant.reactor, scrammed: true };
        plant.controls = { ...plant.controls, rodInsertion: 100, rodMode: "manual", scramArmed: false };
        plant.stats = { ...plant.stats, scramCount: plant.stats.scramCount + 1 };
        pushLog(plant, "critical", "MANUAL SCRAM — rods fully inserted.");
      }
      return { plant };
    }),

  resetScram: () =>
    set((s) => {
      const plant = { ...s.plant };
      if (plant.reactor.scrammed && plant.reactor.coreTemp < 220) {
        plant.reactor = { ...plant.reactor, scrammed: false, meltdown: false, meltdownProgress: 0 };
        pushLog(plant, "info", "SCRAM reset. Reactor ready for re-startup.");
      } else if (plant.reactor.scrammed) {
        pushLog(plant, "warn", "Cannot reset SCRAM until core temp < 220°C.");
      }
      return { plant };
    }),

  resetTurbine: () =>
    set((s) => {
      const plant = { ...s.plant };
      if (plant.turbine.tripped && plant.turbine.rpm < 100) {
        plant.turbine = { ...plant.turbine, tripped: false };
        pushLog(plant, "info", "Turbine trip reset. Ready to spin up.");
      } else if (plant.turbine.tripped) {
        pushLog(plant, "warn", "Cannot reset turbine until RPM < 100.");
      }
      return { plant };
    }),

  syncGenerator: () =>
    set((s) => {
      const plant = { ...s.plant };
      if (plant.turbine.syncReady && !plant.turbine.tripped) {
        plant.controls = { ...plant.controls, generatorSync: true };
        plant.generator = { ...plant.generator, synced: true };
        pushLog(plant, "info", "Generator synchronised to grid.");
      } else {
        pushLog(plant, "warn", "Sync rejected — RPM out of band.");
      }
      return { plant };
    }),

  ackAlarms: () =>
    set((s) => {
      const plant = { ...s.plant };
      ackAllAlarms(plant);
      pushLog(plant, "info", "Alarms acknowledged.");
      return { plant };
    }),

  newSession: () =>
    set((s) => ({ plant: { ...makeInitialPlantState(), difficulty: s.plant.difficulty } })),

  finishShift: () =>
    set((s) => {
      const next = reconcileSave(s.save, s.plant);
      writeSave(next);
      const plant = { ...makeInitialPlantState(), difficulty: s.plant.difficulty };
      pushLog(plant, "info", "Shift archived. New session ready.");
      return { plant, save: next };
    }),

  toggleStep: (id) =>
    set((s) => ({
      plant: { ...s.plant, checklist: { ...s.plant.checklist, [id]: !s.plant.checklist[id] } },
    })),

  resetSaveData: () =>
    set(() => ({ save: resetSave() })),

  tick: () => {
    const { plant, save } = get();
    if (plant.paused) return;

    const factor = DIFFICULTY_FACTORS[plant.difficulty];
    const dt = (1 / TICK_HZ) * factor.rate;

    // Mutate a shallow clone so React-subscribed components re-render.
    const next: PlantState = {
      ...plant,
      controls: { ...plant.controls },
      reactor: { ...plant.reactor },
      coolant: { ...plant.coolant },
      feedwater: { ...plant.feedwater },
      steam: { ...plant.steam },
      turbine: { ...plant.turbine },
      generator: { ...plant.generator },
      stats: { ...plant.stats },
      alarms: { ...plant.alarms },
      faults: plant.faults.slice(),
      history: plant.history.slice(),
      checklist: { ...plant.checklist },
      log: plant.log.slice(),
    };

    tickFaults(next, dt);
    stepReactor({ state: next, dt, rateScale: factor.rate });
    evaluateAlarms(next);
    tickScore(next, dt);
    tickChecklist(next);

    // Auto SCRAM at meltdown
    if (next.reactor.coreTemp > 380 && !next.reactor.scrammed) {
      next.reactor.scrammed = true;
      next.controls.rodInsertion = 100;
      next.stats.scramCount += 1;
      pushLog(next, "critical", "AUTO-SCRAM — core temperature critical.");
    }

    // History buffer
    next.history.push({
      t: next.simTime,
      power: next.reactor.power,
      coreTemp: next.reactor.coreTemp,
      corePressure: next.reactor.corePressure,
      steamPressure: next.steam.steamPressure,
      rpm: next.turbine.rpm,
      mw: next.generator.mw,
      coreWater: next.reactor.coreWater,
    });
    const cutoff = next.simTime - HISTORY_SECONDS;
    while (next.history.length && next.history[0].t < cutoff) next.history.shift();

    // Periodically persist a partial save (best score / peak MW).
    let nextSave = save;
    if (Math.floor(next.simTime) % 10 === 0 && Math.floor(plant.simTime) !== Math.floor(next.simTime)) {
      nextSave = reconcileSave(save, next);
      writeSave(nextSave);
    }

    set({ plant: next, save: nextSave });
  },
}));

// Outside-the-component helper for sliders and clamps
export const setSlider =
  <K extends keyof PlantState["controls"]>(key: K) =>
  (value: number) =>
    useStore.getState().setControl(key, clamp(value, 0, 100) as PlantState["controls"][K]);
