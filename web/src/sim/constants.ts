import type { AlarmDefinition, AlarmId, ChecklistStep, Difficulty } from "./types";

export const TICK_HZ = 4; // engine ticks per simulated second
export const HISTORY_SECONDS = 180;

export const DIFFICULTY_FACTORS: Record<
  Difficulty,
  { rate: number; faultRate: number; hints: boolean; gridVolatility: number }
> = {
  training: { rate: 0.55, faultRate: 0.0005, hints: true, gridVolatility: 0.4 },
  normal: { rate: 1.0, faultRate: 0.004, hints: false, gridVolatility: 1.0 },
  expert: { rate: 1.55, faultRate: 0.012, hints: false, gridVolatility: 1.6 },
};

// Operating envelope constants
export const LIMITS = {
  coreTempMaxSafe: 320, // °C
  coreTempCritical: 360,
  coreTempMeltdown: 420,
  corePressureMaxSafe: 75, // bar
  corePressureCritical: 90,
  coreWaterMin: 35,
  coreWaterMax: 90,
  steamPressureMaxSafe: 70,
  steamPressureRelief: 82,
  rpmTarget: 3600,
  rpmOverspeed: 3950,
  transformerOverload: 100,
  hotwellMin: 25,
  deaeratorMin: 30,
  deaeratorTempMin: 90,
};

export const ALARM_DEFS: Record<AlarmId, AlarmDefinition> = {
  core_water_low: {
    id: "core_water_low",
    label: "CORE WATER LOW",
    severity: "warning",
    description: "Core water level below safe minimum.",
    fix: "Start feedwater pumps, raise inlet valves.",
  },
  core_water_high: {
    id: "core_water_high",
    label: "CORE WATER HIGH",
    severity: "warning",
    description: "Core flooded — efficiency suffering.",
    fix: "Reduce feedwater flow, throttle inlet valves.",
  },
  core_temp_high: {
    id: "core_temp_high",
    label: "CORE TEMP HIGH",
    severity: "critical",
    description: "Core temperature exceeding safe limits.",
    fix: "Insert control rods, ensure coolant flow.",
  },
  core_pressure_high: {
    id: "core_pressure_high",
    label: "CORE PRESSURE HIGH",
    severity: "critical",
    description: "Reactor pressure dangerously high.",
    fix: "Open main steam valve, reduce rod height.",
  },
  loop_a_dry: {
    id: "loop_a_dry",
    label: "COOLANT LOOP A DRY",
    severity: "critical",
    description: "Loop A coolant level too low.",
    fix: "Restart coolant pump A, check makeup water.",
  },
  loop_b_dry: {
    id: "loop_b_dry",
    label: "COOLANT LOOP B DRY",
    severity: "critical",
    description: "Loop B coolant level too low.",
    fix: "Restart coolant pump B, check makeup water.",
  },
  feed_loop_dry: {
    id: "feed_loop_dry",
    label: "FEED LOOP DRY",
    severity: "critical",
    description: "Feedwater starvation — no flow to core.",
    fix: "Start feedwater pumps and raise hotwell level.",
  },
  pump_cavitation: {
    id: "pump_cavitation",
    label: "PUMP CAVITATION",
    severity: "warning",
    description: "Pumps drawing dry — deaerator level too low.",
    fix: "Raise deaerator level, run makeup water.",
  },
  low_hotwell: {
    id: "low_hotwell",
    label: "LOW HOTWELL LEVEL",
    severity: "warning",
    description: "Hotwell condensate level below threshold.",
    fix: "Run makeup water pump, throttle deaerator demand.",
  },
  deaerator_a_low: {
    id: "deaerator_a_low",
    label: "DEAERATOR A LOW",
    severity: "warning",
    description: "Deaerator A water level too low.",
    fix: "Start condensate pump A, check valve.",
  },
  deaerator_b_low: {
    id: "deaerator_b_low",
    label: "DEAERATOR B LOW",
    severity: "warning",
    description: "Deaerator B water level too low.",
    fix: "Start condensate pump B, check valve.",
  },
  deaerator_a_temp_low: {
    id: "deaerator_a_temp_low",
    label: "DEAERATOR A TEMP LOW",
    severity: "info",
    description: "Deaerator A below working temperature.",
    fix: "Open steam inlet A to warm the vessel.",
  },
  deaerator_b_temp_low: {
    id: "deaerator_b_temp_low",
    label: "DEAERATOR B TEMP LOW",
    severity: "info",
    description: "Deaerator B below working temperature.",
    fix: "Open steam inlet B to warm the vessel.",
  },
  circuit_overpressure: {
    id: "circuit_overpressure",
    label: "CIRCUIT OVERPRESSURE",
    severity: "critical",
    description: "Steam circuit pressure relief active.",
    fix: "Open main steam valve, reduce rod height.",
  },
  high_outlet_pressure: {
    id: "high_outlet_pressure",
    label: "HIGH OUTLET PRESSURE",
    severity: "warning",
    description: "Coolant outlet pressure trending high.",
    fix: "Increase coolant flow, ensure both pumps online.",
  },
  transformer_overload: {
    id: "transformer_overload",
    label: "TRANSFORMER OVERLOAD",
    severity: "critical",
    description: "Generator output exceeding transformer rating.",
    fix: "Reduce load via main steam valve.",
  },
  turbine_overspeed: {
    id: "turbine_overspeed",
    label: "TURBINE OVERSPEED",
    severity: "critical",
    description: "Turbine spinning above maximum RPM.",
    fix: "Close main steam valve, open bypass.",
  },
  turbine_trip: {
    id: "turbine_trip",
    label: "TURBINE TRIP",
    severity: "critical",
    description: "Turbine emergency shutdown engaged.",
    fix: "Acknowledge, reset turbine on Turbine panel.",
  },
  reactor_scram: {
    id: "reactor_scram",
    label: "REACTOR SCRAM",
    severity: "critical",
    description: "Reactor emergency shutdown.",
    fix: "Stabilise core, then reset rods to begin again.",
  },
  meltdown_warning: {
    id: "meltdown_warning",
    label: "MELTDOWN WARNING",
    severity: "critical",
    description: "Core temp critical — fuel damage imminent.",
    fix: "SCRAM immediately, restore coolant flow.",
  },
};

