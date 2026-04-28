interface Props {
  label: string;
  value: number | string;
  unit?: string;
  decimals?: number;
  warn?: boolean;
  critical?: boolean;
  trend?: "up" | "down" | "flat";
}

export function Readout({
  label,
  value,
  unit,
  decimals = 1,
  warn,
  critical,
  trend,
}: Props) {
  const display =
    typeof value === "number"
      ? value.toLocaleString(undefined, {
          minimumFractionDigits: decimals,
          maximumFractionDigits: decimals,
        })
      : value;

  const cls = critical
    ? "readout readout-red"
    : warn
      ? "readout readout-amber"
      : "readout";

  return (
    <div className="flex flex-col gap-1">
      <span className="text-[10px] uppercase tracking-[0.18em] text-panel-400 font-display">
        {label}
      </span>
      <div className={`${cls} text-base flex items-baseline justify-between gap-2 min-w-[80px]`}>
        <span>{display}</span>
        <span className="text-[10px] opacity-70 ml-1">{unit ?? ""}</span>
        {trend && (
          <span className="text-[10px] opacity-60">
            {trend === "up" ? "▲" : trend === "down" ? "▼" : "—"}
          </span>
        )}
      </div>
    </div>
  );
}
