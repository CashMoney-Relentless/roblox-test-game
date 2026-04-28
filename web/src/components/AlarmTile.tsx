import type { AlarmDefinition, AlarmState } from "../sim/types";

interface Props {
  def: AlarmDefinition;
  state: AlarmState;
  hint?: boolean;
}

export function AlarmTile({ def, state, hint }: Props) {
  const color =
    def.severity === "critical"
      ? "red"
      : def.severity === "warning"
        ? "amber"
        : "blue";

  const active = state.active;
  const flashing = active && !state.acknowledged && def.severity !== "info";

  const colorClasses = {
    red: active
      ? "border-readout-red/70 bg-[#2a0a0a] text-readout-red"
      : "border-panel-700 bg-panel-800 text-panel-400",
    amber: active
      ? "border-readout-amber/60 bg-[#2a1d05] text-readout-amber"
      : "border-panel-700 bg-panel-800 text-panel-400",
    blue: active
      ? "border-readout-blue/60 bg-[#06222a] text-readout-blue"
      : "border-panel-700 bg-panel-800 text-panel-400",
  } as const;

  return (
    <div
      className={`px-2 py-2 rounded border text-xs font-display uppercase tracking-wider ${
        colorClasses[color]
      } ${flashing ? "animate-flash" : ""}`}
      title={`${def.description}\n\nFix: ${def.fix}`}
    >
      <div className="flex items-center gap-2 mb-1">
        <span
          className={`led ${
            active
              ? color === "red"
                ? "led-on-red"
                : color === "amber"
                  ? "led-on-amber"
                  : "led-on-green"
              : ""
          }`}
        />
        <span className="font-semibold">{def.label}</span>
      </div>
      <div className="text-[10px] opacity-80 normal-case tracking-normal leading-snug">
        {def.description}
      </div>
      {hint && active && (
        <div className="text-[10px] mt-1 normal-case tracking-normal text-panel-400 italic leading-snug">
          → {def.fix}
        </div>
      )}
    </div>
  );
}
