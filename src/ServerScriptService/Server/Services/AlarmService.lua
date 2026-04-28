local AlarmService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))

local R = ReactorConstants.Reactor
local C = ReactorConstants.Coolant
local F = ReactorConstants.Feedwater
local S = ReactorConstants.Steam
local AlarmDefs = ReactorConstants.Alarms

local function setAlarm(state, id, active)
	local alarms = state.Alarms.Active
	if active then
		if not alarms[id] then
			alarms[id] = {
				Id = id,
				ActivatedAt = state.ElapsedTime,
				Severity = AlarmDefs[id] and AlarmDefs[id].Severity or "Warning",
				Display = AlarmDefs[id] and AlarmDefs[id].Display or id,
				Hint = AlarmDefs[id] and AlarmDefs[id].Hint or "",
			}
			table.insert(state.Alarms.History, {
				Id = id,
				At = state.ElapsedTime,
				Type = "Activated",
			})
		end
	else
		if alarms[id] then
			alarms[id] = nil
			state.Alarms.Acknowledged[id] = nil
			table.insert(state.Alarms.History, {
				Id = id,
				At = state.ElapsedTime,
				Type = "Cleared",
			})
		end
	end
end

local function evaluateConditions(state)
	local r = state.Reactor
	local c = state.Coolant
	local f = state.Feedwater
	local s = state.Steam

	setAlarm(state, "CoreWaterLow", r.CoreWater < R.LowCoreWater)
	setAlarm(state, "CoreWaterHigh", r.CoreWater > R.HighCoreWater)
	setAlarm(state, "CoreTempHigh", r.CoreTemp > R.MaxCoreTemp - 10)
	setAlarm(state, "CorePressureHigh", r.CorePressure > R.MaxCorePressure - 0.5)

	setAlarm(state, "CoolantLoopADry", c.LoopALevel < C.DryLevel + 5)
	setAlarm(state, "CoolantLoopBDry", c.LoopBLevel < C.DryLevel + 5)
	setAlarm(state, "PumpCavitation", c.CavitationA or c.CavitationB)
	setAlarm(state, "HighOutletPressure", c.OutletPressure > C.MaxOutletPressure)

	setAlarm(state, "LowHotwellLevel", f.HotwellLevel < F.LowHotwellLevel)
	setAlarm(state, "DeaeratorALow", f.DeaeratorALevel < F.LowDeaeratorLevel)
	setAlarm(state, "DeaeratorBLow", f.DeaeratorBLevel < F.LowDeaeratorLevel)
	setAlarm(state, "DeaeratorATempLow", f.DeaeratorATemp < F.LowDeaeratorTemp and (f.FeedPumpA or f.FeedPumpB))
	setAlarm(state, "DeaeratorBTempLow", f.DeaeratorBTemp < F.LowDeaeratorTemp and (f.FeedPumpA or f.FeedPumpB))
	setAlarm(state, "FeedLoopDry", f.FeedLineDry)
	setAlarm(state, "RecircLoopDry",
		(r.RecircPumpA and c.LoopALevel < C.DryLevel) or (r.RecircPumpB and c.LoopBLevel < C.DryLevel))

	setAlarm(state, "CircuitOverpressure", r.CorePressure > R.OverpressureLimit)
	setAlarm(state, "TransformerOverload", s.TransformerLoad > S.TransformerOverloadMW)
	setAlarm(state, "TurbineOverspeed", s.TurbineRPM > S.OverspeedRPM and not s.TurbineTripped)
	setAlarm(state, "TurbineTrip", s.TurbineTripped)
	setAlarm(state, "ReactorSCRAM", r.Scrammed)
	setAlarm(state, "MeltdownWarning", r.MeltdownRisk > 100 or r.CoreTemp > R.MeltdownTemp - 30)
end

function AlarmService.Step(state, dt)
	evaluateConditions(state)
end

function AlarmService.Acknowledge(state, alarmId)
	if state.Alarms.Active[alarmId] then
		state.Alarms.Acknowledged[alarmId] = true
	end
end

function AlarmService.IsActive(state, alarmId)
	return state.Alarms.Active[alarmId] ~= nil
end

function AlarmService.Snapshot(state)
	local out = {}
	for id, info in pairs(state.Alarms.Active) do
		out[id] = {
			Id = id,
			Severity = info.Severity,
			Display = info.Display,
			Hint = info.Hint,
			ActivatedAt = info.ActivatedAt,
			Acknowledged = state.Alarms.Acknowledged[id] and true or false,
		}
	end
	return out
end

return AlarmService
