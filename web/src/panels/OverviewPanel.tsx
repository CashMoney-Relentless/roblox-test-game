import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { Gauge } from "../components/Gauge";
import { Readout } from "../components/Readout";
import { MiniChart } from "../components/MiniChart";
import { Bar } from "../components/Bar";
import { ALARM_DEFS, LIMITS } from "../sim/constants";
import { activeAlarmIds } from "../sim/alarms";

export function OverviewPanel() {
  const plant = useStore((s) => s.plant);
  const r = plant.reactor;
  const t = plant.turbine;
  const g = plant.generator;
  const stats = plant.stats;
  const active = activeAlarmIds(plant);

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel title="Plant Overview" subtitle="Argonne-1 Reactor" className="col-span-12 xl:col-span-8">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <Gauge label="Reactor Power" value={r.power} max={120} unit="%" warnAt={100} criticalAt={110} />
          <Gauge
            label="Core Temp"
            value={r.coreTemp}
            max={450}
            unit="°C"
            warnAt={LIMITS.coreTempMaxSafe}
            criticalAt={LIMITS.coreTempCritical}
          />
          <Gauge
            label="Core Pressure"
            value={r.corePressure}
            max={120}
            unit="bar"
            warnAt={LIMITS.corePressureMaxSafe}
            criticalAt={LIMITS.corePressureCritical}
          />
          <Gauge
            label="Steam Pressure"
            value={plant.steam.steamPressure}
            max={100}
            unit="bar"
            warnAt={LIMITS.steamPressureMaxSafe}
            criticalAt={LIMITS.steamPressureRelief}
          />
          <Gauge
            label="Core Water"
            value={r.coreWater}
            max={100}
            unit="%"
            warnAt={LIMITS.coreWaterMax}
          />
          <Gauge
            label="Turbine RPM"
            value={t.rpm}
            max={4500}
            unit="rpm"
            warnAt={LIMITS.rpmTarget + 200}
            criticalAt={LIMITS.rpmOverspeed - 80}
            decimals={0}
          />
          <Gauge
            label="Generator MW"
            value={g.mw}
            max={500}
            unit="MW"
            warnAt={420}
            criticalAt={460}
          />
          <Gauge
            label="Stability"
            value={stats.stability}
            max={100}
            unit="%"
            warnAt={50}
            criticalAt={25}
          />
        </div>
      </Panel>

      <Panel title="Telemetry" className="col-span-12 xl:col-span-4">
        <div className="grid grid-cols-2 gap-2">
          <Readout label="Score" value={Math.round(stats.score)} unit="pts" decimals={0} />
          <Readout label="Peak MW" value={Math.round(stats.peakMw)} unit="MW" decimals={0} />
          <Readout label="Uptime" value={Math.round(plant.simTime)} unit="s" decimals={0} />
          <Readout label="Efficiency" value={stats.efficiency} unit="%" />
          <Readout label="Alarm Count" value={stats.alarmCount} unit="" decimals={0} />
          <Readout
            label="Startup Time"
            value={stats.startupTime !== null ? Math.round(stats.startupTime) : "—"}
            unit={stats.startupTime !== null ? "s" : ""}
            decimals={0}
          />
          <Readout label="SCRAMs" value={stats.scramCount} unit="" decimals={0} />
          <Readout label="Trips" value={stats.turbineTrips} unit="" decimals={0} />
        </div>
        <div className="mt-3 grid grid-cols-2 gap-2">
          <Bar label="Transformer Load" value={g.transformerLoad} max={150} warnAt={85} criticalAt={100} />
          <Bar label="Vibration" value={t.vibration} max={100} warnAt={50} criticalAt={80} />
        </div>
      </Panel>

      <Panel title="Trends" className="col-span-12 xl:col-span-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <MiniChart data={plant.history} dataKey="power" color="#34ff7a" unit="%" label="Reactor Power" domain={[0, 120]} />
          <MiniChart data={plant.history} dataKey="mw" color="#3ad6ff" unit="MW" label="Generator MW" domain={[0, 500]} />
          <MiniChart data={plant.history} dataKey="coreTemp" color="#ffb030" unit="°C" label="Core Temp" domain={[0, 420]} />
          <MiniChart data={plant.history} dataKey="steamPressure" color="#ff7ac8" unit="bar" label="Steam Pressure" domain={[0, 100]} />
        </div>
      </Panel>

      <Panel title="Active Alarms" className="col-span-12 xl:col-span-4">
        {active.length === 0 ? (
          <div className="text-sm text-panel-400 italic">All systems nominal.</div>
        ) : (
          <ul className="space-y-1">
            {active.map((id) => {
              const def = ALARM_DEFS[id];
              return (
                <li
                  key={id}
                  className={`flex items-center gap-2 text-xs font-display uppercase tracking-wider px-2 py-1 rounded border ${
                    def.severity === "critical"
                      ? "border-readout-red/60 bg-[#2a0a0a]/60 text-readout-red"
                      : def.severity === "warning"
                        ? "border-readout-amber/60 bg-[#2a1d05]/60 text-readout-amber"
                        : "border-readout-blue/60 bg-[#06222a]/60 text-readout-blue"
                  }`}
                >
                  <span
                    className={`led ${
                      def.severity === "critical"
                        ? "led-on-red"
                        : def.severity === "warning"
                          ? "led-on-amber"
                          : "led-on-green"
                    }`}
                  />
                  {def.label}
                </li>
              );
            })}
          </ul>
        )}
      </Panel>
    </div>
  );
}
