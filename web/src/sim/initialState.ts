import type { AlarmId, AlarmState, ChecklistStepId, PlantState } from "./types";
import { ALARM_DEFS, CHECKLIST_STEPS } from "./constants";

const emptyAlarms = (): Record<AlarmId, AlarmState> => {
  const out = {} as Record<AlarmId, AlarmState>;
  (Object.keys(ALARM_DEFS) as AlarmId[]).forEach((id) => {
    out[id] = { id, active: false, acknowledged: false, triggeredAt: 0 };
  });
  return out;
};

const emptyChecklist = (): Record<ChecklistStepId, boolean> => {
  const out = {} as Record<ChecklistStepId, boolean>;
  CHECKLIST_STEPS.forEach((s) => {
    out[s.id] = false;
  });
  return out;
};

export function makeInitialPlantState(): PlantState {
  return {
    difficulty: "training",
    simTime: 0,
    paused: false,
    controls: {
      controlPower: false,
      rodInsertion: 100,
      rodMode: "manual",
      recircPumps: false,
      coolantPumpA: false,
      coolantPumpB: false,
      feedwaterPumpA: false,
      feedwaterPumpB: false,
      condensatePumpA: false,
      condensatePumpB: false,
      makeupWaterPump: false,
      steamInletA: 0,
      steamInletB: 0,
      mainSteamValve: 0,
      bypassValve: 0,
      generatorSync: false,
      scramArmed: false,
      alarmAudio: true,
    },
    reactor: {
      power: 0,
      neutronFlux: 0,
      coreTemp: 35,
      corePressure: 1.5,
      coreWater: 50,
      scrammed: false,
      meltdown: false,
      meltdownProgress: 0,
    },
    coolant: {
      flowA: 0,
      flowB: 0,
      inletTempA: 25,
      outletTempA: 25,
      inletTempB: 25,
      outletTempB: 25,
      loopALevel: 100,
      loopBLevel: 100,
    },
    feedwater: {
      hotwellLevel: 30,
      deaeratorALevel: 20,
      deaeratorBLevel: 20,
      deaeratorATemp: 25,
      deaeratorBTemp: 25,
      feedwaterFlow: 0,
      cavitation: false,
    },
    steam: {
      steamPressure: 1.0,
      steamFlow: 0,
      bypassFlow: 0,
    },
    turbine: {
      rpm: 0,
      vibration: 0,
      tripped: false,
      syncReady: false,
    },
    generator: {
      mw: 0,
      targetMw: 250,
      transformerLoad: 0,
      synced: false,
    },
    stats: {
      stability: 100,
      uptime: 0,
      startupTime: null,
      alarmCount: 0,
      scramCount: 0,
      turbineTrips: 0,
      peakMw: 0,
      efficiency: 0,
      score: 0,
    },
    alarms: emptyAlarms(),
    faults: [],
    history: [],
    checklist: emptyChecklist(),
    log: [
      {
        t: 0,
        level: "info",
        text: "Console online. Argonne-1 reactor in cold-shutdown.",
      },
    ],
  };
}
