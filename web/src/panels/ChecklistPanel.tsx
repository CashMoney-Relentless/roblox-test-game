import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { CHECKLIST_STEPS, DIFFICULTY_FACTORS } from "../sim/constants";

export function ChecklistPanel() {
  const plant = useStore((s) => s.plant);
  const showHints = DIFFICULTY_FACTORS[plant.difficulty].hints;
  const checklist = plant.checklist;

  const completed = Object.values(checklist).filter(Boolean).length;
  const total = CHECKLIST_STEPS.length;
  const pct = Math.round((completed / total) * 100);

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel
        title="Startup Checklist"
        subtitle={`${completed}/${total} steps complete`}
        right={
          <span className="font-mono text-xs text-readout-green">{pct}%</span>
        }
        className="col-span-12 xl:col-span-8"
      >
        <ol className="flex flex-col gap-2">
          {CHECKLIST_STEPS.map((s, i) => {
            const done = checklist[s.id];
            return (
              <li
                key={s.id}
                className={`px-3 py-2 rounded border flex flex-col gap-0.5 transition ${
                  done
                    ? "border-readout-green/40 bg-[#0f1a13]/60"
                    : "border-panel-700 bg-panel-800/60"
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-2">
                    <span
                      className={`led ${done ? "led-on-green" : "led-on-amber"}`}
                    />
                    <span
                      className={`font-display uppercase tracking-wider text-sm ${
                        done ? "text-readout-green" : "text-panel-400"
                      }`}
                    >
                      {String(i + 1).padStart(2, "0")} · {s.title}
                    </span>
                  </span>
                  <span className="text-[10px] font-mono uppercase tracking-wider opacity-70">
                    {done ? "DONE" : "PENDING"}
                  </span>
                </div>
                <p className="text-xs text-panel-400 leading-snug">{s.description}</p>
                {showHints && !done && (
                  <p className="text-[11px] text-readout-blue/90 italic leading-snug">
                    Hint: {s.hint}
                  </p>
                )}
              </li>
            );
          })}
        </ol>
      </Panel>

      <Panel title="Operating Notes" className="col-span-12 xl:col-span-4">
        <ul className="text-xs space-y-2 leading-relaxed text-panel-400">
          <li>
            <span className="text-readout-green">→</span> Raising rods (lower
            insertion %) increases reactor heat. Withdraw slowly.
          </li>
          <li>
            <span className="text-readout-green">→</span> Heat builds steam
            pressure. Steam drives the turbine.
          </li>
          <li>
            <span className="text-readout-green">→</span> Coolant pumps remove
            heat. Both loops should always run when at power.
          </li>
          <li>
            <span className="text-readout-green">→</span> Feedwater raises core
            water level. Too much water cools the core and lowers efficiency.
          </li>
          <li>
            <span className="text-readout-green">→</span> Low water raises core
            temperature very fast.
          </li>
          <li>
            <span className="text-readout-green">→</span> Open the main steam
            valve to admit steam to the turbine. Watch RPM.
          </li>
          <li>
            <span className="text-readout-green">→</span> Synchronise the
            generator only when RPM is in band (3500 – 3700).
          </li>
          <li>
            <span className="text-readout-green">→</span> Increase output by
            withdrawing rods further and opening the steam valve.
          </li>
          <li>
            <span className="text-readout-amber">!</span> SCRAM is your friend.
            When in doubt, scram.
          </li>
        </ul>
      </Panel>
    </div>
  );
}
