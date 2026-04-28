local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("Services")

local Simulation = require(Services:WaitForChild("SimulationService"))
local ReactorCore = require(Services:WaitForChild("ReactorCoreService"))
local Coolant = require(Services:WaitForChild("CoolantService"))
local Feedwater = require(Services:WaitForChild("FeedwaterService"))
local Steam = require(Services:WaitForChild("SteamTurbineService"))
local Alarm = require(Services:WaitForChild("AlarmService"))
local Fault = require(Services:WaitForChild("FaultService"))
local Startup = require(Services:WaitForChild("StartupProcedureService"))
local Save = require(Services:WaitForChild("SaveService"))
local Score = require(Services:WaitForChild("ScoreService"))
local Panel = require(Services:WaitForChild("PanelService"))

local services = {
	Simulation = Simulation,
	ReactorCore = ReactorCore,
	Coolant = Coolant,
	Feedwater = Feedwater,
	Steam = Steam,
	Alarm = Alarm,
	Fault = Fault,
	Startup = Startup,
	Save = Save,
	Score = Score,
	Panel = Panel,
}

Simulation:RegisterStepper("ReactorCore", 10, ReactorCore.Step)
Simulation:RegisterStepper("Coolant", 20, Coolant.Step)
Simulation:RegisterStepper("Feedwater", 30, Feedwater.Step)
Simulation:RegisterStepper("Steam", 40, Steam.Step)
Simulation:RegisterStepper("Fault", 50, Fault.Step)
Simulation:RegisterStepper("Alarm", 60, Alarm.Step)
Simulation:RegisterStepper("Startup", 70, Startup.Step)
Simulation:RegisterStepper("Score", 80, Score.Step)

local state = Simulation:GetState()
Fault.Init(state)
Startup.Init(state)

Panel.Init(services)
Save.Bind()

Players.PlayerAdded:Connect(function(player)
	Save.Load(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	Save.Load(player)
end

Simulation:Start()
