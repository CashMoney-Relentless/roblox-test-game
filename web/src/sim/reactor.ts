import type { ActiveFault, PlantState } from "./types";
import { LIMITS } from "./constants";

// Generic helpers
export const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));
export const lerp = (a: number, b: number, t: number) => a + (b - a) * clamp(t, 0, 1);

export const hasFault = (faults: ActiveFault[], id: ActiveFault["id"]) =>
  faults.some((f) => f.id === id);

interface StepArgs {
  state: PlantState;
  dt: number; // simulated seconds
  rateScale: number; // difficulty rate scalar
}

// Runs one tick of physics; mutates `state` in place for cheapness because
// we always replace the slices that change inside the store.
export function stepReactor({ state, dt, rateScale }: StepArgs) {
  const c = state.controls;
  const r = state.reactor;
  const co = state.coolant;
  const fw = state.feedwater;
  const st = state.steam;
  const tu = state.turbine;
  const ge = state.generator;

  // ============ Coolant loops ============
  // Pump on requires control power.
  const pumpA = c.controlPower && c.coolantPumpA && !hasFault(state.faults, "pump_failure_a");
  const pumpB = c.controlPower && c.coolantPumpB && !hasFault(state.faults, "pump_failure_b");

  const targetFlowA = pumpA ? 4500 : 0;
  const targetFlowB = pumpB ? 4500 : 0;

  // Loop imbalance fault biases one of the loops down.
  const imbalance = hasFault(state.faults, "loop_imbalance");
  co.flowA = lerp(co.flowA, imbalance ? targetFlowA * 0.4 : targetFlowA, 0.08 * rateScale);
  co.flowB = lerp(co.flowB, imbalance ? targetFlowB * 1.05 : targetFlowB, 0.08 * rateScale);

  // Loop level slowly drains while pumping with low feedwater.
  const drainA = pumpA ? 0.06 : 0;
  const drainB = pumpB ? 0.06 : 0;
  // Recirc & makeup top up loops a bit.
  const refillA = c.makeupWaterPump ? 0.08 : 0;
  const refillB = c.makeupWaterPump ? 0.08 : 0;
  co.loopALevel = clamp(co.loopALevel - drainA + refillA, 0, 100);
  co.loopBLevel = clamp(co.loopBLevel - drainB + refillB, 0, 100);

  // ============ Hotwell / Deaerator / Feedwater ============
  // Condensate pumps move water hotwell -> deaerators
  const condA = c.controlPower && c.condensatePumpA;
  const condB = c.controlPower && c.condensatePumpB;
  const makeup = c.controlPower && c.makeupWaterPump;

  // Makeup water raises hotwell.
  if (makeup) fw.hotwellLevel += 0.6 * dt;
  if (condA) {
    const xfer = Math.min(0.45 * dt, fw.hotwellLevel);
    fw.hotwellLevel -= xfer;
    fw.deaeratorALevel += xfer;
  }
  if (condB) {
    const xfer = Math.min(0.45 * dt, fw.hotwellLevel);
    fw.hotwellLevel -= xfer;
    fw.deaeratorBLevel += xfer;
  }

  // Steam inlet valves heat deaerators if steam is available.
  const steamHeatRate = (valve: number) =>
    (valve / 100) * Math.min(1, st.steamPressure / 30) * 8 * dt;
  fw.deaeratorATemp = clamp(
    fw.deaeratorATemp - 0.05 * dt + steamHeatRate(c.steamInletA),
    20,
    180,
  );
  fw.deaeratorBTemp = clamp(
    fw.deaeratorBTemp - 0.05 * dt + steamHeatRate(c.steamInletB),
    20,
    180,
  );

  // Feedwater pumps move water deaerators -> core
  const fwA =
    c.controlPower &&
    c.feedwaterPumpA &&
    !hasFault(state.faults, "feedwater_interruption");
  const fwB =
    c.controlPower &&
    c.feedwaterPumpB &&
    !hasFault(state.faults, "feedwater_interruption");

  let feedFlow = 0;
  if (fwA && fw.deaeratorALevel > 5) {
    const draw = Math.min(0.55 * dt, fw.deaeratorALevel);
    fw.deaeratorALevel -= draw;
    feedFlow += draw;
  }
  if (fwB && fw.deaeratorBLevel > 5) {
    const draw = Math.min(0.55 * dt, fw.deaeratorBLevel);
    fw.deaeratorBLevel -= draw;
    feedFlow += draw;
  }
  fw.feedwaterFlow = lerp(fw.feedwaterFlow, feedFlow * 60, 0.2);

  // Cavitation when pumps run with too-low deaerator level.
  fw.cavitation =
    (fwA && fw.deaeratorALevel < 8) || (fwB && fw.deaeratorBLevel < 8);

  fw.hotwellLevel = clamp(fw.hotwellLevel, 0, 100);
  fw.deaeratorALevel = clamp(fw.deaeratorALevel, 0, 100);
  fw.deaeratorBLevel = clamp(fw.deaeratorBLevel, 0, 100);

  // Feedwater raises core water.
  r.coreWater = clamp(r.coreWater + feedFlow * 6 - fw.feedwaterFlow * 0.0005, 0, 100);

  // Steam production lowers core water proportional to steam flow.
  const boilOff = clamp(r.power / 100, 0, 1.2) * 0.8 * dt;
  r.coreWater = clamp(r.coreWater - boilOff, 0, 100);

  // ============ Reactor neutron / power dynamics ============
  // rodInsertion: 0 = withdrawn, 100 = fully inserted -> reactor critical when below ~80
  const reactivity = c.controlPower && !r.scrammed ? clamp((85 - c.rodInsertion) / 60, -0.2, 1.5) : -1.0;
  // recirc helps thermal coupling
  const recircBoost = c.recircPumps ? 1.0 : 0.6;
  // power converges toward target driven by reactivity, scaled by water presence
  const waterCoupling = clamp((r.coreWater - 15) / 70, 0, 1);
  const targetPower = clamp(reactivity * 110 * waterCoupling * recircBoost, 0, 130);
  // If scrammed, power decays quickly.
  if (r.scrammed) {
    r.power = lerp(r.power, 0, 0.04 * rateScale);
  } else {
    r.power = lerp(r.power, targetPower, 0.04 * rateScale);
  }
  r.neutronFlux = clamp(
    r.power * 11 + (Math.random() - 0.5) * (1 + r.power * 0.08),
    0,
    1500,
  );

  // ============ Heat balance ============
  // Generated heat from power.
  const heatIn = r.power * 0.45 * dt; // °C per second (illustrative)
  // Cooling from coolant flow & water.
  const coolFlow = (co.flowA + co.flowB) / 9000; // 0..1 (both pumps → 1)
  const cooling = (10 + coolFlow * 65) * (0.4 + waterCoupling * 0.6) * dt;
  // Steam venting cools too
  const steamCooling = clamp(c.mainSteamValve / 100, 0, 1) * 5 * dt;

  r.coreTemp = clamp(r.coreTemp + heatIn - cooling - steamCooling, 25, 800);

  // Coolant inlet/outlet temps
  co.inletTempA = lerp(co.inletTempA, 25 + r.coreTemp * 0.05, 0.1);
  co.outletTempA = lerp(co.outletTempA, co.inletTempA + (pumpA ? r.coreTemp * 0.4 : 0), 0.1);
  co.inletTempB = lerp(co.inletTempB, 25 + r.coreTemp * 0.05, 0.1);
  co.outletTempB = lerp(co.outletTempB, co.inletTempB + (pumpB ? r.coreTemp * 0.4 : 0), 0.1);

  // ============ Pressure dynamics ============
  // Core pressure builds with temperature and power, relieved by steam flow.
  const pressureBuild = (r.coreTemp - 80) * 0.0025 * dt;
  const pressureRelief =
    clamp(c.mainSteamValve / 100, 0, 1) * 0.18 * dt +
    clamp(c.bypassValve / 100, 0, 1) * 0.15 * dt;
  r.corePressure = clamp(r.corePressure + pressureBuild - pressureRelief, 0.5, 200);

  // Steam pressure mirrors core, lagged.
  const steamGen =
    clamp((r.coreTemp - 100) / 200, 0, 1) * 0.5 * dt + clamp(r.power / 150, 0, 1) * 0.4 * dt;
  st.steamPressure = clamp(st.steamPressure + steamGen - pressureRelief * 0.7, 0.2, 200);
  // Relief valve hard cap
  if (st.steamPressure > LIMITS.steamPressureRelief) {
    st.steamPressure -= 1.6 * dt;
  }

  // Steam flow to turbine
  const steamValveStuck = hasFault(state.faults, "valve_stuck_steam");
  const bypassStuck = hasFault(state.faults, "valve_stuck_bypass");
  const effSteamValve = steamValveStuck ? 0 : c.mainSteamValve;
  const effBypass = bypassStuck ? 100 : c.bypassValve;

  st.steamFlow = lerp(st.steamFlow, (effSteamValve / 100) * st.steamPressure * 1.2, 0.2);
  st.bypassFlow = lerp(st.bypassFlow, (effBypass / 100) * st.steamPressure * 0.5, 0.2);

  // ============ Turbine ============
  const condenserLost = hasFault(state.faults, "condenser_loss");
  const targetRpm = clamp(st.steamFlow * 50, 0, 4500);
  if (tu.tripped) {
    tu.rpm = lerp(tu.rpm, 0, 0.04 * rateScale);
  } else {
    tu.rpm = lerp(tu.rpm, targetRpm, 0.07 * rateScale);
  }
  tu.vibration = clamp(
    Math.abs(tu.rpm - LIMITS.rpmTarget) / 30 + (condenserLost ? 25 : 0),
    0,
    100,
  );
  tu.syncReady = !tu.tripped && tu.rpm > 3500 && tu.rpm < 3700;

  // Auto-trip on overspeed
  if (tu.rpm > LIMITS.rpmOverspeed && !tu.tripped) {
    tu.tripped = true;
    state.stats.turbineTrips += 1;
    state.controls.generatorSync = false;
    pushLog(state, "critical", "Turbine TRIP — overspeed protection activated.");
  }

  // ============ Generator ============
  if (tu.tripped) c.generatorSync = false;
  ge.synced = c.generatorSync && tu.syncReady;

  // Grid demand & target MW (slowly walks)
  if (hasFault(state.faults, "grid_demand_spike")) {
    ge.targetMw = clamp(ge.targetMw + 12 * dt, 100, 600);
  }
  if (Math.random() < 0.001 * rateScale) {
    ge.targetMw = clamp(ge.targetMw + (Math.random() - 0.5) * 60, 80, 500);
  }

  // MW production proportional to steam flow when synced
  const targetMw = ge.synced ? clamp(st.steamFlow * 4.5, 0, 500) : 0;
  ge.mw = lerp(ge.mw, targetMw, 0.08 * rateScale);
  state.stats.peakMw = Math.max(state.stats.peakMw, ge.mw);

  // Transformer load: % vs nominal 400 MW
  const transformerFault = hasFault(state.faults, "transformer_overload_fault");
  ge.transformerLoad = clamp(
    (ge.mw / 400) * 100 + (transformerFault ? 25 : 0),
    0,
    150,
  );

  // ============ Meltdown progression ============
  if (r.coreTemp > LIMITS.coreTempMeltdown - 20) {
    r.meltdownProgress = clamp(
      r.meltdownProgress + (r.coreTemp - (LIMITS.coreTempMeltdown - 20)) * 0.2 * dt,
      0,
      100,
    );
  } else {
    r.meltdownProgress = clamp(r.meltdownProgress - 0.5 * dt, 0, 100);
  }
  if (r.meltdownProgress >= 100) r.meltdown = true;

  // Auto rod mode keeps reactor near 80% if not scrammed
  if (c.rodMode === "auto" && c.controlPower && !r.scrammed) {
    const want = ge.targetMw / 5; // rough power% target
    const error = want - r.power;
    const newRod = clamp(c.rodInsertion - error * 0.05 * dt * rateScale, 0, 100);
    c.rodInsertion = newRod;
  }

  // Sim time accounting
  state.simTime += dt;
  state.stats.uptime += dt;

  // Efficiency rolling
  if (r.power > 5) {
    state.stats.efficiency = lerp(
      state.stats.efficiency,
      clamp((ge.mw / (r.power * 4)) * 100, 0, 120),
      0.04,
    );
  } else {
    state.stats.efficiency = lerp(state.stats.efficiency, 0, 0.05);
  }
}

export function pushLog(
  state: PlantState,
  level: "info" | "warn" | "alarm" | "critical",
  text: string,
) {
  state.log.unshift({ t: state.simTime, level, text });
  if (state.log.length > 250) state.log.length = 250;
}
