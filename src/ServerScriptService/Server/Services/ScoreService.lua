local ScoreService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))

local R = ReactorConstants.Reactor

local function isStable(state)
	local r = state.Reactor
	return not r.Scrammed
		and r.CoreTemp > 250
		and r.CoreTemp < R.MaxCoreTemp
		and r.CorePressure < R.MaxCorePressure
		and r.CorePressure > 4
		and r.CoreWater > R.LowCoreWater
		and r.CoreWater < R.HighCoreWater
end

function ScoreService.Step(state, dt)
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal
	local mult = mode.ScoreMultiplier
	local s = state.Score

	if state.Steam.GeneratorMW > 50 then
		s.ProductionSeconds += dt
		s.Value += state.Steam.GeneratorMW * Config.Score.BaseMWPerSecond * dt * mult
	end

	if isStable(state) then
		s.StableSeconds += dt
		s.Value += Config.Score.StabilityBonusPerSecond * dt * mult
	end

	local activeAlarms = 0
	for _, _ in pairs(state.Alarms.Active) do
		activeAlarms += 1
	end
	if activeAlarms > 0 then
		s.Value -= Config.Score.AlarmPenaltyPerSecond * dt * mult * activeAlarms
	end

	if s.ProductionSeconds > 120 and not s._stableProductionGiven then
		s._stableProductionGiven = true
		s.Value += Config.Score.StableProductionBonus * mult
	end
end

function ScoreService.OnTrip(state)
	state.Score.Value -= Config.Score.TripPenalty
end

function ScoreService.OnScram(state)
	state.Score.Value -= Config.Score.ScramPenalty
end

function ScoreService.OnMeltdown(state)
	state.Score.Value -= Config.Score.MeltdownPenalty
end

function ScoreService.Snapshot(state)
	return {
		Value = math.floor(state.Score.Value),
		StableSeconds = math.floor(state.Score.StableSeconds),
		ProductionSeconds = math.floor(state.Score.ProductionSeconds),
		TripCount = state.Score.TripCount,
		ScramCount = state.Score.ScramCount,
		StartupCompleted = state.Score.StartupCompleted,
	}
end

return ScoreService
