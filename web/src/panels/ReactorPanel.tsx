import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { Gauge } from "../components/Gauge";
import { Slider } from "../components/Slider";
import { Toggle } from "../components/Toggle";
import { ScramButton } from "../components/ScramButton";
import { Readout } from "../components/Readout";
import { Bar } from "../components/Bar";
import { LIMITS } from "../sim/constants";

export function ReactorPanel() {
  const plant = useStore((s) => s.plant);
  const setControl = useStore((s) => s.setControl);
  const toggleControl = useStore((s) => s.toggleControl);

  const r = plant.reactor;
  const c = plant.controls;

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel title="Reactor Vessel" className="col-span-12 lg:col-span-7">
        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
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
            label="Core Water"
            value={r.coreWater}
            max={100}
            unit="%"
            warnAt={LIMITS.coreWaterMax}
          />
          <Gauge
            label="Reactor Power"
            value={r.power}
            max={120}
            unit="%"
            warnAt={100}
            criticalAt={110}
          />
          <Gauge
            label="Neutron Flux"
            value={r.neutronFlux}
            max={1500}
            unit="n/s"
            warnAt={1100}
            criticalAt={1300}
            decimals={0}
          />
          <div className="bg-black/50 border border-panel-700 rounded p-3 flex flex-col">
            <div className="text-[10px] uppercase tracking-[0.2em] text-panel-400 font-display mb-2">
              Status
            </div>
            <div className="flex flex-col gap-1 text-xs font-display">
              <div className="flex items-center gap-2">
                <span className={`led ${c.controlPower ? "led-on-green" : ""}`} /> Control Power
              </div>
              <div className="flex items-center gap-2">
                <span className={`led ${c.recircPumps ? "led-on-green" : ""}`} /> Recirc Pumps
              </div>
              <div className="flex items-center gap-2">
                <span className={`led ${r.scrammed ? "led-on-red" : "led-on-green"}`} />{" "}
                {r.scrammed ? "SCRAMMED" : "Reactor Online"}
              </div>
              <div className="flex items-center gap-2">
                <span
                  className={`led ${
                    r.meltdownProgress > 50
                      ? "led-on-red"
                      : r.meltdownProgress > 0
                        ? "led-on-amber"
                        : ""
                  }`}
                />{" "}
                Containment
              </div>
            </div>
          </div>
        </div>
        <div className="mt-3 grid grid-cols-2 gap-2">
          <Bar
            label="Meltdown Risk"
            value={r.meltdownProgress}
            max={100}
            warnAt={20}
            criticalAt={60}
          />
          <Readout
            label="Vessel"
            value={r.meltdown ? "BREACHED" : r.scrammed ? "SHUTDOWN" : "ACTIVE"}
            critical={r.meltdown}
            warn={r.scrammed}
          />
        </div>
      </Panel>

      <Panel title="Control Rods" className="col-span-12 lg:col-span-5">
        <Slider
          label={`Control Rod Insertion ${c.rodMode === "auto" ? "(AUTO)" : ""}`}
          value={c.rodInsertion}
          inverted
          unit="% inserted"
          onChange={(v) => setControl("rodInsertion", v)}
          disabled={c.rodMode === "auto" || !c.controlPower || r.scrammed}
        />
        <div className="grid grid-cols-2 gap-2 mt-3">
          <Toggle
            label="Control Power"
            on={c.controlPower}
            onChange={() => toggleControl("controlPower")}
          />
          <Toggle
            label="Rod Mode"
            on={c.rodMode === "auto"}
            labels={["MANUAL", "AUTO"]}
            onChange={() => toggleControl("rodMode")}
            disabled={!c.controlPower}
          />
          <Toggle
            label="Recirc Pumps"
            on={c.recircPumps}
            onChange={() => toggleControl("recircPumps")}
            disabled={!c.controlPower}
          />
          <Toggle
            label="Alarm Audio"
            on={c.alarmAudio}
            onChange={() => toggleControl("alarmAudio")}
            variant="amber"
          />
        </div>
        <div className="mt-3">
          <ScramButton />
        </div>
      </Panel>
    </div>
  );
}
