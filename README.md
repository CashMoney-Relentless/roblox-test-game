# Reactor Control Room Simulators

This repository contains **two** independent implementations of the same
fictional nuclear reactor control-room concept:

| Project | Folder | Stack |
|---|---|---|
| **Argonne-1 Web Sim** (recommended) | [`web/`](./web) | Vite · React · TypeScript · Tailwind · Zustand · Recharts |
| Oakridge Roblox Sim (legacy) | [`src/`](./src) (Rojo) | Roblox / Luau |

Both put the player in the role of a reactor operator running a large
pressurized-water-style reactor from cold start through grid sync to stable
megawatt-class production — juggling coolant balance, feedwater chemistry,
steam pressure, turbine vibration and a procedurally generated stream of plant
faults.

## Quick start (web simulator)

```bash
cd web
npm install
npm run dev   # http://localhost:5173
```

See [`web/README.md`](./web/README.md) for full documentation, project layout,
gameplay walkthrough, save format and customisation guide.

---

## Legacy: Oakridge (Roblox)

The original Roblox implementation is preserved below. It is fully playable in
Roblox Studio: every system in the spec is simulated server-side, every panel is
built dynamically on the client, and the entire annunciator system, startup
checklist, fault injector, scoring, save/progression and emergency response
logic are wired up.

The code is organized so you can drop more screens, panels, faults, or
multiplayer roles in without touching the simulation core.

---

## 1. Build / Sync Instructions (Roblox Studio)

This project is laid out for **Rojo**, the standard tool for syncing Roblox
projects from disk into Studio.

