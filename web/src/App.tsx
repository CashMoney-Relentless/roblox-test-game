import { useEffect, useRef } from "react";
import { useStore } from "./store/store";
import { SideNav } from "./components/SideNav";
import { StatusBar } from "./components/StatusBar";
import { LogPanel } from "./components/LogPanel";
import { OverviewPanel } from "./panels/OverviewPanel";
import { ReactorPanel } from "./panels/ReactorPanel";
import { CoolantPanel } from "./panels/CoolantPanel";
import { FeedwaterPanel } from "./panels/FeedwaterPanel";
import { TurbinePanel } from "./panels/TurbinePanel";
import { AlarmPanel } from "./panels/AlarmPanel";
import { ChecklistPanel } from "./panels/ChecklistPanel";
import { TICK_HZ } from "./sim/constants";
import { activeAlarmIds } from "./sim/alarms";
import { alarmBleep } from "./audio";

function ScreenView() {
  const screen = useStore((s) => s.selectedScreen);
  switch (screen) {
    case "reactor":
      return <ReactorPanel />;
    case "coolant":
      return <CoolantPanel />;
    case "feedwater":
      return <FeedwaterPanel />;
    case "turbine":
      return <TurbinePanel />;
    case "alarms":
      return <AlarmPanel />;
    case "checklist":
      return <ChecklistPanel />;
    case "overview":
    default:
      return <OverviewPanel />;
  }
}

function App() {
  const tick = useStore((s) => s.tick);
  const audioOn = useStore((s) => s.plant.controls.alarmAudio);
  const lastAlarmCount = useRef(0);

  useEffect(() => {
    const interval = window.setInterval(() => tick(), 1000 / TICK_HZ);
    return () => window.clearInterval(interval);
  }, [tick]);

  // Alarm beeper: when number of active alarms grows, emit a beep.
  useEffect(() => {
    const unsub = useStore.subscribe((s) => {
      const count = activeAlarmIds(s.plant).length;
      if (count > lastAlarmCount.current && audioOn) {
        alarmBleep();
      }
      lastAlarmCount.current = count;
    });
    return unsub;
  }, [audioOn]);

  return (
    <div className="h-screen w-screen flex flex-col bg-panel-950">
      <StatusBar />
      <div className="flex-1 flex min-h-0">
        <SideNav />
        <main className="flex-1 min-h-0 overflow-y-auto p-3 scanline">
          <div className="grid grid-cols-1 gap-3">
            <ScreenView />
            <LogPanel />
          </div>
          <footer className="mt-4 text-[10px] text-panel-400 font-mono opacity-70 text-center">
            Argonne-1 simulation v1 · all data fictional · click anywhere to enable audio
          </footer>
        </main>
      </div>
    </div>
  );
}

export default App;
