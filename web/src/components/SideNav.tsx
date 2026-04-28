import { useStore, type ScreenId } from "../store/store";
import { activeAlarmIds } from "../sim/alarms";

const items: { id: ScreenId; label: string; sub: string }[] = [
  { id: "overview", label: "Overview", sub: "01 · Master display" },
  { id: "reactor", label: "Reactor", sub: "02 · Core controls" },
  { id: "coolant", label: "Coolant", sub: "03 · Primary loops" },
  { id: "feedwater", label: "Feedwater", sub: "04 · Hotwell / DA" },
  { id: "turbine", label: "Turbine", sub: "05 · TG set" },
  { id: "alarms", label: "Alarms", sub: "06 · Annunciator" },
  { id: "checklist", label: "Procedure", sub: "07 · Startup" },
];

export function SideNav() {
  const screen = useStore((s) => s.selectedScreen);
  const setScreen = useStore((s) => s.setScreen);
  const plant = useStore((s) => s.plant);
  const activeCount = activeAlarmIds(plant).length;

  return (
    <nav className="bg-panel-900/80 border-r border-panel-700 px-2 py-3 w-56 flex flex-col gap-1">
      <div className="px-2 mb-3">
        <div className="font-display font-bold text-readout-amber text-lg leading-tight tracking-widest">
          ARGONNE-1
        </div>
        <div className="text-[10px] uppercase tracking-[0.2em] text-panel-400">
          Reactor Control Room
        </div>
      </div>
      {items.map((it) => {
        const active = screen === it.id;
        const flag = it.id === "alarms" && activeCount > 0;
        return (
          <button
            key={it.id}
            onClick={() => setScreen(it.id)}
            className={`text-left px-3 py-2 rounded-sm border transition flex items-center justify-between gap-2 ${
              active
                ? "bg-panel-800 border-readout-green/40"
                : "bg-transparent border-transparent hover:bg-panel-800/60"
            }`}
          >
            <div>
              <div
                className={`font-display uppercase tracking-wider text-sm ${
                  active ? "text-readout-green" : "text-panel-400"
                }`}
              >
                {it.label}
              </div>
              <div className="text-[10px] text-panel-400/80 font-mono">
                {it.sub}
              </div>
            </div>
            {flag && (
              <span className="led led-on-red animate-flash" title={`${activeCount} active alarms`} />
            )}
          </button>
        );
      })}
      <div className="mt-auto px-2 pt-3 border-t border-panel-700 text-[10px] font-mono text-panel-400">
        v1.0 — local sim
      </div>
    </nav>
  );
}