1. Install [Rojo](https://rojo.space/) (`rojo` CLI or Studio plugin).
2. Open this folder. The Rojo entry point is `default.project.json`.
3. Run `rojo serve default.project.json` (or use the Studio plugin's "Connect").
4. In Studio, install the **Rojo plugin** if you haven't, then click **Connect**.
5. Studio will populate the data model with the folder structure below.
6. Press **Play** in Studio. The control room GUI is built automatically.

If you do not want to use Rojo, you can mirror the structure manually:

```
ReplicatedStorage
  Remotes (Folder)
    PanelAction (RemoteEvent)
    SystemUpdate (RemoteEvent)
    AlarmUpdate (RemoteEvent)
    ProcedureUpdate (RemoteEvent)
    RequestSnapshot (RemoteFunction)
  Shared (Folder)
    Config (ModuleScript)
    ReactorConstants (ModuleScript)

ServerScriptService
  Server (Folder)
    Loader (Script)
    Services (Folder)
      SimulationService (ModuleScript)
      ReactorCoreService (ModuleScript)
      CoolantService (ModuleScript)
      FeedwaterService (ModuleScript)
      SteamTurbineService (ModuleScript)
      AlarmService (ModuleScript)
      FaultService (ModuleScript)
      StartupProcedureService (ModuleScript)
      SaveService (ModuleScript)
      ScoreService (ModuleScript)
      PanelService (ModuleScript)

StarterGui
  ControlPanelGui (ScreenGui)

StarterPlayer
  StarterPlayerScripts
    Client (Folder)
      Loader (LocalScript)
      ControlPanelClient (ModuleScript)
      GaugeController (ModuleScript)
      AlarmClient (ModuleScript)
      ProcedureClient (ModuleScript)
      Theme (ModuleScript)
      Widgets (ModuleScript)
```

You then paste the source of each `.lua` file in this repo into the matching
script.

> **Note on the GUI:** the on-screen panels (gauges, switches, sliders, alarm
> tiles, procedure rows, the SCRAM cover, the graph) are all built at runtime
> from `ControlPanelClient`. You do **not** need to lay out every UI object by
> hand. The `ControlPanelGui` ScreenGui is intentionally empty. This is what
> makes the panel "expandable" — adding a new screen is one function call.

If you would still prefer to lay out the GUI manually for art reasons, the
client looks for the following object names (and creates them if missing) under
`ControlPanelGui`:

```
MainFrame
  Header
  Tabs
  Body
    ReactorScreen
    CoolantScreen
    FeedwaterScreen
    TurbineScreen
    AlarmScreen
    ProcedureScreen
    GraphScreen
```

## 2. How To Play

1. Open the **PROCEDURE** tab. Select a difficulty mode (Training is recommended
   for new operators).
2. Open the **REACTOR** tab. Throw the **BATTERY / CONTROL POWER** switch.
   Without it, no other pumps or controls function.
3. Open the **FEEDWATER** tab. Engage **COND PUMP A**, **COND PUMP B**,
   and the **MAKEUP WATER PUMP** (back on the REACTOR tab). Set the condensate
   speed sliders to ~50%. Wait for the **HOTWELL LEVEL** and both
   **DEAERATOR** levels to come up.
4. On **FEEDWATER**, open **STEAM INLET A** and **STEAM INLET B** to ~30% so the
   deaerators warm up. (You won't have steam yet, but as the plant comes online
   they'll begin heating.)
5. Engage **FEED PUMP A** and **B**, set their speed targets to ~40%.
6. Open the **COOLANT** tab. Enable **COOLANT PUMP A** and **B**, ramp them up
   to ~50%. Verify **LOOP A LEVEL** and **LOOP B LEVEL** stay above 30%.
7. Back on **REACTOR**: engage **RECIRC PUMP A** and **B**.
8. Slowly drag the **ROD HEIGHT TARGET** slider up — start with 30%, watch
   neutron flux respond, then continue toward 50–60%.
9. The reactor will heat up. When **CORE TEMP** is above 240 °C, switch to the
   **TURBINE** tab and gently open the **MAIN STEAM VALVE** to ~30–40%. Keep
   **BYPASS VALVE** at ~10–20% as a safety margin.
10. As **TURBINE RPM** approaches 3000, the generator will auto-sync to the
    grid. Increase main steam valve to push **GENERATOR MW** above 600 MW.
11. Hold stable production for 30 seconds — the procedure ends, you receive a
    startup bonus, and you're now operating an active power plant.

If anything goes wrong, the **EMERGENCY SCRAM** button (REACTOR tab) drops all
rods and stops the reaction. It must be clicked **twice** within 1.5 seconds
(this is the cover/confirm). After SCRAM, allow the core to cool below 200 °C
before pressing **RESET REACTOR**. Decay heat is simulated and continues to
climb temperature for a while after shutdown — manage your cooling.

## 3. Architecture

### Data flow

```
Player UI input
  └── PanelAction RemoteEvent ───────┐
                                     ▼
                              PanelService (server)
                                     │
                                     ▼
                          SimulationService.state
                                     ▲
   step loop (every 0.25s, in priority order):
     ReactorCoreService.Step
     CoolantService.Step
     FeedwaterService.Step
     SteamTurbineService.Step
     FaultService.Step
     AlarmService.Step
     StartupProcedureService.Step
     ScoreService.Step
                                     │
                                     ▼
                       SystemUpdate RemoteEvent
                                     │
                                     ▼
                ControlPanelClient (gauges, alarms, etc.)
```

### Key principles

- **Server is the source of truth.** All physics live in
  `SimulationService.state`. The client never mutates reactor values. Even if
  an exploiter calls `PanelAction:FireServer("SCRAM")`, the action is gated by
  `Handlers` in `PanelService` and is just as legal as a button press.
- **Pure-function services.** Each subsystem service exposes a `Step(state, dt)`
  function that is registered with the simulation core. This makes adding a new
  subsystem (say, a chemistry control loop, or backup diesels) a matter of
  writing a module and calling `Simulation:RegisterStepper`.
- **Realistic causal coupling.** Rod height drives flux which drives thermal
  power; thermal power drives core temperature, which interacts with coolant
  flow to set outlet pressure; pressure drives steam pressure (gated by valves)
  which spins the turbine which produces MW which loads the transformer which
  in turn imposes additional alarm states. Failure modes from the spec are all
  modeled — pump cavitation, dry loops, deaerator temperature drop, transformer
  overload, turbine overspeed, decay heat after SCRAM, meltdown risk.
- **Configurable difficulty.** `Config.Difficulty` controls timing, fault
  rates, and score multipliers. `FaultService` schedules events using
  `FaultIntervalMin/Max` and `FaultProbability`. Each fault has `Apply`,
  optional `Tick`, and `ClearWhen` hooks.

## 4. Scripts In This Repo

| Script | Type | Where |
|---|---|---|
| `Config.lua` | ModuleScript | `ReplicatedStorage/Shared/Config` |
| `ReactorConstants.lua` | ModuleScript | `ReplicatedStorage/Shared/ReactorConstants` |
| `Loader.server.lua` | Script | `ServerScriptService/Server/Loader` |
| `SimulationService.lua` | ModuleScript | `ServerScriptService/Server/Services/SimulationService` |
| `ReactorCoreService.lua` | ModuleScript | `ServerScriptService/Server/Services/ReactorCoreService` |
| `CoolantService.lua` | ModuleScript | `ServerScriptService/Server/Services/CoolantService` |
| `FeedwaterService.lua` | ModuleScript | `ServerScriptService/Server/Services/FeedwaterService` |
| `SteamTurbineService.lua` | ModuleScript | `ServerScriptService/Server/Services/SteamTurbineService` |
| `AlarmService.lua` | ModuleScript | `ServerScriptService/Server/Services/AlarmService` |
| `FaultService.lua` | ModuleScript | `ServerScriptService/Server/Services/FaultService` |
| `StartupProcedureService.lua` | ModuleScript | `ServerScriptService/Server/Services/StartupProcedureService` |
| `SaveService.lua` | ModuleScript | `ServerScriptService/Server/Services/SaveService` |
| `ScoreService.lua` | ModuleScript | `ServerScriptService/Server/Services/ScoreService` |
| `PanelService.lua` | ModuleScript | `ServerScriptService/Server/Services/PanelService` |
| `Loader.client.lua` | LocalScript | `StarterPlayerScripts/Client/Loader` |
| `ControlPanelClient.lua` | ModuleScript | `StarterPlayerScripts/Client/ControlPanelClient` |
| `GaugeController.lua` | ModuleScript | `StarterPlayerScripts/Client/GaugeController` |
| `AlarmClient.lua` | ModuleScript | `StarterPlayerScripts/Client/AlarmClient` |
| `ProcedureClient.lua` | ModuleScript | `StarterPlayerScripts/Client/ProcedureClient` |
| `Theme.lua` | ModuleScript | `StarterPlayerScripts/Client/Theme` |
| `Widgets.lua` | ModuleScript | `StarterPlayerScripts/Client/Widgets` |

## 5. Adding More Panels

To add, e.g. a "Containment" screen:

1. Open `ControlPanelClient.lua`.
2. Add `"ContainmentScreen"` to the list of screen names in `buildScreens`.
3. Write a `buildContainmentScreen(screen)` function that uses the helpers from
   `Widgets.lua` (`Widgets.Gauge`, `Widgets.Switch`, `Widgets.Slider`,
   `Widgets.Indicator`, `Widgets.Button`).
4. Call `gauges:Register("MyGauge", g)` for each new gauge so updates flow
   automatically.
5. If you need new server-side behavior, write a new module under
   `ServerScriptService/Server/Services` exposing `Step(state, dt)`, and add a
   line in `Loader.server.lua` calling `Simulation:RegisterStepper`.

## 6. Multiplayer Roles

The architecture is role-ready: `Config.Roles` lists the four roles
(ReactorOperator, TurbineOperator, BalanceOfPlantOperator, Supervisor). The
simulation runs once on the server and is shared between every connected
operator, so a simple per-screen ACL on `extras.TabButtons` and a per-action
allowlist in `PanelService.Handlers` is enough to gate panels by role. This is
intentionally left as a hook (everyone currently sees every panel) so you can
choose how you want to assign roles in your build (lobby, role select GUI,
team service, etc.). The simulation will already work correctly with multiple
players issuing actions concurrently.

## 7. Save / Progression

`SaveService` uses `DataStoreService` (`OakridgeOperator_v1`) and persists per
player:

- `XP` — operator experience points (drives rank).
- `BestMW` — best stable generator output.
- `FastestStartup` — best startup time.
- `SuccessfulStartups` — completed startup procedures.
- `EmergencyScrams` — total SCRAMs.
- `Meltdowns` — meltdowns endured.

Rank titles are read from `ReactorConstants.RankBrackets`.

## 8. Realism Notes / Disclaimer

Oakridge Nuclear Power Station as portrayed here is a fictional facility. The
physics is plausible-looking arcade physics — every rate constant has been
tuned for gameplay tension rather than to match any real reactor. It is **not
a training tool** and should not be used as one. Real plants have many more
interlocks, redundancies, and failure modes than are simulated here.
