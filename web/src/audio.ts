// Tiny WebAudio alarm beeper. We don't ship sound assets — instead we
// synthesise a short 2-tone industrial bleep when a critical alarm
// becomes active. The simulator polls this from the React tree.

let ctx: AudioContext | null = null;

function ensureCtx(): AudioContext | null {
  if (typeof window === "undefined") return null;
  if (!ctx) {
    try {
      ctx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
    } catch {
      return null;
    }
  }
  return ctx;
}

export function beep(frequency = 880, duration = 0.16, volume = 0.05) {
  const c = ensureCtx();
  if (!c) return;
  const osc = c.createOscillator();
  const gain = c.createGain();
  osc.type = "square";
  osc.frequency.value = frequency;
  gain.gain.value = 0;
  osc.connect(gain);
  gain.connect(c.destination);
  const now = c.currentTime;
  gain.gain.setValueAtTime(0, now);
  gain.gain.linearRampToValueAtTime(volume, now + 0.02);
  gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);
  osc.start(now);
  osc.stop(now + duration + 0.02);
}

export function alarmBleep() {
  beep(820, 0.13);
  setTimeout(() => beep(620, 0.16), 130);
}
