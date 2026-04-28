import { useStore } from "../store/store";
import { Panel } from "../components/Panel";
import { AlarmTile } from "../components/AlarmTile";
import { Toggle } from "../components/Toggle";
import { ALARM_DEFS, DIFFICULTY_FACTORS } from "../sim/constants";
import type { AlarmId } from "../sim/types";
import { faultLabel } from "../sim/faults";

export function AlarmPanel() {
  const plant = useStore((s) => s.plant);
  const ackAlarms = useStore((s) => s.ackAlarms);
  const toggleControl = useStore((s) => s.toggleControl);
  const c = plant.controls;
  const showHints = DIFFICULTY_FACTORS[plant.difficulty].hints;

  const ids = Object.keys(ALARM_DEFS) as AlarmId[];
  const sorted = ids.sort((a, b) => {
    const aActive = plant.alarms[a].active ? 0 : 1;
    const bActive = plant.alarms[b].active ? 0 : 1;
    if (aActive !== bActive) return aActive - bActive;
    return ALARM_DEFS[a].label.localeCompare(ALARM_DEFS[b].label);
  });

  return (
    <div className="grid grid-cols-12 gap-3">
      <Panel
        title="Annunciator"
        subtitle={`${Object.values(plant.alarms).filter((a) => a.active).length} active`}
        right={
          <button onClick={ackAlarms} className="industrial-btn !py-1 !text-[10px]">
            Acknowledge
          </button>
        }
        className="col-span-12 lg:col-span-9"
      >
        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-2">
          {sorted.map((id) => (
            <AlarmTile
              key={id}
              def={ALARM_DEFS[id]}
              state={plant.alarms[id]}
              hint={showHints}
            />
          ))}
        </div>
      </Panel>

      <div className="col-span-12 lg:col-span-3 flex flex-col gap-3">
        <Panel title="Audio">
          <Toggle
            label="Alarm Audio"
            on={c.alarmAudio}
            onChange={() => toggleControl("alarmAudio")}
            variant="amber"
          />
          <p className="text-[10px] text-panel-400 mt-2 leading-snug">
            Alarms only clear when the underlying condition is resolved. Acknowledging
            silences the flashing only.
          </p>
        </Panel>

        <Panel title="Active Faults">
          {plant.faults.length === 0 ? (
            <div className="text-xs text-panel-400 italic">No active faults.</div>
          ) : (
            <ul className="text-xs space-y-1 font-display uppercase tracking-wider text-readout-amber">
              {plant.faults.map((f) => (
                <li key={f.id} className="flex items-center gap-2">
                  <span className="led led-on-amber" />
                  {faultLabel(f.id)}
                  <span className="ml-auto font-mono text-[10px] opacity-70">
                    {f.duration.toFixed(0)}s
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>
    </div>
  );
}
