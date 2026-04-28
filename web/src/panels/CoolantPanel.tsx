import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { Toggle } from "../components/Toggle";
import { Bar } from "../components/Bar";
import { Readout } from "../components/Readout";

export function CoolantPanel() {
  const plant = useStore((s) => s.plant);
  const c = plant.controls;
  const co = plant.coolant;
  const toggleControl = useStore((s) => s.toggleControl);

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel title="Coolant Loop A" className="col-span-12 lg:col-span-6">
        <div className="grid grid-cols-2 gap-2">
          <Toggle
            label="Coolant Pump A"
            on={c.coolantPumpA}
            onChange={() => toggleControl("coolantPumpA")}
            disabled={!c.controlPower}
          />
          <Readout label="Flow Rate" value={co.flowA} unit="m³/h" decimals={0} />
          <Readout label="Inlet Temp" value={co.inletTempA} unit="°C" />
          <Readout
            label="Outlet Temp"
            value={co.outletTempA}
            unit="°C"
            warn={co.outletTempA > 240}
            critical={co.outletTempA > 280}
          />
        </div>
        <div className="mt-3">
          <Bar
            label="Loop A Coolant Level"
            value={co.loopALevel}
            warnBelow={50}
            criticalAt={undefined}
          />
        </div>
      </Panel>

      <Panel title="Coolant Loop B" className="col-span-12 lg:col-span-6">
        <div className="grid grid-cols-2 gap-2">
          <Toggle
            label="Coolant Pump B"
            on={c.coolantPumpB}
            onChange={() => toggleControl("coolantPumpB")}
            disabled={!c.controlPower}
          />
          <Readout label="Flow Rate" value={co.flowB} unit="m³/h" decimals={0} />
          <Readout label="Inlet Temp" value={co.inletTempB} unit="°C" />
          <Readout
            label="Outlet Temp"
            value={co.outletTempB}
            unit="°C"
            warn={co.outletTempB > 240}
            critical={co.outletTempB > 280}
          />
        </div>
        <div className="mt-3">
          <Bar label="Loop B Coolant Level" value={co.loopBLevel} warnBelow={50} />
        </div>
      </Panel>

      <Panel title="Loop Diagnostics" className="col-span-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          <Readout
            label="Total Flow"
            value={co.flowA + co.flowB}
            unit="m³/h"
            decimals={0}
          />
          <Readout label="ΔT Loop A" value={co.outletTempA - co.inletTempA} unit="°C" />
          <Readout label="ΔT Loop B" value={co.outletTempB - co.inletTempB} unit="°C" />
          <Readout
            label="Imbalance"
            value={Math.abs(co.flowA - co.flowB)}
            unit="m³/h"
            decimals={0}
            warn={Math.abs(co.flowA - co.flowB) > 800}
            critical={Math.abs(co.flowA - co.flowB) > 2000}
          />
        </div>
      </Panel>
    </div>
  );
}
