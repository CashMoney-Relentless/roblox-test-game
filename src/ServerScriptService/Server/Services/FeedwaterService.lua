local FeedwaterService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))
local Config = require(Shared:WaitForChild("Config"))

local F = ReactorConstants.Feedwater

local function approach(current, target, rate, dt)
	if current < target then
		return math.min(current + rate * dt, target)
	else
		return math.max(current - rate * dt, target)
	end
end

function FeedwaterService.Step(state, dt)
	local f = state.Feedwater
	local mode = Config.Difficulty[state.Mode] or Config.Difficulty.Normal

	if not state.BatteryPower then
		f.FeedPumpATarget = 0
		f.FeedPumpBTarget = 0
		f.CondPumpATarget = 0
		f.CondPumpBTarget = 0
	end

	if not f.FeedPumpA then f.FeedPumpATarget = 0 end
	if not f.FeedPumpB then f.FeedPumpBTarget = 0 end
	if not f.CondPumpA then f.CondPumpATarget = 0 end
	if not f.CondPumpB then f.CondPumpBTarget = 0 end

	f.FeedPumpASpeed = approach(f.FeedPumpASpeed, f.FeedPumpATarget,
		F.FeedPumpRampRate * mode.ChangeRateMultiplier, dt)
	f.FeedPumpBSpeed = approach(f.FeedPumpBSpeed, f.FeedPumpBTarget,
		F.FeedPumpRampRate * mode.ChangeRateMultiplier, dt)
	f.CondPumpASpeed = approach(f.CondPumpASpeed, f.CondPumpATarget,
		F.CondPumpRampRate * mode.ChangeRateMultiplier, dt)
	f.CondPumpBSpeed = approach(f.CondPumpBSpeed, f.CondPumpBTarget,
		F.CondPumpRampRate * mode.ChangeRateMultiplier, dt)

	local condDrawA = (f.CondPumpASpeed / 100) * 1.4
	local condDrawB = (f.CondPumpBSpeed / 100) * 1.4
	local feedDrawA = (f.FeedPumpASpeed / 100) * 1.0
	local feedDrawB = (f.FeedPumpBSpeed / 100) * 1.0
	local makeup = f.MakeupPump and F.MakeupRate or 0

	f.HotwellLevel += (makeup * 0.5 - condDrawA - condDrawB) * dt
	f.HotwellLevel = math.clamp(f.HotwellLevel, 0, 100)

	f.DeaeratorALevel += (condDrawA - feedDrawA) * dt
	f.DeaeratorBLevel += (condDrawB - feedDrawB) * dt
	f.DeaeratorALevel = math.clamp(f.DeaeratorALevel, 0, 100)
	f.DeaeratorBLevel = math.clamp(f.DeaeratorBLevel, 0, 100)

	local steamHeatA = (f.SteamInletA / 100) * 35 * dt
	local steamHeatB = (f.SteamInletB / 100) * 35 * dt
	f.DeaeratorATemp = math.clamp(f.DeaeratorATemp + steamHeatA - 0.6 * dt, 20, 200)
	f.DeaeratorBTemp = math.clamp(f.DeaeratorBTemp + steamHeatB - 0.6 * dt, 20, 200)

	f.FeedLineDry = (f.DeaeratorALevel < 5 and f.FeedPumpASpeed > 5)
		or (f.DeaeratorBLevel < 5 and f.FeedPumpBSpeed > 5)
end

function FeedwaterService.SetSwitch(state, name, value)
	local f = state.Feedwater
	if name == "FeedPumpA" then f.FeedPumpA = value and true or false end
	if name == "FeedPumpB" then f.FeedPumpB = value and true or false end
	if name == "CondPumpA" then f.CondPumpA = value and true or false end
	if name == "CondPumpB" then f.CondPumpB = value and true or false end
	if name == "MakeupPump" then f.MakeupPump = value and true or false end
end

function FeedwaterService.SetTarget(state, name, target)
	local f = state.Feedwater
	target = math.clamp(target, 0, 100)
	if name == "FeedPumpA" then f.FeedPumpATarget = target end
	if name == "FeedPumpB" then f.FeedPumpBTarget = target end
	if name == "CondPumpA" then f.CondPumpATarget = target end
	if name == "CondPumpB" then f.CondPumpBTarget = target end
	if name == "SteamInletA" then f.SteamInletA = target end
	if name == "SteamInletB" then f.SteamInletB = target end
	if name == "ReliefValve" then f.ReliefValve = target end
end

return FeedwaterService
