import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { Toggle } from "../components/Toggle";
import { Slider } from "../components/Slider";
import { Bar } from "../components/Bar";
import { Readout } from "../components/Readout";
import { LIMITS } from "../sim/constants";

export function FeedwaterPanel() {
  const plant = useStore((s) => s.plant);
  const c = plant.controls;
  const fw = plant.feedwater;
  const toggleControl = useStore((s) => s.toggleControl);
  const setControl = useStore((s) => s.setControl);

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel title="Condensate / Hotwell" className="col-span-12 lg:col-span-4">
        <div className="grid grid-cols-1 gap-2">
          <Bar
            label="Hotwell Level"
            value={fw.hotwellLevel}
            warnBelow={LIMITS.hotwellMin}
          />
          <Toggle
            label="Condensate Pump A"
            on={c.condensatePumpA}
            onChange={() => toggleControl("condensatePumpA")}
            disabled={!c.controlPower}
          />
          <Toggle
            label="Condensate Pump B"
            on={c.condensatePumpB}
            onChange={() => toggleControl("condensatePumpB")}
            disabled={!c.controlPower}
          />
          <Toggle
            label="Makeup Water Pump"
            on={c.makeupWaterPump}
            onChange={() => toggleControl("makeupWaterPump")}
            disabled={!c.controlPower}
          />
        </div>
      </Panel>

      <Panel title="Deaerator A" className="col-span-12 lg:col-span-4">
        <div className="grid grid-cols-1 gap-2">
          <Bar
            label="Level"
            value={fw.deaeratorALevel}
            warnBelow={LIMITS.deaeratorMin}
          />
          <Readout
            label="Temperature"
            value={fw.deaeratorATemp}
            unit="°C"
            warn={fw.deaeratorATemp < LIMITS.deaeratorTempMin}
          />
          <Slider
            label="Steam Inlet A"
            value={c.steamInletA}
            onChange={(v) => setControl("steamInletA", v)}
            disabled={!c.controlPower}
          />
        </div>
      </Panel>

      <Panel title="Deaerator B" className="col-span-12 lg:col-span-4">
        <div className="grid grid-cols-1 gap-2">
          <Bar
            label="Level"
            value={fw.deaeratorBLevel}
            warnBelow={LIMITS.deaeratorMin}
          />
          <Readout
            label="Temperature"
            value={fw.deaeratorBTemp}
            unit="°C"
            warn={fw.deaeratorBTemp < LIMITS.deaeratorTempMin}
          />
          <Slider
            label="Steam Inlet B"
            value={c.steamInletB}
            onChange={(v) => setControl("steamInletB", v)}
            disabled={!c.controlPower}
          />
        </div>
      </Panel>

      <Panel title="Feedwater System" className="col-span-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          <Toggle
            label="Feedwater Pump A"
            on={c.feedwaterPumpA}
            onChange={() => toggleControl("feedwaterPumpA")}
            disabled={!c.controlPower}
          />
          <Toggle
            label="Feedwater Pump B"
            on={c.feedwaterPumpB}
            onChange={() => toggleControl("feedwaterPumpB")}
            disabled={!c.controlPower}
          />
          <Readout label="Feedwater Flow" value={fw.feedwaterFlow} unit="kg/s" decimals={0} />
          <Readout
            label="Cavitation"
            value={fw.cavitation ? "ALARM" : "OK"}
            critical={fw.cavitation}
          />
        </div>
      </Panel>
    </div>
  );
}
