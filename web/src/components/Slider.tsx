interface Props {
  label: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  unit?: string;
  onChange: (v: number) => void;
  disabled?: boolean;
  inverted?: boolean; // display inversion (e.g. rod insertion)
  size?: "sm" | "md";
}

export function Slider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = "%",
  onChange,
  disabled,
  inverted,
  size = "md",
}: Props) {
  return (
    <div className={`bg-black/40 border border-panel-700 rounded p-3 ${disabled ? "opacity-50" : ""}`}>
      <div className="flex justify-between items-baseline mb-2">
        <span className="text-[10px] uppercase tracking-[0.18em] text-panel-400 font-display">
          {label}
        </span>
        <span className="readout text-sm">
          {value.toFixed(0)}
          <span className="text-[10px] opacity-70 ml-1">{unit}</span>
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(parseFloat(e.target.value))}
        className={`w-full ${size === "sm" ? "h-4" : "h-6"} ${inverted ? "[direction:rtl]" : ""}`}
      />
      <div className="flex justify-between text-[10px] text-panel-400 mt-1 font-mono">
        <span>{inverted ? `${max}` : `${min}`}</span>
        <span>{inverted ? `${min}` : `${max}`}</span>
      </div>
    </div>
  );
}
