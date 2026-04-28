import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  XAxis,
  YAxis,
  Tooltip,
} from "recharts";
import type { HistoryPoint } from "../sim/types";

interface Props {
  data: HistoryPoint[];
  dataKey: keyof HistoryPoint;
  color: string;
  unit?: string;
  domain?: [number, number];
  height?: number;
  label: string;
}

export function MiniChart({ data, dataKey, color, unit, domain, height = 110, label }: Props) {
  return (
    <div className="bg-black/40 border border-panel-700 rounded p-2">
      <div className="flex justify-between items-baseline mb-1">
        <span className="text-[10px] uppercase tracking-[0.18em] text-panel-400 font-display">
          {label}
        </span>
        <span
          className="font-mono text-xs"
          style={{ color, textShadow: `0 0 6px ${color}88` }}
        >
          {data.length > 0 ? (data[data.length - 1][dataKey] as number).toFixed(1) : "0.0"}
          <span className="opacity-70 ml-1">{unit}</span>
        </span>
      </div>
      <div style={{ width: "100%", height }}>
        <ResponsiveContainer>
          <AreaChart data={data} margin={{ top: 4, right: 4, left: -28, bottom: -12 }}>
            <defs>
              <linearGradient id={`grad-${String(dataKey)}`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={color} stopOpacity={0.55} />
                <stop offset="100%" stopColor={color} stopOpacity={0.05} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke="#1d2731" strokeDasharray="2 4" />
            <XAxis
              dataKey="t"
              type="number"
              domain={["auto", "auto"]}
              tick={{ fontSize: 9, fill: "#4b5d6c" }}
              tickFormatter={(v) => `${v.toFixed(0)}`}
              hide
            />
            <YAxis
              domain={domain ?? ["auto", "auto"]}
              tick={{ fontSize: 9, fill: "#4b5d6c" }}
              width={32}
            />
            <Tooltip
              contentStyle={{
                background: "#0a0d12",
                border: "1px solid #26333f",
                borderRadius: 4,
                fontSize: 11,
                color: "#d8e2ec",
              }}
              labelFormatter={(v) => `t=${(v as number).toFixed(1)}s`}
              formatter={(v) => {
                const num = typeof v === "number" ? v : Number(v);
                return [num.toFixed(1) + (unit ? ` ${unit}` : ""), label];
              }}
            />
            <Area
              type="monotone"
              dataKey={dataKey}
              stroke={color}
              strokeWidth={1.5}
              fill={`url(#grad-${String(dataKey)})`}
              isAnimationActive={false}
              dot={false}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
