local ReactorCoreService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))
local Config = require(Shared:WaitForChild("Config"))

local R = ReactorConstants.Reactor

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function approach(current, target, rate, dt)
	if current < target then
		return math.min(current + rate * dt, target)
	else
		return math.max(current - rate * dt, target)
	end
end

function ReactorCoreService.Step(state, dt)
	local r = state.Reactor
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal
	local k = mode.ChangeRateMultiplier

	if r.ControlMode == "Auto" and not r.Scrammed then
		local desiredPct = state.Steam.GeneratorMW > 0
			and clamp(state.Steam.GeneratorMW / 1000 * 80, 0, 90)
			or 0
		r.TargetRodHeight = desiredPct
	end

	local rodRate = 6 * k
	if r.Scrammed then
		r.TargetRodHeight = 0
		rodRate = 60
	end
	r.RodHeight = approach(r.RodHeight, r.TargetRodHeight, rodRate, dt)

	local fluxTarget = (r.RodHeight / 100) ^ 1.4
	r.NeutronFlux = approach(r.NeutronFlux, fluxTarget, 0.6 * k, dt)
	if r.Scrammed then
		r.NeutronFlux = approach(r.NeutronFlux, 0, 4.0, dt)
	end

	local thermalTarget = r.NeutronFlux * R.MaxThermalPowerMW
	r.ThermalPowerMW = approach(r.ThermalPowerMW, thermalTarget, R.MaxThermalPowerMW * 0.5 * dt, dt)

	if r.Scrammed then
		local decayPower = R.MaxThermalPowerMW * R.DecayHeatFraction *
			math.exp(-(state.ElapsedTime - (state.Procedure.ScramTime or state.ElapsedTime)) / R.DecayTimeConstant)
		r.DecayHeat = math.max(decayPower, 0)
		r.ThermalPowerMW = math.max(r.ThermalPowerMW, r.DecayHeat)
	else
		r.DecayHeat = 0
	end

	r.ReactorPowerPct = clamp((r.ThermalPowerMW / R.MaxThermalPowerMW) * 100, 0, 130)

	local coolantFlow = (state.Coolant.FlowA + state.Coolant.FlowB) * 0.5
	local coolingFactor = clamp(coolantFlow / 80, 0.05, 1.6)
	local heatGain = (r.ThermalPowerMW / R.MaxThermalPowerMW) * 240 * dt
	local heatLoss = (r.CoreTemp - 25) * 0.0028 * coolingFactor * dt * 60
	r.CoreTemp = clamp(r.CoreTemp + heatGain - heatLoss, 20, 600)

	if state.Coolant.FlowA + state.Coolant.FlowB > 5 then
		state.Coolant.OutletTemp = approach(state.Coolant.OutletTemp, r.CoreTemp, 30, dt)
		state.Coolant.InletTemp = approach(state.Coolant.InletTemp,
			math.max(r.CoreTemp - 75 - coolingFactor * 5, 30), 20, dt)
	else
		state.Coolant.OutletTemp = approach(state.Coolant.OutletTemp, r.CoreTemp, 5, dt)
	end

	local pressureFromHeat = math.max(0, (r.CoreTemp - 100) * 0.025)
	local pressureRelief = (state.Steam.MainSteamValve / 100) * 1.4
		+ (state.Steam.BypassValve / 100) * 1.0
		+ (state.Feedwater.ReliefValve / 100) * 2.5
	r.CorePressure = approach(r.CorePressure,
		math.max(0, pressureFromHeat - pressureRelief), 1.2, dt)

	local feedFlow = (state.Feedwater.FeedPumpASpeed + state.Feedwater.FeedPumpBSpeed) * 0.5 / 100
	local steamLoss = (state.Steam.MainSteamValve / 100) * 0.5
		+ (state.Steam.BypassValve / 100) * 0.4
		+ (state.Feedwater.ReliefValve / 100) * 0.6
	r.CoreWater = clamp(r.CoreWater + (feedFlow * 4 - steamLoss * 6) * dt, 0, 105)

	if r.RecircPumpA then
		state.Coolant.LoopALevel = state.Coolant.LoopALevel
			+ (r.CoreWater - state.Coolant.LoopALevel) * 0.05 * dt
	end
	if r.RecircPumpB then
		state.Coolant.LoopBLevel = state.Coolant.LoopBLevel
			+ (r.CoreWater - state.Coolant.LoopBLevel) * 0.05 * dt
	end

	local meltdownPressure = math.max(0, (r.CoreTemp - 360) * 0.5)
		+ math.max(0, (r.CorePressure - 8.6) * 6)
		+ math.max(0, (15 - r.CoreWater) * 1.2)
	r.MeltdownRisk = clamp(r.MeltdownRisk + meltdownPressure * dt - 4 * dt, 0, 200)

	if r.MeltdownRisk >= 200 and not r.Melted then
		r.Melted = true
		r.Scrammed = true
	end
end

function ReactorCoreService.Scram(state, reason)
	local r = state.Reactor
	if r.Scrammed then
		return
	end
	r.Scrammed = true
	r.TargetRodHeight = 0
	state.Procedure.ScramTime = state.ElapsedTime
	state.Score.ScramCount += 1
	if reason then
		state.Reactor.LastScramReason = reason
	end
end

function ReactorCoreService.Reset(state)
	local r = state.Reactor
	r.Scrammed = false
	r.Melted = false
	r.MeltdownRisk = 0
	r.RodHeight = 0
	r.TargetRodHeight = 0
	r.NeutronFlux = 0
	r.ThermalPowerMW = 0
	r.CoreTemp = R.AmbientCoreTemp
	r.CorePressure = 0.1
	r.CoreWater = R.NominalCoreWater
	r.LastScramReason = nil
end

return ReactorCoreService
