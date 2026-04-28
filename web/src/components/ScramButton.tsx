import { useStore } from "../store/store";

export function ScramButton() {
  const armed = useStore((s) => s.plant.controls.scramArmed);
  const scrammed = useStore((s) => s.plant.reactor.scrammed);
  const toggleControl = useStore((s) => s.toggleControl);
  const scram = useStore((s) => s.scram);
  const resetScram = useStore((s) => s.resetScram);

  return (
    <div className="bg-black/60 border border-panel-700 rounded p-3">
      <div className="flex items-center justify-between mb-2">
        <span className="text-[11px] uppercase tracking-[0.2em] text-panel-400 font-display">
          Emergency SCRAM
        </span>
        <button
          className={`industrial-btn !py-1 !text-[10px] ${armed ? "industrial-btn-active" : ""}`}
          onClick={() => toggleControl("scramArmed")}
        >
          {armed ? "Cover Open" : "Open Cover"}
        </button>
      </div>
      <button
        onClick={armed ? scram : undefined}
        disabled={!armed || scrammed}
        className={`w-full py-6 rounded-md font-display font-bold uppercase tracking-[0.3em] text-lg transition border-2 ${
          armed && !scrammed
            ? "border-readout-red text-white animate-pulse"
            : "border-panel-700 text-panel-400 cursor-not-allowed"
        }`}
        style={{
          background:
            armed && !scrammed
              ? "linear-gradient(180deg, #ff3838 0%, #8a0a0a 100%)"
              : "linear-gradient(180deg, #2a0a0a 0%, #150505 100%)",
          boxShadow:
            armed && !scrammed
              ? "0 0 16px rgba(255,56,56,0.6), inset 0 1px 0 rgba(255,255,255,0.25), inset 0 -3px 0 rgba(0,0,0,0.6)"
              : "inset 0 1px 0 rgba(255,255,255,0.05), inset 0 -2px 0 rgba(0,0,0,0.4)",
        }}
      >
        {scrammed ? "SCRAMMED" : "SCRAM"}
      </button>
      {scrammed && (
        <button
          onClick={resetScram}
          className="industrial-btn mt-2 w-full !text-[11px]"
        >
          Reset SCRAM (T &lt; 220°C)
        </button>
      )}
    </div>
  );
}
