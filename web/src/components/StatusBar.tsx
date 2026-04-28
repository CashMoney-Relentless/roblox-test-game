import { useStore } from "../store/store";
import type { Difficulty } from "../sim/types";
import { activeAlarmIds } from "../sim/alarms";
import { faultLabel } from "../sim/faults";

const DIFFS: { id: Difficulty; label: string }[] = [
  { id: "training", label: "Training" },
  { id: "normal", label: "Normal" },
  { id: "expert", label: "Expert" },
];

export function StatusBar() {
  const plant = useStore((s) => s.plant);
  const save = useStore((s) => s.save);
  const setDifficulty = useStore((s) => s.setDifficulty);
  const setPaused = useStore((s) => s.setPaused);
  const newSession = useStore((s) => s.newSession);
  const finishShift = useStore((s) => s.finishShift);
  const resetSaveData = useStore((s) => s.resetSaveData);

  const active = activeAlarmIds(plant);
  const top = active[0];

  return (
    <div className="border-b border-panel-700 bg-panel-900/80 px-3 py-2 flex flex-wrap items-center gap-3">
      <div className="flex items-center gap-2">
        <span
          className={`led ${
            plant.reactor.scrammed
              ? "led-on-red"
              : plant.generator.synced
                ? "led-on-green"
                : "led-on-amber"
          }`}
        />
        <span className="font-display uppercase tracking-widest text-xs text-panel-400">
          {plant.reactor.scrammed
            ? "Reactor Scrammed"
            : plant.generator.synced
              ? `Online · ${plant.generator.mw.toFixed(0)} MW`
              : "Cold / Startup"}
        </span>
      </div>

      <div className="flex items-center gap-1 ml-2">
        {DIFFS.map((d) => (
          <button
            key={d.id}
            onClick={() => setDifficulty(d.id)}
            className={`industrial-btn !py-1 !text-[10px] ${
              plant.difficulty === d.id ? "industrial-btn-active" : ""
            }`}
          >
            {d.label}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-2 ml-auto">
        {plant.faults.length > 0 && (
          <span className="text-[10px] font-mono uppercase tracking-wider text-readout-amber animate-flash">
            FAULT: {faultLabel(plant.faults[0].id)}
          </span>
        )}
        {top && (
          <span className="text-[10px] font-mono uppercase tracking-wider text-readout-red animate-flash">
            ALARM ACTIVE
          </span>
        )}
        <span className="text-[10px] font-mono text-panel-400">
          XP {save.operatorXp.toLocaleString()} · {save.operatorRank}
        </span>
        <button
          className="industrial-btn !py-1 !text-[10px]"
          onClick={() => setPaused(!plant.paused)}
        >
          {plant.paused ? "Resume" : "Pause"}
        </button>
        <button
          className="industrial-btn !py-1 !text-[10px]"
          onClick={() => {
            if (confirm("Reset to a fresh session? Saved progress is kept.")) newSession();
          }}
        >
          New Session
        </button>
        <button
          className="industrial-btn !py-1 !text-[10px]"
          onClick={() => {
            if (confirm("End shift, archive results, and start fresh?")) finishShift();
          }}
        >
          End Shift
        </button>
        <button
          className="industrial-btn !py-1 !text-[10px]"
          title="Erase all saved progress"
          onClick={() => {
            if (confirm("Really erase all saved progress? This cannot be undone.")) resetSaveData();
          }}
        >
          Wipe Save
        </button>
      </div>
    </div>
  );
}
