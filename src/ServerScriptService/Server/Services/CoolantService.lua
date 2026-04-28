local CoolantService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))
local Config = require(Shared:WaitForChild("Config"))

local C = ReactorConstants.Coolant

local function approach(current, target, rate, dt)
	if current < target then
		return math.min(current + rate * dt, target)
	else
		return math.max(current - rate * dt, target)
	end
end

function CoolantService.Step(state, dt)
	local c = state.Coolant
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal

	if not state.BatteryPower then
		c.PumpATargetSpeed = 0
		c.PumpBTargetSpeed = 0
	end
	if not c.LoopAEnabled then
		c.PumpATargetSpeed = 0
	end
	if not c.LoopBEnabled then
		c.PumpBTargetSpeed = 0
	end

	c.PumpASpeed = approach(c.PumpASpeed, c.PumpATargetSpeed, C.PumpRampRate * mode.ChangeRateMultiplier, dt)
	c.PumpBSpeed = approach(c.PumpBSpeed, c.PumpBTargetSpeed, C.PumpRampRate * mode.ChangeRateMultiplier, dt)

	local function calcFlow(speed, level)
		if level < C.DryLevel then
			return 0
		end
		local cavitate = level < C.CavitationLevel
		local efficiency = cavitate and 0.4 or 1.0
		return (speed / 100) * C.MaxFlow * efficiency
	end

	c.FlowA = calcFlow(c.PumpASpeed, c.LoopALevel)
	c.FlowB = calcFlow(c.PumpBSpeed, c.LoopBLevel)
	c.CavitationA = c.LoopALevel < C.CavitationLevel and c.PumpASpeed > 5
	c.CavitationB = c.LoopBLevel < C.CavitationLevel and c.PumpBSpeed > 5

	c.LoopALevel -= (c.PumpASpeed / 100) * 0.6 * dt
	c.LoopBLevel -= (c.PumpBSpeed / 100) * 0.6 * dt
	if state.Reactor.RecircPumpA then
		c.LoopALevel += 1.5 * dt
	end
	if state.Reactor.RecircPumpB then
		c.LoopBLevel += 1.5 * dt
	end

	if state.Feedwater.MakeupPump then
		c.LoopALevel += 1.0 * dt
		c.LoopBLevel += 1.0 * dt
	end

	c.LoopALevel = math.clamp(c.LoopALevel, 0, 100)
	c.LoopBLevel = math.clamp(c.LoopBLevel, 0, 100)

	local thermalLoad = state.Reactor.ThermalPowerMW
	local totalFlow = c.FlowA + c.FlowB
	local pressureRise = thermalLoad / 1500 - totalFlow / 200
	local desiredOutlet = math.max(state.Reactor.CorePressure + pressureRise, 0)
	c.OutletPressure = approach(c.OutletPressure, desiredOutlet, 1.2, dt)
end

function CoolantService.SetPumpA(state, enabled, target)
	state.Coolant.LoopAEnabled = enabled and true or false
	if not enabled then
		state.Coolant.PumpATargetSpeed = 0
	elseif target then
		state.Coolant.PumpATargetSpeed = math.clamp(target, 0, 100)
	end
end

function CoolantService.SetPumpB(state, enabled, target)
	state.Coolant.LoopBEnabled = enabled and true or false
	if not enabled then
		state.Coolant.PumpBTargetSpeed = 0
	elseif target then
		state.Coolant.PumpBTargetSpeed = math.clamp(target, 0, 100)
	end
end

function CoolantService.SetPumpATarget(state, target)
	state.Coolant.PumpATargetSpeed = math.clamp(target, 0, 100)
end

function CoolantService.SetPumpBTarget(state, target)
	state.Coolant.PumpBTargetSpeed = math.clamp(target, 0, 100)
end

return CoolantService
