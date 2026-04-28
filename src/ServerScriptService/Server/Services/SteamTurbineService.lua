local SteamTurbineService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))
local Config = require(Shared:WaitForChild("Config"))

local S = ReactorConstants.Steam

local function approach(current, target, rate, dt)
	if current < target then
		return math.min(current + rate * dt, target)
	else
		return math.max(current - rate * dt, target)
	end
end

function SteamTurbineService.Step(state, dt)
	local s = state.Steam
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal

	s.MainSteamValve = approach(s.MainSteamValve, s.TargetMainValve, 8 * mode.ChangeRateMultiplier, dt)
	s.BypassValve = approach(s.BypassValve, s.TargetBypassValve, 14 * mode.ChangeRateMultiplier, dt)

	local steamGain = (state.Reactor.CorePressure / S.NominalSteamPressure) * 1.2
	local steamRelease = (s.MainSteamValve / 100) * 1.0 + (s.BypassValve / 100) * 1.4
	s.SteamPressure = math.clamp(s.SteamPressure + (steamGain - steamRelease) * dt, 0, 12)

	if s.TurbineTripped then
		s.TurbineTarget = 0
	else
		s.TurbineTarget = math.clamp((s.MainSteamValve / 100) * S.NominalTurbineRPM
			+ (s.SteamPressure / S.NominalSteamPressure) * 200, 0, 4000)
	end
	s.TurbineRPM = approach(s.TurbineRPM, s.TurbineTarget,
		S.TurbineRampRate * mode.ChangeRateMultiplier, dt)

	s.Vibration = math.max(0, (s.TurbineRPM - S.NominalTurbineRPM) * 0.1)
		+ (s.SteamPressure > S.MaxSteamPressure and (s.SteamPressure - S.MaxSteamPressure) * 8 or 0)
		+ (state.Reactor.CoreWater > 92 and (state.Reactor.CoreWater - 92) * 4 or 0)

	if not s.Synced and s.TurbineRPM >= S.SyncRPM and s.TurbineRPM <= 3050 then
		s.Synced = true
	end
	if s.Synced and (s.TurbineRPM < 2700 or s.TurbineTripped) then
		s.Synced = false
	end

	if s.Synced and not s.TurbineTripped then
		local target = math.max(0, (s.MainSteamValve / 100) * S.NominalGeneratorMW
			* math.min(1.2, s.SteamPressure / S.NominalSteamPressure))
		s.GeneratorMW = approach(s.GeneratorMW, target, 80 * mode.ChangeRateMultiplier, dt)
	else
		s.GeneratorMW = approach(s.GeneratorMW, 0, 200, dt)
	end

	local pumpLoad = ((state.Coolant.PumpASpeed + state.Coolant.PumpBSpeed) / 200) * 30
		+ ((state.Feedwater.FeedPumpASpeed + state.Feedwater.FeedPumpBSpeed) / 200) * 25
	s.TransformerLoad = s.GeneratorMW + pumpLoad

	if not s.TurbineTripped then
		if s.TurbineRPM > S.TripRPM
			or s.SteamPressure > S.OverpressureSteam
			or s.Vibration > S.VibrationOverspeedThreshold then
			s.TurbineTripped = true
			s.TargetMainValve = 0
			s.TargetBypassValve = 100
			state.Score.TripCount += 1
		end
	end
end

function SteamTurbineService.SetMainValve(state, target)
	state.Steam.TargetMainValve = math.clamp(target, 0, 100)
end

function SteamTurbineService.SetBypassValve(state, target)
	state.Steam.TargetBypassValve = math.clamp(target, 0, 100)
end

function SteamTurbineService.ResetTurbine(state)
	state.Steam.TurbineTripped = false
	state.Steam.TurbineRPM = 0
	state.Steam.GeneratorMW = 0
	state.Steam.Synced = false
end

return SteamTurbineService
