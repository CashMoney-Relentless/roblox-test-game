interface Props {
  label: string;
  value: number;
  min?: number;
  max?: number;
  unit?: string;
  warnAt?: number;
  criticalAt?: number;
  warnBelow?: number;
}

export function Bar({
  label,
  value,
  min = 0,
  max = 100,
  unit = "%",
  warnAt,
  criticalAt,
  warnBelow,
}: Props) {
  const t = Math.max(0, Math.min(1, (value - min) / (max - min || 1)));
  const isCrit = criticalAt !== undefined && value >= criticalAt;
  const isWarn = (warnAt !== undefined && value >= warnAt) || (warnBelow !== undefined && value <= warnBelow);
  const color = isCrit ? "#ff3838" : isWarn ? "#ffb030" : "#34ff7a";

  return (
    <div className="bg-black/40 border border-panel-700 rounded p-2">
      <div className="flex justify-between items-baseline">
        <span className="text-[10px] uppercase tracking-[0.18em] text-panel-400 font-display">
          {label}
        </span>
        <span
          className="font-mono text-xs"
          style={{ color, textShadow: `0 0 6px ${color}88` }}
        >
          {value.toFixed(1)}
          <span className="opacity-70 ml-1 text-[10px]">{unit}</span>
        </span>
      </div>
      <div className="mt-1 h-2 bg-panel-800 border border-panel-700 rounded-sm overflow-hidden">
        <div
          className="h-full transition-all duration-200"
          style={{
            width: `${t * 100}%`,
            background: `linear-gradient(90deg, ${color}55, ${color})`,
            boxShadow: `0 0 6px ${color}99`,
          }}
        />
      </div>
    </div>
  );
}
