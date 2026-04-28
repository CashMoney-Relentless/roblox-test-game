local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Client = script.Parent

local ControlPanelClient = require(Client:WaitForChild("ControlPanelClient"))

ControlPanelClient.Init()
