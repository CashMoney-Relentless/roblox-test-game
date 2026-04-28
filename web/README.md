# Argonne-1 Reactor Control Room (Web)

A serious, technical nuclear reactor control-room simulator built as a single-page
web app. You operate a fictional pressurized-water-style reactor — **Argonne-1**
— from cold shutdown through grid sync to stable megawatt-class production,
managing coolant balance, feedwater chemistry, steam pressure, turbine RPM, and
a procedurally generated stream of plant faults.

This is the first playable version. It implements the full spec:

- Seven control-room screens (Overview, Reactor, Coolant, Feedwater, Turbine,
  Alarms, Procedure)
- 13-step guided startup checklist
- Cause-and-effect physics: rods → heat → steam → RPM → MW
- 20 alarm conditions, severity-coded annunciator with acknowledge & audio
- 11 random fault types with per-difficulty injection rates
- Three difficulty modes: Training (slow + hints), Normal, Expert (fast + more
  faults)
- LocalStorage save: best score, peak MW, fastest startup, successful startups,
  total SCRAMs / trips, operator XP and rank
- Real industrial-panel look: dark background, green/amber/red indicators,
  digital readouts, analog gauges, alarm tiles, toggle switches, sliders,
  Recharts graphs, scanline-style scrolling backdrop

## Tech stack

- React 19 + TypeScript
- Vite 8
- Tailwind CSS 3
- [Zustand](https://zustand-demo.pmnd.rs/) for state
- [Recharts](https://recharts.org/) for graphs
- Web Audio API for the synthesized alarm beeper
- LocalStorage for persistent saves

## Setup

```bash
cd web
npm install
npm run dev      # http://localhost:5173
npm run build    # production build into ./dist
npm run preview  # preview the built bundle
```

## Project layout

```
web/
├── index.html
├── package.json
├── tailwind.config.js
├── postcss.config.js
├── vite.config.ts
└── src/
    ├── App.tsx                # shell, engine loop, alarm beeper
    ├── main.tsx
    ├── audio.ts               # synthesized alarm sound
    ├── index.css              # Tailwind + industrial component styles
    ├── components/            # reusable UI: Panel, Gauge, Bar, Slider,
    │   │                      # Toggle, Readout, AlarmTile, MiniChart,
    │   │                      # ScramButton, SideNav, StatusBar, LogPanel
    │   └── ...
    ├── panels/                # the seven control-room screens
    │   ├── OverviewPanel.tsx
    │   ├── ReactorPanel.tsx
    │   ├── CoolantPanel.tsx
    │   ├── FeedwaterPanel.tsx
    │   ├── TurbinePanel.tsx
    │   ├── AlarmPanel.tsx
    │   └── ChecklistPanel.tsx
    ├── store/
    │   └── store.ts           # Zustand store + tick orchestration
    └── sim/
        ├── types.ts           # all TypeScript types for plant systems
        ├── constants.ts       # alarm definitions, checklist, limits, modes
        ├── initialState.ts    # cold-shutdown plant
        ├── reactor.ts         # physics engine: heat, pressure, steam, RPM, MW
        ├── alarms.ts          # alarm rule table & evaluator
        ├── faults.ts          # random fault injector
        ├── scoring.ts         # stability, efficiency, score, rank
        ├── checklist.ts       # automatic checklist progression
        └── save.ts            # LocalStorage save / reconcile / wipe
```

## How to play

The plant boots in cold shutdown with all pumps and valves off. Open the
**Procedure** panel (07) — it lists 13 startup steps. In Training mode each
step shows a hint. The store automatically marks a step done when the world
state satisfies the test (e.g. when both feedwater pumps are running, the
"Start Feedwater Pumps" step ticks itself green).

Recommended first run (Training mode):

1. **Reactor → Control Power ON.**
2. **Feedwater → Condensate Pump A & B, Makeup Water Pump.** Wait for hotwell
   to climb above 60 %.
3. **Feedwater → open Steam Inlet A & B to ~30 %** to warm the deaerators.
4. **Feedwater → Feedwater Pumps A & B.**
5. **Coolant → Coolant Pumps A & B.**
6. **Reactor → Recirc Pumps ON.**
7. **Reactor → drag rod insertion down toward 50 %.** Heat begins to climb.
8. **Wait** for Steam Pressure ≥ 40 bar (Overview chart shows it).
9. **Turbine → open Main Steam Valve to ~25 %.** RPM climbs.
10. **Turbine → trim Main Steam Valve until RPM is 3500 – 3700.**
11. **Turbine → Sync Generator.** MW starts flowing.
12. **Withdraw rods further & open the steam valve** until output > 100 MW.

After that you're "online". A grid demand target appears in the Generator panel;
keep MW within ±15 % of it to maximise stability score. Random faults will
arrive; resolve them or use **SCRAM** (Reactor panel, lift the cover first) to
shut down the core.

## Save data

A tiny JSON blob persists to `localStorage` under `argonne1.save.v1` containing:

- best score
- highest MW output
- fastest successful startup
- number of successful startups
- total SCRAMs and turbine trips
- operator XP (and computed rank: Trainee → Plant Director)

Use **End Shift** in the status bar to archive a session and apply XP/score to
the save. **Wipe Save** resets it. Save state is also auto-flushed every 10 s.

## Customising

- **Add a fault**: extend `FaultId` in `src/sim/types.ts`, append to `FAULT_POOL`
  / `FAULT_LABELS` / `FAULT_DURATIONS` in `src/sim/faults.ts`, and reference it
  inside `stepReactor` in `src/sim/reactor.ts`.
- **Add an alarm**: add an entry to `ALARM_DEFS` in `src/sim/constants.ts` and a
  test in the `TRIGGER_LIST` in `src/sim/alarms.ts`.
- **Tweak difficulty**: change `DIFFICULTY_FACTORS` in `src/sim/constants.ts`.
- **Add a panel/screen**: drop a new component in `src/panels/`, add an entry
  to `SideNav.tsx`, and a case to the `ScreenView` switch in `App.tsx`.

This codebase intentionally keeps the simulation engine in plain functions
operating on a `PlantState` object so the engine can be unit-tested or moved to
a Web Worker later.
