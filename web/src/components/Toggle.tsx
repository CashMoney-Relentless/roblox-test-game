interface Props {
  label: string;
  on: boolean;
  onChange: () => void;
  disabled?: boolean;
  labels?: [string, string]; // [off, on]
  variant?: "green" | "amber" | "red";
}

export function Toggle({ label, on, onChange, disabled, labels, variant = "green" }: Props) {
  const colorOn =
    variant === "green"
      ? "led-on-green"
      : variant === "amber"
        ? "led-on-amber"
        : "led-on-red";
  return (
    <button
      onClick={onChange}
      disabled={disabled}
      className={`flex items-center justify-between w-full px-3 py-2 rounded-sm border bg-panel-800 hover:bg-panel-700 transition disabled:opacity-50 disabled:cursor-not-allowed ${
        on ? "border-readout-green/50" : "border-panel-700"
      }`}
      style={{
        boxShadow: on
          ? "inset 0 0 8px rgba(52,255,122,0.18), inset 0 1px 0 rgba(255,255,255,0.05)"
          : "inset 0 1px 0 rgba(255,255,255,0.04), inset 0 -2px 0 rgba(0,0,0,0.4)",
      }}
    >
      <span className="flex items-center gap-2 text-xs uppercase tracking-wider font-display text-panel-400">
        <span className={`led ${on ? colorOn : ""}`} />
        {label}
      </span>
      <span
        className={`font-mono text-xs ${
          on ? "text-readout-green" : "text-panel-400"
        }`}
      >
        {labels ? (on ? labels[1] : labels[0]) : on ? "ON" : "OFF"}
      </span>
    </button>
  );
}
