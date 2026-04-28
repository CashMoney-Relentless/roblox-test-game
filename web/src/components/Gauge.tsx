interface Props {
  label: string;
  value: number;
  min?: number;
  max: number;
  unit?: string;
  warnAt?: number;
  criticalAt?: number;
  decimals?: number;
}

// Half-circle analog-style gauge built from an SVG arc.
export function Gauge({
  label,
  value,
  min = 0,
  max,
  unit,
  warnAt,
  criticalAt,
  decimals = 1,
}: Props) {
  const clamped = Math.max(min, Math.min(max, value));
  const t = (clamped - min) / (max - min || 1);
  const angle = -90 + t * 180; // -90 left .. 90 right (semi-circle pointing up)

  const isCrit = criticalAt !== undefined && value >= criticalAt;
  const isWarn = warnAt !== undefined && value >= warnAt && !isCrit;
  const color = isCrit ? "#ff3838" : isWarn ? "#ffb030" : "#34ff7a";

  // Build colored arcs for normal/warn/critical zones
  const arcPath = (a0: number, a1: number) => {
    const r = 58;
    const cx = 70;
    const cy = 72;
    const rad = (deg: number) => ((deg - 90) * Math.PI) / 180;
    const x0 = cx + r * Math.cos(rad(a0));
    const y0 = cy + r * Math.sin(rad(a0));
    const x1 = cx + r * Math.cos(rad(a1));
    const y1 = cy + r * Math.sin(rad(a1));
    const large = a1 - a0 > 180 ? 1 : 0;
    return `M ${x0.toFixed(2)} ${y0.toFixed(2)} A ${r} ${r} 0 ${large} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}`;
  };

  // Map values to angles (0..180 across the arc, clockwise from -90)
  const valToAng = (v: number) => ((v - min) / (max - min)) * 180;

  const warnA = warnAt !== undefined ? valToAng(warnAt) : 180;
  const critA = criticalAt !== undefined ? valToAng(criticalAt) : 180;

  return (
    <div className="bg-black/50 border border-panel-700 rounded p-3 flex flex-col items-center min-w-[150px]">
      <div className="text-[10px] uppercase tracking-[0.2em] text-panel-400 font-display mb-1">
        {label}
      </div>
      <svg viewBox="0 0 140 90" className="w-full h-auto">
        <defs>
          <filter id="g-glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="1.5" />
          </filter>
        </defs>
        <path d={arcPath(0, 180)} stroke="#1d2731" strokeWidth="10" fill="none" />
        <path d={arcPath(0, warnA)} stroke="#34ff7a55" strokeWidth="10" fill="none" />
        <path d={arcPath(warnA, critA)} stroke="#ffb03066" strokeWidth="10" fill="none" />
        <path d={arcPath(critA, 180)} stroke="#ff383866" strokeWidth="10" fill="none" />
        <g transform={`rotate(${angle} 70 72)`}>
          <line x1="70" y1="72" x2="70" y2="20" stroke={color} strokeWidth="2.5" filter="url(#g-glow)" />
          <circle cx="70" cy="72" r="3" fill={color} />
        </g>
      </svg>
      <div
        className={`font-mono tabular-nums text-lg ${
          isCrit ? "text-readout-red" : isWarn ? "text-readout-amber" : "text-readout-green"
        }`}
        style={{ textShadow: `0 0 6px ${color}88` }}
      >
        {value.toLocaleString(undefined, {
          minimumFractionDigits: decimals,
          maximumFractionDigits: decimals,
        })}
        <span className="text-[10px] ml-1 opacity-70">{unit}</span>
      </div>
    </div>
  );
}
