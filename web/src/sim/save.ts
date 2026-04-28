import type { PlantState, SaveData } from "./types";
import { rankFromXp } from "./scoring";

const KEY = "argonne1.save.v1";

const DEFAULT_SAVE: SaveData = {
  bestScore: 0,
  highestMw: 0,
  fastestStartup: null,
  successfulStartups: 0,
  totalScrams: 0,
  totalTurbineTrips: 0,
  operatorXp: 0,
  operatorRank: rankFromXp(0),
};

export function loadSave(): SaveData {
  if (typeof window === "undefined") return { ...DEFAULT_SAVE };
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return { ...DEFAULT_SAVE };
    const parsed = JSON.parse(raw) as Partial<SaveData>;
    return { ...DEFAULT_SAVE, ...parsed, operatorRank: rankFromXp(parsed.operatorXp ?? 0) };
  } catch {
    return { ...DEFAULT_SAVE };
  }
}

export function writeSave(save: SaveData) {
  try {
    window.localStorage.setItem(
      KEY,
      JSON.stringify({ ...save, operatorRank: rankFromXp(save.operatorXp) }),
    );
  } catch {
    // ignore quota errors
  }
}

export function resetSave(): SaveData {
  try {
    window.localStorage.removeItem(KEY);
  } catch {
    // ignore
  }
  return { ...DEFAULT_SAVE };
}

// Apply session results (called when user ends a session or on certain events)
export function reconcileSave(prev: SaveData, state: PlantState): SaveData {
  const next = { ...prev };
  next.bestScore = Math.max(prev.bestScore, Math.round(state.stats.score));
  next.highestMw = Math.max(prev.highestMw, Math.round(state.stats.peakMw));
  next.totalScrams = prev.totalScrams + state.stats.scramCount;
  next.totalTurbineTrips = prev.totalTurbineTrips + state.stats.turbineTrips;

  if (state.stats.startupTime !== null) {
    next.successfulStartups = prev.successfulStartups + 1;
    next.fastestStartup =
      prev.fastestStartup === null
        ? state.stats.startupTime
        : Math.min(prev.fastestStartup, state.stats.startupTime);
  }

  // XP gain: score, peakMw, plus startup bonus
  const xpGain =
    Math.round(state.stats.score * 0.4) +
    Math.round(state.stats.peakMw * 0.2) +
    (state.stats.startupTime !== null ? 250 : 0) -
    state.stats.scramCount * 75 -
    state.stats.turbineTrips * 40;
  next.operatorXp = Math.max(0, prev.operatorXp + Math.max(0, xpGain));
  next.operatorRank = rankFromXp(next.operatorXp);
  return next;
}
