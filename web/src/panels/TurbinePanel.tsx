import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { Slider } from "../components/Slider";
import { Gauge } from "../components/Gauge";
import { Readout } from "../components/Readout";
import { Bar } from "../components/Bar";
import { LIMITS } from "../sim/constants";

export function TurbinePanel() {
  const plant = useStore((s) => s.plant);
  const c = plant.controls;
  const t = plant.turbine;
  const g = plant.generator;
  const setControl = useStore((s) => s.setControl);
  const syncGenerator = useStore((s) => s.syncGenerator);
  const resetTurbine = useStore((s) => s.resetTurbine);

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel title="Turbine" className="col-span-12 lg:col-span-7">
        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          <Gauge
            label="Turbine RPM"
            value={t.rpm}
            max={4500}
            unit="rpm"
            warnAt={LIMITS.rpmTarget + 250}
            criticalAt={LIMITS.rpmOverspeed - 80}
            decimals={0}
          />
          <Gauge label="Vibration" value={t.vibration} max={100} unit="" warnAt={50} criticalAt={80} />
          <Gauge label="Steam Pressure" value={plant.steam.steamPressure} max={100} unit="bar" warnAt={70} criticalAt={82} />
        </div>
        <div className="mt-3 grid grid-cols-1 gap-2">
          <Slider
            label="Main Steam Valve"
            value={c.mainSteamValve}
            onChange={(v) => setControl("mainSteamValve", v)}
            disabled={!c.controlPower || t.tripped}
          />
          <Slider
            label="Bypass Valve"
            value={c.bypassValve}
            onChange={(v) => setControl("bypassValve", v)}
            disabled={!c.controlPower}
          />
        </div>
      </Panel>

      <Panel title="Generator" className="col-span-12 lg:col-span-5">
        <div className="grid grid-cols-2 gap-2">
          <Readout label="Output" value={g.mw} unit="MW" />
          <Readout
            label="Grid Demand"
            value={g.targetMw}
            unit="MW"
            decimals={0}
          />
          <Readout
            label="Sync Status"
            value={g.synced ? "SYNCED" : t.syncReady ? "READY" : t.tripped ? "TRIPPED" : "OFF"}
            warn={!g.synced && t.syncReady}
            critical={t.tripped}
          />
          <Readout
            label="Transformer"
            value={g.transformerLoad}
            unit="%"
            warn={g.transformerLoad > 85}
            critical={g.transformerLoad > LIMITS.transformerOverload}
          />
        </div>
        <div className="mt-3 grid grid-cols-1 gap-2">
          <Bar
            label="Transformer Load"
            value={g.transformerLoad}
            max={150}
            warnAt={85}
            criticalAt={LIMITS.transformerOverload}
          />
          <Bar
            label="Vibration"
            value={t.vibration}
            warnAt={50}
            criticalAt={80}
          />
        </div>
        <div className="mt-3 grid grid-cols-2 gap-2">
          <button
            onClick={syncGenerator}
            disabled={!t.syncReady || g.synced}
            className="industrial-btn disabled:opacity-50 disabled:cursor-not-allowed"
            style={{
              background: g.synced
                ? "linear-gradient(180deg, #1a2a1f 0%, #0f1a13 100%)"
                : t.syncReady
                  ? "linear-gradient(180deg, #1f2a3a 0%, #131c2a 100%)"
                  : undefined,
              color: g.synced ? "#34ff7a" : t.syncReady ? "#3ad6ff" : undefined,
              borderColor: g.synced ? "rgba(52,255,122,0.4)" : t.syncReady ? "rgba(58,214,255,0.4)" : undefined,
            }}
          >
            {g.synced ? "Synced" : "Sync Generator"}
          </button>
          <button
            onClick={resetTurbine}
            disabled={!t.tripped}
            className="industrial-btn disabled:opacity-40"
          >
            Reset Turbine Trip
          </button>
        </div>
      </Panel>
    </div>
  );
}
