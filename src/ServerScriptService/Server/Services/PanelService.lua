local PanelService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PanelAction = Remotes:WaitForChild("PanelAction")
local SystemUpdate = Remotes:WaitForChild("SystemUpdate")
local AlarmUpdate = Remotes:WaitForChild("AlarmUpdate")
local ProcedureUpdate = Remotes:WaitForChild("ProcedureUpdate")
local RequestSnapshot = Remotes:WaitForChild("RequestSnapshot")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local _services
local _state

local function getNumber(v, default)
	if type(v) == "number" then
		return v
	end
	return default or 0
end

local Handlers = {}

function Handlers.SetMode(player, value)
	if Config.Difficulty[value] then
		_services.Simulation:SetMode(value)
	end
end

function Handlers.BatteryPower(player, value)
	_state.BatteryPower = value and true or false
end

function Handlers.SetRodTarget(player, value)
	if not _state.Reactor.Scrammed then
		_state.Reactor.TargetRodHeight = math.clamp(getNumber(value, 0), 0, 100)
	end
end

function Handlers.SetRodMode(player, value)
	if value == "Auto" or value == "Manual" then
		_state.Reactor.ControlMode = value
	end
end

function Handlers.SCRAM(player)
	_services.ReactorCore.Scram(_state, "Manual SCRAM")
	_services.Score.OnScram(_state)
end

function Handlers.ResetReactor(player)
	if _state.Reactor.Scrammed and _state.Reactor.CoreTemp < 200 and not _state.Reactor.Melted then
		_services.ReactorCore.Reset(_state)
		_services.Steam.ResetTurbine(_state)
	end
end

function Handlers.CoolantPumpA(player, enabled)
	_services.Coolant.SetPumpA(_state, enabled, _state.Coolant.PumpATargetSpeed)
end

function Handlers.CoolantPumpB(player, enabled)
	_services.Coolant.SetPumpB(_state, enabled, _state.Coolant.PumpBTargetSpeed)
end

function Handlers.CoolantPumpATarget(player, value)
	_services.Coolant.SetPumpATarget(_state, getNumber(value, 0))
end

function Handlers.CoolantPumpBTarget(player, value)
	_services.Coolant.SetPumpBTarget(_state, getNumber(value, 0))
end

function Handlers.RecircA(player, enabled)
	_state.Reactor.RecircPumpA = enabled and true or false
end

function Handlers.RecircB(player, enabled)
	_state.Reactor.RecircPumpB = enabled and true or false
end

function Handlers.FeedSwitch(player, name, value)
	_services.Feedwater.SetSwitch(_state, name, value)
end

function Handlers.FeedTarget(player, name, value)
	_services.Feedwater.SetTarget(_state, name, getNumber(value, 0))
end

function Handlers.MainSteamValve(player, value)
	_services.Steam.SetMainValve(_state, getNumber(value, 0))
end

function Handlers.BypassValve(player, value)
	_services.Steam.SetBypassValve(_state, getNumber(value, 0))
end

function Handlers.AcknowledgeAlarm(player, alarmId)
	_services.Alarm.Acknowledge(_state, alarmId)
end

function Handlers.ResetTurbine(player)
	if _state.Steam.TurbineTripped and _state.Steam.TurbineRPM < 100 then
		_services.Steam.ResetTurbine(_state)
	end
end

function PanelService.Init(services)
	_services = services
	_state = services.Simulation:GetState()

	PanelAction.OnServerEvent:Connect(function(player, actionName, a, b)
		local handler = Handlers[actionName]
		if handler then
			local ok, err = pcall(handler, player, a, b)
			if not ok then
				warn("[PanelService] Action error:", actionName, err)
			end
		end
	end)

	RequestSnapshot.OnServerInvoke = function(player)
		return PanelService.Snapshot()
	end

	task.spawn(function()
		while true do
			task.wait(Config.Tick.BroadcastStep)
			PanelService.Broadcast()
		end
	end)
end

local function copySimple(t)
	local out = {}
	for k, v in pairs(t) do
		if type(v) ~= "table" and type(v) ~= "function" then
			out[k] = v
		end
	end
	return out
end

function PanelService.Snapshot()
	if not _state then return nil end
	return {
		Mode = _state.Mode,
		BatteryPower = _state.BatteryPower,
		ElapsedTime = _state.ElapsedTime,
		Reactor = copySimple(_state.Reactor),
		Coolant = copySimple(_state.Coolant),
		Feedwater = copySimple(_state.Feedwater),
		Steam = copySimple(_state.Steam),
		Alarms = _services.Alarm.Snapshot(_state),
		Faults = _services.Fault.Snapshot(_state),
		Procedure = _services.Startup.Snapshot(_state),
		Score = _services.Score.Snapshot(_state),
	}
end

function PanelService.Broadcast()
	local snapshot = PanelService.Snapshot()
	if not snapshot then return end
	for _, player in ipairs(Players:GetPlayers()) do
		SystemUpdate:FireClient(player, snapshot)
	end
end

return PanelService
