// Core types describing every observable value and control input
// in the simulated reactor plant.

export type Difficulty = "training" | "normal" | "expert";

export type RodMode = "manual" | "auto";

export type AlarmId =
  | "core_water_low"
  | "core_water_high"
  | "core_temp_high"
  | "core_pressure_high"
  | "loop_a_dry"
  | "loop_b_dry"
  | "feed_loop_dry"
  | "pump_cavitation"
  | "low_hotwell"
  | "deaerator_a_low"
  | "deaerator_b_low"
  | "deaerator_a_temp_low"
  | "deaerator_b_temp_low"
  | "circuit_overpressure"
  | "high_outlet_pressure"
  | "transformer_overload"
  | "turbine_overspeed"
  | "turbine_trip"
  | "reactor_scram"
  | "meltdown_warning";

export type AlarmSeverity = "info" | "warning" | "critical";

export interface AlarmDefinition {
  id: AlarmId;
  label: string;
  severity: AlarmSeverity;
  description: string;
  fix: string;
}

export interface AlarmState {
  id: AlarmId;
  active: boolean;
  acknowledged: boolean;
  triggeredAt: number; // sim time in seconds when first triggered
}

export type FaultId =
  | "pump_failure_a"
  | "pump_failure_b"
  | "valve_stuck_steam"
  | "valve_stuck_bypass"
  | "sensor_fault_temp"
  | "sensor_fault_pressure"
  | "grid_demand_spike"
  | "condenser_loss"
  | "feedwater_interruption"
  | "transformer_overload_fault"
  | "loop_imbalance";

export interface ActiveFault {
  id: FaultId;
  startedAt: number;
  duration: number; // seconds remaining
  data?: Record<string, number>;
}

export interface Controls {
  controlPower: boolean;
  rodInsertion: number; // 0 = fully withdrawn (max heat), 100 = fully inserted
  rodMode: RodMode;
  recircPumps: boolean;
  coolantPumpA: boolean;
  coolantPumpB: boolean;
  feedwaterPumpA: boolean;
  feedwaterPumpB: boolean;
  condensatePumpA: boolean;
  condensatePumpB: boolean;
  makeupWaterPump: boolean;
  steamInletA: number; // 0..100
  steamInletB: number; // 0..100
  mainSteamValve: number; // 0..100
  bypassValve: number; // 0..100
  generatorSync: boolean;
  scramArmed: boolean; // safety cover open
  alarmAudio: boolean;
}

export interface Reactor {
  power: number; // 0..120 percent
  neutronFlux: number; // arbitrary units (0..1500)
  coreTemp: number; // °C
  corePressure: number; // bar
  coreWater: number; // 0..100 percent
  scrammed: boolean;
  meltdown: boolean;
  meltdownProgress: number; // 0..100 once dangerous, 100 = vessel breach
}

export interface Coolant {
  flowA: number; // m^3/h
  flowB: number;
  inletTempA: number;
  outletTempA: number;
  inletTempB: number;
  outletTempB: number;
  loopALevel: number; // 0..100
  loopBLevel: number;
}

export interface Feedwater {
  hotwellLevel: number; // 0..100
  deaeratorALevel: number;
  deaeratorBLevel: number;
  deaeratorATemp: number; // °C
  deaeratorBTemp: number;
  feedwaterFlow: number;
  cavitation: boolean;
}

export interface SteamSystem {
  steamPressure: number; // bar
  steamFlow: number; // kg/s arbitrary
  bypassFlow: number;
}

export interface Turbine {
  rpm: number;
  vibration: number; // 0..100
  tripped: boolean;
  syncReady: boolean;
}

export interface Generator {
  mw: number;
  targetMw: number; // grid demand target
  transformerLoad: number; // 0..120 percent
  synced: boolean;
}

export interface Stats {
  stability: number; // 0..100 rolling stability score
  uptime: number; // seconds since session start
  startupTime: number | null; // seconds to reach synced + > 100MW the first time
  alarmCount: number; // total alarms triggered this session
  scramCount: number; // SCRAMs this session
  turbineTrips: number;
  peakMw: number;
  efficiency: number; // 0..100, MW vs reactor power
  score: number;
}

export interface PlantState {
  difficulty: Difficulty;
  simTime: number; // seconds
  paused: boolean;
  controls: Controls;
  reactor: Reactor;
  coolant: Coolant;
  feedwater: Feedwater;
  steam: SteamSystem;
  turbine: Turbine;
  generator: Generator;
  stats: Stats;
  alarms: Record<AlarmId, AlarmState>;
  faults: ActiveFault[];
  history: HistoryPoint[];
  checklist: Record<ChecklistStepId, boolean>;
  log: LogEntry[];
}

export interface HistoryPoint {
  t: number;
  power: number;
  coreTemp: number;
  corePressure: number;
  steamPressure: number;
  rpm: number;
  mw: number;
  coreWater: number;
}

export interface LogEntry {
  t: number;
  level: "info" | "warn" | "alarm" | "critical";
  text: string;
}

export type ChecklistStepId =
  | "control_power"
  | "condensate"
  | "hotwell"
  | "deaerators"
  | "feedwater"
  | "coolant"
  | "recirc"
  | "rods"
  | "steam_pressure"
  | "main_steam_valve"
  | "spin_turbine"
  | "sync_generator"
  | "increase_load";

export interface ChecklistStep {
  id: ChecklistStepId;
  title: string;
  description: string;
  hint: string;
}

export interface SaveData {
  bestScore: number;
  highestMw: number;
  fastestStartup: number | null;
  successfulStartups: number;
  totalScrams: number;
  totalTurbineTrips: number;
  operatorXp: number;
  operatorRank: string;
}