export const CHECKLIST_STEPS: ChecklistStep[] = [
  {
    id: "control_power",
    title: "Enable Control Power",
    description: "Energise the control bus to bring panels online.",
    hint: "Reactor Panel — toggle CONTROL POWER on.",
  },
  {
    id: "condensate",
    title: "Start Condensate Pumps",
    description: "Move water from the hotwell into the deaerators.",
    hint: "Feedwater Panel — start condensate pumps A and B.",
  },
  {
    id: "hotwell",
    title: "Fill Hotwell",
    description: "Hotwell must be above 60% before continuing.",
    hint: "Feedwater Panel — engage makeup water pump until ≥ 60%.",
  },
  {
    id: "deaerators",
    title: "Fill & Heat Deaerators",
    description: "Both deaerators above 60% level and 100°C.",
    hint: "Open steam inlets A and B once levels build.",
  },
  {
    id: "feedwater",
    title: "Start Feedwater Pumps",
    description: "Begin pushing feedwater toward the core.",
    hint: "Feedwater Panel — both feedwater pumps on.",
  },
  {
    id: "coolant",
    title: "Start Coolant Loops",
    description: "Establish primary coolant circulation.",
    hint: "Coolant Panel — toggle pumps A and B.",
  },
  {
    id: "recirc",
    title: "Start Recirculation Pumps",
    description: "Recirc improves core flow stability.",
    hint: "Reactor Panel — RECIRC PUMPS on.",
  },
  {
    id: "rods",
    title: "Raise Control Rods Slowly",
    description: "Withdraw rods below 70% insertion to start fission.",
    hint: "Move rod slider down toward 50% insertion.",
  },
  {
    id: "steam_pressure",
    title: "Build Steam Pressure",
    description: "Wait for steam pressure to exceed 40 bar.",
    hint: "Heat the core, watch steam pressure climb.",
  },
  {
    id: "main_steam_valve",
    title: "Open Main Steam Valve",
    description: "Admit steam to the turbine.",
    hint: "Turbine Panel — open main steam valve gradually.",
  },
  {
    id: "spin_turbine",
    title: "Spin Turbine to Target RPM",
    description: "Bring RPM to ≥ 3300 before sync.",
    hint: "Adjust steam valve to settle near 3600 RPM.",
  },
  {
    id: "sync_generator",
    title: "Synchronise Generator",
    description: "Press SYNC once RPM is in band.",
    hint: "RPM 3500 – 3700 unlocks SYNC.",
  },
  {
    id: "increase_load",
    title: "Increase Load",
    description: "Output above 100 MW completes startup.",
    hint: "Withdraw rods further, open steam valve.",
  },
];

export const ALARM_PRIORITY: Record<AlarmId, number> = Object.fromEntries(
  Object.values(ALARM_DEFS).map((a) => [
    a.id,
    a.severity === "critical" ? 0 : a.severity === "warning" ? 1 : 2,
  ]),
) as Record<AlarmId, number>;
