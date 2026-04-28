local StartupProcedureService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Steps = {
	{
		Id = "BatteryPower",
		Title = "1. Enable battery / control power",
		Hint = "Throw the BATTERY POWER switch on the main panel.",
		Check = function(state) return state.BatteryPower end,
	},
	{
		Id = "Condensate",
		Title = "2. Start condensate system",
		Hint = "Engage Condensate Pumps A and B and the Makeup Water Pump.",
		Check = function(state)
			return state.Feedwater.CondPumpA and state.Feedwater.CondPumpB
				and state.Feedwater.MakeupPump
		end,
	},
	{
		Id = "FillHotwell",
		Title = "3. Fill hotwell and deaerators",
		Hint = "Wait until hotwell > 50, deaerator A&B > 40.",
		Check = function(state)
			return state.Feedwater.HotwellLevel > 50
				and state.Feedwater.DeaeratorALevel > 40
				and state.Feedwater.DeaeratorBLevel > 40
		end,
	},
	{
		Id = "Feedwater",
		Title = "4. Start feedwater pumps",
		Hint = "Enable Feed Pumps A and B and run them at >= 30%.",
		Check = function(state)
			return state.Feedwater.FeedPumpA and state.Feedwater.FeedPumpB
				and state.Feedwater.FeedPumpASpeed > 25
				and state.Feedwater.FeedPumpBSpeed > 25
		end,
	},
	{
		Id = "Coolant",
		Title = "5. Start coolant pumps",
		Hint = "Enable Loops A and B, ramp up to >= 40%.",
		Check = function(state)
			return state.Coolant.LoopAEnabled and state.Coolant.LoopBEnabled
				and state.Coolant.PumpASpeed > 35
				and state.Coolant.PumpBSpeed > 35
		end,
	},
	{
		Id = "Recirc",
		Title = "6. Enable recirculation pumps",
		Hint = "Engage Recirc Pump A and Recirc Pump B.",
		Check = function(state)
			return state.Reactor.RecircPumpA and state.Reactor.RecircPumpB
		end,
	},
	{
		Id = "RaiseRods",
		Title = "7. Raise control rods slowly",
		Hint = "Raise rods to between 30 and 60 percent.",
		Check = function(state)
			return state.Reactor.RodHeight > 28 and not state.Reactor.Scrammed
		end,
	},
	{
		Id = "HeatUp",
		Title = "8. Heat up reactor",
		Hint = "Wait until core temperature reaches 240 C.",
		Check = function(state)
			return state.Reactor.CoreTemp > 240
		end,
	},
	{
		Id = "Steam",
		Title = "9. Open steam valves gradually",
		Hint = "Open Main Steam Valve to between 25 and 60 percent.",
		Check = function(state)
			return state.Steam.MainSteamValve > 24
		end,
	},
	{
		Id = "Turbine",
		Title = "10. Spin turbine to target RPM",
		Hint = "Bring turbine RPM into the 2980-3050 range.",
		Check = function(state)
			return state.Steam.TurbineRPM > 2950 and state.Steam.TurbineRPM < 3060
		end,
	},
	{
		Id = "Sync",
		Title = "11. Sync generator to grid",
		Hint = "Wait for generator to sync (auto when in RPM band).",
		Check = function(state)
			return state.Steam.Synced
		end,
	},
	{
		Id = "Load",
		Title = "12. Increase load to stable MW output",
		Hint = "Hold generator output above 600 MW for 30 seconds.",
		Check = function(state)
			if state.Steam.GeneratorMW > 600 then
				state.Procedure._loadHold = (state.Procedure._loadHold or 0) + 0.25
			else
				state.Procedure._loadHold = 0
			end
			return (state.Procedure._loadHold or 0) >= 30
		end,
	},
}

function StartupProcedureService.GetSteps()
	local out = {}
	for i, s in ipairs(Steps) do
		out[i] = {
			Id = s.Id,
			Title = s.Title,
			Hint = s.Hint,
		}
	end
	return out
end

function StartupProcedureService.Init(state)
	state.Procedure.StartedAt = state.ElapsedTime
	state.Procedure.CurrentStep = 1
	state.Procedure.CompletedSteps = {}
	state.Procedure.Done = false
end

function StartupProcedureService.Step(state, dt)
	if state.Procedure.Done then
		return
	end
	local step = Steps[state.Procedure.CurrentStep]
	if step and step.Check(state) then
		state.Procedure.CompletedSteps[step.Id] = true
		state.Procedure.CurrentStep += 1
		if state.Procedure.CurrentStep > #Steps then
			state.Procedure.Done = true
			state.Procedure.CompletedAt = state.ElapsedTime
			if not state.Score.StartupCompleted then
				state.Score.StartupCompleted = true
				state.Score.Value += Config.Score.StartupBonus
			end
		end
	end
end

function StartupProcedureService.Snapshot(state)
	return {
		CurrentStep = state.Procedure.CurrentStep,
		Done = state.Procedure.Done,
		CompletedSteps = state.Procedure.CompletedSteps,
		StartedAt = state.Procedure.StartedAt,
		Steps = StartupProcedureService.GetSteps(),
	}
end

return StartupProcedureService
