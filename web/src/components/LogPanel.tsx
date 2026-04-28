import { useStore } from "../store/store";
import { Panel } from "./Panel";

export function LogPanel() {
  const log = useStore((s) => s.plant.log);
  return (
    <Panel title="Event Log" subtitle="last 50 events">
      <ul className="font-mono text-[11px] leading-5 max-h-[180px] overflow-y-auto pr-1">
        {log.slice(0, 50).map((e, i) => (
          <li key={i} className="flex gap-2">
            <span className="text-panel-400">
              [{e.t.toFixed(1).padStart(7, " ")}]
            </span>
            <span
              className={
                e.level === "critical"
                  ? "text-readout-red"
                  : e.level === "alarm"
                    ? "text-readout-amber"
                    : e.level === "warn"
                      ? "text-readout-amber"
                      : "text-panel-400"
              }
            >
              {e.text}
            </span>
          </li>
        ))}
      </ul>
    </Panel>
  );
}
