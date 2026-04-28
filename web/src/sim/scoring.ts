import type { PlantState } from "./types";
import { activeAlarmIds } from "./alarms";

const STAB_TARGET_MW = 250;

export function tickScore(state: PlantState, dt: number) {
  const stats = state.stats;

  // Stability: reward staying near grid target & penalise alarms
  const mwError = Math.abs(state.generator.mw - state.generator.targetMw);
  const stabContribution = state.generator.synced
    ? Math.max(0, 100 - (mwError / STAB_TARGET_MW) * 100)
    : Math.max(0, stats.stability - 4 * dt);
  stats.stability = stats.stability * 0.97 + stabContribution * 0.03;

  // Score accumulator: MW * stability factor * efficiency, minus alarms.
  const activeAlarms = activeAlarmIds(state);
  const criticalActive = activeAlarms.filter(
    (id) => id === "reactor_scram" || id === "turbine_trip" || id === "meltdown_warning",
  ).length;

  const baseGain =
    (state.generator.synced ? state.generator.mw * 0.05 : 0) *
    (stats.stability / 100) *
    (stats.efficiency / 100 + 0.4) *
    dt;

  const penalty = (activeAlarms.length * 0.4 + criticalActive * 3) * dt;

  stats.score = Math.max(0, stats.score + baseGain - penalty);
}

export function rankFromXp(xp: number): string {
  if (xp < 100) return "Trainee";
  if (xp < 500) return "Junior Operator";
  if (xp < 1500) return "Reactor Operator";
  if (xp < 3500) return "Senior Operator";
  if (xp < 7000) return "Shift Supervisor";
  if (xp < 12000) return "Control Room Lead";
  return "Plant Director";
}
