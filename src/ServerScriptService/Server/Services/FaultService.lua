local FaultService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local FaultDefinitions = {
	{
		Id = "PumpAFailure",
		Display = "COOLANT PUMP A FAILURE",
		Apply = function(state)
			state.Coolant.LoopAEnabled = false
			state.Coolant.PumpATargetSpeed = 0
		end,
		ClearWhen = function(state)
			return state.Coolant.PumpASpeed < 5 and not state.Coolant.LoopAEnabled
		end,
	},
	{
		Id = "PumpBFailure",
		Display = "COOLANT PUMP B FAILURE",
		Apply = function(state)
			state.Coolant.LoopBEnabled = false
			state.Coolant.PumpBTargetSpeed = 0
		end,
		ClearWhen = function(state)
			return state.Coolant.PumpBSpeed < 5 and not state.Coolant.LoopBEnabled
		end,
	},
	{
		Id = "MainSteamValveStuck",
		Display = "MAIN STEAM VALVE STUCK",
		Apply = function(state)
			state.Steam._stuckMain = state.Steam.MainSteamValve
		end,
		Tick = function(state)
			state.Steam.TargetMainValve = state.Steam._stuckMain or 0
		end,
		ClearWhen = function(state)
			return false
		end,
	},
	{
		Id = "SensorFaultCoreTemp",
		Display = "SENSOR FAULT - CORE TEMP",
		Apply = function(state)
			state.Reactor._sensorBiasTemp = (math.random() - 0.5) * 60
		end,
		ClearWhen = function(state)
			return false
		end,
	},
	{
		Id = "LoadDemandSpike",
		Display = "GRID LOAD DEMAND SPIKE",
		Apply = function(state)
			state.Steam._loadSpikeUntil = state.ElapsedTime + 90
		end,
		Tick = function(state)
			if state.Steam._loadSpikeUntil and state.ElapsedTime < state.Steam._loadSpikeUntil then
				state.Steam.GeneratorMW = math.min(1200, state.Steam.GeneratorMW + 0.4)
			end
		end,
		ClearWhen = function(state)
			return state.Steam._loadSpikeUntil and state.ElapsedTime > state.Steam._loadSpikeUntil
		end,
	},
	{
		Id = "CondenserCoolingLoss",
		Display = "CONDENSER COOLING LOSS",
		Apply = function(state)
			state.Feedwater._condenserPenalty = 0.6
		end,
		Tick = function(state)
			state.Feedwater.HotwellLevel = math.max(0, state.Feedwater.HotwellLevel - 0.5 * 0.05)
		end,
		ClearWhen = function(state)
			return false
		end,
	},
	{
		Id = "DeaeratorTempDrop",
		Display = "DEAERATOR TEMP DROP",
		Apply = function(state)
			state.Feedwater.DeaeratorATemp = math.max(20, state.Feedwater.DeaeratorATemp - 30)
			state.Feedwater.DeaeratorBTemp = math.max(20, state.Feedwater.DeaeratorBTemp - 30)
		end,
		ClearWhen = function(state)
			return state.Feedwater.DeaeratorATemp > 100 and state.Feedwater.DeaeratorBTemp > 100
		end,
	},
	{
		Id = "FeedwaterInterruption",
		Display = "FEEDWATER INTERRUPTION",
		Apply = function(state)
			state.Feedwater.FeedPumpA = false
			state.Feedwater.FeedPumpB = false
		end,
		ClearWhen = function(state)
			return state.Feedwater.FeedPumpA and state.Feedwater.FeedPumpB
		end,
	},
	{
		Id = "TransformerOverload",
		Display = "TRANSFORMER OVERLOAD EVENT",
		Apply = function(state)
			state.Steam._transformerStress = state.ElapsedTime + 60
		end,
		Tick = function(state)
			if state.Steam._transformerStress and state.ElapsedTime < state.Steam._transformerStress then
				state.Steam.TransformerLoad = state.Steam.TransformerLoad + 0.4
			end
		end,
		ClearWhen = function(state)
			return state.Steam._transformerStress and state.ElapsedTime > state.Steam._transformerStress
		end,
	},
	{
		Id = "CoolantLoopImbalance",
		Display = "COOLANT LOOP IMBALANCE",
		Apply = function(state)
			state.Coolant.LoopALevel = math.max(0, state.Coolant.LoopALevel - 25)
		end,
		ClearWhen = function(state)
			return state.Coolant.LoopALevel > 60
		end,
	},
}

local function chooseRandomFault()
	return FaultDefinitions[math.random(1, #FaultDefinitions)]
end

function FaultService.Init(state)
	state.Faults._nextRoll = 0
end

function FaultService.Step(state, dt)
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal
	if state.Faults._nextRoll == 0 then
		state.Faults._nextRoll = state.ElapsedTime
			+ math.random(mode.FaultIntervalMin, mode.FaultIntervalMax)
	end

	if state.IsRunning and state.ElapsedTime > state.Faults._nextRoll then
		state.Faults._nextRoll = state.ElapsedTime
			+ math.random(mode.FaultIntervalMin, mode.FaultIntervalMax)
		if math.random() < mode.FaultProbability and state.Reactor.ReactorPowerPct > 5 then
			local fault = chooseRandomFault()
			FaultService.Trigger(state, fault.Id)
		end
	end

	for id, def in pairs(state.Faults.Active) do
		local fdef = nil
		for _, f in ipairs(FaultDefinitions) do
			if f.Id == id then fdef = f; break end
		end
		if fdef and fdef.Tick then
			fdef.Tick(state)
		end
		if fdef and fdef.ClearWhen and fdef.ClearWhen(state) then
			state.Faults.Active[id] = nil
		end
	end
end

function FaultService.Trigger(state, id)
	for _, fdef in ipairs(FaultDefinitions) do
		if fdef.Id == id then
			fdef.Apply(state)
			state.Faults.Active[id] = {
				Id = id,
				Display = fdef.Display,
				StartedAt = state.ElapsedTime,
			}
			return true
		end
	end
	return false
end

function FaultService.Snapshot(state)
	local list = {}
	for id, info in pairs(state.Faults.Active) do
		table.insert(list, {
			Id = id,
			Display = info.Display,
			StartedAt = info.StartedAt,
		})
	end
	return list
end

return FaultService
