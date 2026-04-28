local SimulationService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))

local state = {
	Mode = "Training",
	IsRunning = false,
	ElapsedTime = 0,
	BatteryPower = false,

	Reactor = {
		ControlMode = "Manual",
		RodHeight = 0,
		TargetRodHeight = 0,
		ReactorPowerPct = 0,
		ThermalPowerMW = 0,
		CoreTemp = ReactorConstants.Reactor.AmbientCoreTemp,
		CorePressure = 0.1,
		CoreWater = ReactorConstants.Reactor.NominalCoreWater,
		NeutronFlux = 0,
		DecayHeat = 0,
		Scrammed = false,
		MeltdownRisk = 0,
		Melted = false,
		RecircPumpA = false,
		RecircPumpB = false,
	},

	Coolant = {
		LoopAEnabled = false,
		LoopBEnabled = false,
		PumpASpeed = 0,
		PumpBSpeed = 0,
		PumpATargetSpeed = 0,
		PumpBTargetSpeed = 0,
		FlowA = 0,
		FlowB = 0,
		LoopALevel = 80,
		LoopBLevel = 80,
		InletTemp = 25,
		OutletTemp = 25,
		OutletPressure = 0.1,
		CavitationA = false,
		CavitationB = false,
	},

	Feedwater = {
		FeedPumpA = false,
		FeedPumpB = false,
		CondPumpA = false,
		CondPumpB = false,
		MakeupPump = false,
		FeedPumpASpeed = 0,
		FeedPumpBSpeed = 0,
		CondPumpASpeed = 0,
		CondPumpBSpeed = 0,
		FeedPumpATarget = 0,
		FeedPumpBTarget = 0,
		CondPumpATarget = 0,
		CondPumpBTarget = 0,
		HotwellLevel = 50,
		DeaeratorALevel = 40,
		DeaeratorBLevel = 40,
		DeaeratorATemp = 25,
		DeaeratorBTemp = 25,
		SteamInletA = 0,
		SteamInletB = 0,
		ReliefValve = 0,
		FeedLineDry = false,
	},

	Steam = {
		SteamPressure = 0.1,
		MainSteamValve = 0,
		BypassValve = 0,
		TargetMainValve = 0,
		TargetBypassValve = 0,
		TurbineRPM = 0,
		TurbineTarget = 0,
		Vibration = 0,
		GeneratorMW = 0,
		TransformerLoad = 0,
		Synced = false,
		TurbineTripped = false,
	},

	Alarms = {
		Active = {},
		Acknowledged = {},
		History = {},
	},

	Faults = {
		Active = {},
	},

	Procedure = {
		StartedAt = 0,
		CurrentStep = 1,
		CompletedSteps = {},
		Done = false,
	},

	Score = {
		Value = 0,
		StableSeconds = 0,
		ProductionSeconds = 0,
		TripCount = 0,
		ScramCount = 0,
		StartupCompleted = false,
	},

	Players = {},
}

SimulationService.State = state
SimulationService._stepFunctions = {}
SimulationService._readyEvent = Instance.new("BindableEvent")

function SimulationService:GetState()
	return state
end

function SimulationService:RegisterStepper(name, priority, fn)
	table.insert(self._stepFunctions, {
		Name = name,
		Priority = priority or 50,
		Fn = fn,
	})
	table.sort(self._stepFunctions, function(a, b)
		return a.Priority < b.Priority
	end)
end

function SimulationService:GetDifficultyConfig()
	return Config.Difficulty[state.Mode] or Config.Difficulty.Normal
end

function SimulationService:SetMode(modeName)
	if Config.Difficulty[modeName] then
		state.Mode = modeName
	end
end

function SimulationService:Reset()
	state.IsRunning = false
	state.ElapsedTime = 0
	state.BatteryPower = false

	state.Reactor.ControlMode = "Manual"
	state.Reactor.RodHeight = 0
	state.Reactor.TargetRodHeight = 0
	state.Reactor.ReactorPowerPct = 0
	state.Reactor.ThermalPowerMW = 0
	state.Reactor.CoreTemp = ReactorConstants.Reactor.AmbientCoreTemp
	state.Reactor.CorePressure = 0.1
	state.Reactor.CoreWater = ReactorConstants.Reactor.NominalCoreWater
	state.Reactor.NeutronFlux = 0
	state.Reactor.DecayHeat = 0
	state.Reactor.Scrammed = false
	state.Reactor.MeltdownRisk = 0
	state.Reactor.Melted = false
	state.Reactor.RecircPumpA = false
	state.Reactor.RecircPumpB = false

	for k, _ in pairs(state.Coolant) do
		if type(state.Coolant[k]) == "number" then
			state.Coolant[k] = 0
		elseif type(state.Coolant[k]) == "boolean" then
			state.Coolant[k] = false
		end
	end
	state.Coolant.LoopALevel = 80
	state.Coolant.LoopBLevel = 80
	state.Coolant.InletTemp = 25
	state.Coolant.OutletTemp = 25

	for k, _ in pairs(state.Feedwater) do
		if type(state.Feedwater[k]) == "number" then
			state.Feedwater[k] = 0
		elseif type(state.Feedwater[k]) == "boolean" then
			state.Feedwater[k] = false
		end
	end
	state.Feedwater.HotwellLevel = 50
	state.Feedwater.DeaeratorALevel = 40
	state.Feedwater.DeaeratorBLevel = 40
	state.Feedwater.DeaeratorATemp = 25
	state.Feedwater.DeaeratorBTemp = 25

	for k, _ in pairs(state.Steam) do
		if type(state.Steam[k]) == "number" then
			state.Steam[k] = 0
		elseif type(state.Steam[k]) == "boolean" then
			state.Steam[k] = false
		end
	end
	state.Steam.SteamPressure = 0.1

	state.Alarms.Active = {}
	state.Alarms.Acknowledged = {}
	state.Alarms.History = {}
	state.Faults.Active = {}

	state.Procedure.StartedAt = 0
	state.Procedure.CurrentStep = 1
	state.Procedure.CompletedSteps = {}
	state.Procedure.Done = false

	state.Score.Value = 0
	state.Score.StableSeconds = 0
	state.Score.ProductionSeconds = 0
	state.Score.TripCount = 0
	state.Score.ScramCount = 0
	state.Score.StartupCompleted = false
end

function SimulationService:Start()
	if state.IsRunning then
		return
	end
	state.IsRunning = true
	state.ElapsedTime = 0

	task.spawn(function()
		local last = os.clock()
		while state.IsRunning do
			local now = os.clock()
			local dt = math.min(now - last, Config.Tick.SimulationStep * 4)
			last = now
			state.ElapsedTime += dt

			for _, entry in ipairs(self._stepFunctions) do
				local ok, err = pcall(entry.Fn, state, dt)
				if not ok then
					warn("[SimulationService] Stepper error in", entry.Name, err)
				end
			end

			task.wait(Config.Tick.SimulationStep)
		end
	end)

	self._readyEvent:Fire()
end

function SimulationService:Stop()
	state.IsRunning = false
end

function SimulationService:Ready()
	if state.IsRunning then
		return
	end
	self._readyEvent.Event:Wait()
end

return SimulationService
