import type { ChecklistStepId, PlantState } from "./types";
import { LIMITS } from "./constants";
import { pushLog } from "./reactor";

const TESTS: Record<ChecklistStepId, (s: PlantState) => boolean> = {
  control_power: (s) => s.controls.controlPower,
  condensate: (s) => s.controls.condensatePumpA && s.controls.condensatePumpB,
  hotwell: (s) => s.feedwater.hotwellLevel >= 60,
  deaerators: (s) =>
    s.feedwater.deaeratorALevel >= 60 &&
    s.feedwater.deaeratorBLevel >= 60 &&
    s.feedwater.deaeratorATemp >= LIMITS.deaeratorTempMin &&
    s.feedwater.deaeratorBTemp >= LIMITS.deaeratorTempMin,
  feedwater: (s) => s.controls.feedwaterPumpA && s.controls.feedwaterPumpB,
  coolant: (s) => s.controls.coolantPumpA && s.controls.coolantPumpB,
  recirc: (s) => s.controls.recircPumps,
  rods: (s) => s.controls.rodInsertion <= 70,
  steam_pressure: (s) => s.steam.steamPressure >= 40,
  main_steam_valve: (s) => s.controls.mainSteamValve >= 25,
  spin_turbine: (s) => s.turbine.rpm >= 3300,
  sync_generator: (s) => s.generator.synced,
  increase_load: (s) => s.generator.synced && s.generator.mw >= 100,
};

export function tickChecklist(state: PlantState) {
  let advanced = false;
  for (const id of Object.keys(TESTS) as ChecklistStepId[]) {
    if (!state.checklist[id] && TESTS[id](state)) {
      state.checklist[id] = true;
      advanced = true;
      pushLog(state, "info", `Checklist step complete: ${id.replace(/_/g, " ")}`);
    }
  }

  if (
    advanced &&
    state.checklist.increase_load &&
    state.stats.startupTime === null
  ) {
    state.stats.startupTime = state.simTime;
    pushLog(
      state,
      "info",
      `Startup complete in ${state.simTime.toFixed(1)}s — operator XP awarded.`,
    );
  }
}
