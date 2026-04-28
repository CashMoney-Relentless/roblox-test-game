import type { ActiveFault, FaultId, PlantState } from "./types";
import { DIFFICULTY_FACTORS } from "./constants";
import { pushLog } from "./reactor";

const FAULT_LABELS: Record<FaultId, string> = {
  pump_failure_a: "COOLANT PUMP A FAILURE",
  pump_failure_b: "COOLANT PUMP B FAILURE",
  valve_stuck_steam: "MAIN STEAM VALVE STUCK CLOSED",
  valve_stuck_bypass: "BYPASS VALVE STUCK OPEN",
  sensor_fault_temp: "CORE TEMP SENSOR DRIFT",
  sensor_fault_pressure: "PRESSURE SENSOR DRIFT",
  grid_demand_spike: "GRID DEMAND SPIKE",
  condenser_loss: "CONDENSER COOLING LOST",
  feedwater_interruption: "FEEDWATER INTERRUPTION",
  transformer_overload_fault: "TRANSFORMER OVERLOAD",
  loop_imbalance: "COOLANT LOOP IMBALANCE",
};

const FAULT_DURATIONS: Record<FaultId, [number, number]> = {
  pump_failure_a: [25, 60],
  pump_failure_b: [25, 60],
  valve_stuck_steam: [30, 70],
  valve_stuck_bypass: [30, 70],
  sensor_fault_temp: [40, 90],
  sensor_fault_pressure: [40, 90],
  grid_demand_spike: [30, 60],
  condenser_loss: [25, 60],
  feedwater_interruption: [20, 45],
  transformer_overload_fault: [20, 50],
  loop_imbalance: [30, 80],
};

const FAULT_POOL: FaultId[] = [
  "pump_failure_a",
  "pump_failure_b",
  "valve_stuck_steam",
  "valve_stuck_bypass",
  "sensor_fault_temp",
  "sensor_fault_pressure",
  "grid_demand_spike",
  "condenser_loss",
  "feedwater_interruption",
  "transformer_overload_fault",
  "loop_imbalance",
];

export function tickFaults(state: PlantState, dt: number) {
  const factor = DIFFICULTY_FACTORS[state.difficulty];

  // Decrement durations
  for (const f of state.faults) {
    f.duration -= dt;
  }
  // Remove expired and log
  const expired = state.faults.filter((f) => f.duration <= 0);
  for (const f of expired) {
    pushLog(state, "info", `Fault cleared: ${FAULT_LABELS[f.id]}`);
  }
  state.faults = state.faults.filter((f) => f.duration > 0);

  // Don't inject in training before plant has built up power.
  const allowFaults =
    state.simTime > 30 && (state.difficulty !== "training" || state.reactor.power > 25);
  if (!allowFaults) return;

  // Don't pile up too many at once
  if (state.faults.length >= 3) return;

  if (Math.random() < factor.faultRate) {
    const candidates = FAULT_POOL.filter((id) => !state.faults.some((f) => f.id === id));
    if (candidates.length === 0) return;
    const id = candidates[Math.floor(Math.random() * candidates.length)];
    const [lo, hi] = FAULT_DURATIONS[id];
    const fault: ActiveFault = {
      id,
      startedAt: state.simTime,
      duration: lo + Math.random() * (hi - lo),
    };
    state.faults.push(fault);
    pushLog(state, "warn", `Fault injected: ${FAULT_LABELS[id]}`);
  }
}

export function faultLabel(id: FaultId): string {
  return FAULT_LABELS[id];
}
