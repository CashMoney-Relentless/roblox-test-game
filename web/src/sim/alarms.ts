import { ALARM_DEFS, LIMITS } from "./constants";
import type { AlarmId, PlantState } from "./types";
import { pushLog } from "./reactor";

const TRIGGER_LIST: { id: AlarmId; test: (s: PlantState) => boolean }[] = [
  { id: "core_water_low", test: (s) => s.reactor.coreWater < LIMITS.coreWaterMin && s.controls.controlPower },
  { id: "core_water_high", test: (s) => s.reactor.coreWater > LIMITS.coreWaterMax },
  { id: "core_temp_high", test: (s) => s.reactor.coreTemp > LIMITS.coreTempMaxSafe },
  { id: "core_pressure_high", test: (s) => s.reactor.corePressure > LIMITS.corePressureMaxSafe },
  { id: "loop_a_dry", test: (s) => s.controls.coolantPumpA && s.coolant.loopALevel < 25 },
  { id: "loop_b_dry", test: (s) => s.controls.coolantPumpB && s.coolant.loopBLevel < 25 },
  {
    id: "feed_loop_dry",
    test: (s) =>
      s.reactor.coreWater < LIMITS.coreWaterMin - 5 &&
      !(s.controls.feedwaterPumpA || s.controls.feedwaterPumpB),
  },
  { id: "pump_cavitation", test: (s) => s.feedwater.cavitation },
  { id: "low_hotwell", test: (s) => s.feedwater.hotwellLevel < LIMITS.hotwellMin && s.controls.controlPower },
  {
    id: "deaerator_a_low",
    test: (s) => s.feedwater.deaeratorALevel < LIMITS.deaeratorMin && s.controls.controlPower,
  },
  {
    id: "deaerator_b_low",
    test: (s) => s.feedwater.deaeratorBLevel < LIMITS.deaeratorMin && s.controls.controlPower,
  },
  {
    id: "deaerator_a_temp_low",
    test: (s) =>
      s.feedwater.deaeratorATemp < LIMITS.deaeratorTempMin &&
      s.feedwater.deaeratorALevel > 30 &&
      s.steam.steamPressure > 5,
  },
  {
    id: "deaerator_b_temp_low",
    test: (s) =>
      s.feedwater.deaeratorBTemp < LIMITS.deaeratorTempMin &&
      s.feedwater.deaeratorBLevel > 30 &&
      s.steam.steamPressure > 5,
  },
  {
    id: "circuit_overpressure",
    test: (s) => s.steam.steamPressure > LIMITS.steamPressureRelief - 4,
  },
  {
    id: "high_outlet_pressure",
    test: (s) => s.coolant.outletTempA > 280 || s.coolant.outletTempB > 280,
  },
  {
    id: "transformer_overload",
    test: (s) => s.generator.transformerLoad > LIMITS.transformerOverload,
  },
  {
    id: "turbine_overspeed",
    test: (s) => s.turbine.rpm > LIMITS.rpmOverspeed - 80,
  },
  { id: "turbine_trip", test: (s) => s.turbine.tripped },
  { id: "reactor_scram", test: (s) => s.reactor.scrammed },
  {
    id: "meltdown_warning",
    test: (s) => s.reactor.coreTemp > LIMITS.coreTempCritical,
  },
];

export function evaluateAlarms(state: PlantState) {
  for (const { id, test } of TRIGGER_LIST) {
    const a = state.alarms[id];
    const fire = test(state);
    if (fire && !a.active) {
      a.active = true;
      a.acknowledged = false;
      a.triggeredAt = state.simTime;
      state.stats.alarmCount += 1;
      pushLog(
        state,
        ALARM_DEFS[id].severity === "critical" ? "critical" : "alarm",
        `ALARM: ${ALARM_DEFS[id].label}`,
      );
    } else if (!fire && a.active) {
      a.active = false;
      a.acknowledged = false;
      pushLog(state, "info", `Cleared: ${ALARM_DEFS[id].label}`);
    }
  }
}

export function activeAlarmIds(state: PlantState): AlarmId[] {
  return (Object.keys(state.alarms) as AlarmId[]).filter((id) => state.alarms[id].active);
}

export function ackAllAlarms(state: PlantState) {
  for (const id in state.alarms) {
    state.alarms[id as AlarmId].acknowledged = true;
  }
}
