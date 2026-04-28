local ControlPanelClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PanelAction = Remotes:WaitForChild("PanelAction")
local SystemUpdate = Remotes:WaitForChild("SystemUpdate")
local RequestSnapshot = Remotes:WaitForChild("RequestSnapshot")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))

local Theme = require(script.Parent:WaitForChild("Theme"))
local Widgets = require(script.Parent:WaitForChild("Widgets"))
local GaugeController = require(script.Parent:WaitForChild("GaugeController"))
local AlarmClient = require(script.Parent:WaitForChild("AlarmClient"))
local ProcedureClient = require(script.Parent:WaitForChild("ProcedureClient"))

local R = ReactorConstants.Reactor
local C = ReactorConstants.Coolant
local F = ReactorConstants.Feedwater
local S = ReactorConstants.Steam

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ControlPanelGui")

local screens = {}
local switches = {}
local sliders = {}
local indicators = {}
local extras = {}

local gauges = GaugeController.new()

local function makeStroke(parent, color)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Border
	s.Parent = parent
	return s
end

local function makeCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
	return c
end

local function getOrCreate(name, className, parent, props)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local obj = Instance.new(className)
	obj.Name = name
	if props then
		for k, v in pairs(props) do
			obj[k] = v
		end
	end
	obj.Parent = parent
	return obj
end

local function ensureBackground()
	local mainFrame = getOrCreate("MainFrame", "Frame", gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
	})
	return mainFrame
end

local function buildHeader(parent)
	local header = getOrCreate("Header", "Frame", parent, {
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(),
		BackgroundColor3 = Theme.Colors.Panel,
		BorderSizePixel = 0,
	})
	makeStroke(header, Theme.Colors.Border)

	local title = getOrCreate("Title", "TextLabel", header, {
		BackgroundTransparency = 1,
		TextColor3 = Theme.Colors.Accent,
		Font = Theme.Fonts.Bold,
		TextSize = 18,
		Text = Config.FacilityName,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 420, 0, 22),
		Position = UDim2.new(0, 16, 0, 6),
	})

	local subtitle = getOrCreate("Subtitle", "TextLabel", header, {
		BackgroundTransparency = 1,
		TextColor3 = Theme.Colors.TextDim,
		Font = Theme.Fonts.Label,
		TextSize = 12,
		Text = "Reactor Control Room - v" .. Config.GameVersion,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 420, 0, 16),
		Position = UDim2.new(0, 16, 0, 30),
	})

	local statusLabel = getOrCreate("Status", "TextLabel", header, {
		BackgroundTransparency = 1,
		TextColor3 = Theme.Colors.TextDim,
		Font = Theme.Fonts.Mono,
		TextSize = 13,
		Text = "MODE: TRAINING | T+0s | OPERATOR",
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(1, -440, 1, 0),
		Position = UDim2.new(0, 432, 0, 0),
	})

	extras.StatusLabel = statusLabel

	local banner = getOrCreate("AlarmBanner", "TextLabel", header, {
		Size = UDim2.new(0, 240, 0, 28),
		Position = UDim2.new(1, -260, 1, -34),
		BackgroundColor3 = Theme.Colors.Bad,
		BorderSizePixel = 0,
		Text = "",
		Font = Theme.Fonts.Bold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		Visible = false,
	})
	makeCorner(banner, 4)
	extras.AlarmBanner = banner
	return header
end

local function buildTabs(parent)
	local tabs = getOrCreate("Tabs", "Frame", parent, {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 56),
		BackgroundColor3 = Theme.Colors.PanelDark,
		BorderSizePixel = 0,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabs
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = tabs
	return tabs
end

local function showScreen(name)
	for k, scr in pairs(screens) do
		scr.Visible = (k == name)
	end
	for k, btn in pairs(extras.TabButtons or {}) do
		btn.BackgroundColor3 = (k == name)
			and Theme.Colors.PanelHighlight
			or Theme.Colors.Panel
	end
end

local function buildScreens(parent, tabs)
	local body = getOrCreate("Body", "Frame", parent, {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -100),
		Position = UDim2.new(0, 8, 0, 96),
	})

	local screenNames = {
		"ReactorScreen", "CoolantScreen", "FeedwaterScreen", "TurbineScreen",
		"AlarmScreen", "ProcedureScreen", "GraphScreen",
	}
	local labels = {
		ReactorScreen = "REACTOR",
		CoolantScreen = "COOLANT",
		FeedwaterScreen = "FEEDWATER",
		TurbineScreen = "TURBINE",
		AlarmScreen = "ALARMS",
		ProcedureScreen = "PROCEDURE",
		GraphScreen = "OVERVIEW",
	}

	extras.TabButtons = {}
	for i, name in ipairs(screenNames) do
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Tab"
		btn.LayoutOrder = i
		btn.Size = UDim2.new(0, 110, 1, 0)
		btn.BackgroundColor3 = Theme.Colors.Panel
		btn.AutoButtonColor = true
		btn.Text = labels[name] or name
		btn.Font = Theme.Fonts.Bold
		btn.TextSize = 12
		btn.TextColor3 = Theme.Colors.Text
		btn.BorderSizePixel = 0
		btn.Parent = tabs
		makeCorner(btn, 3)
		extras.TabButtons[name] = btn

		local screen = getOrCreate(name, "Frame", body, {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = (i == 1),
		})
		screens[name] = screen

		btn.MouseButton1Click:Connect(function()
			showScreen(name)
		end)
	end
	showScreen("ReactorScreen")
	return body
end

local function gridContainer(parent, cellWidth, cellHeight, padding)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, cellWidth, 0, cellHeight)
	layout.CellPadding = UDim2.new(0, padding or 6, 0, padding or 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 24)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = parent
	return layout
end

local function makeColumn(parent, name, position, size, sectionLabel)
	local col = Instance.new("Frame")
	col.Name = name
	col.BackgroundColor3 = Theme.Colors.Panel
	col.BorderSizePixel = 0
	col.Position = position
	col.Size = size
	col.Parent = parent
	makeCorner(col, 6)
	makeStroke(col, Theme.Colors.Border)
	if sectionLabel then
		Widgets.SectionLabel(sectionLabel, col)
	end
	return col
end

local function buildReactorScreen(screen)
	local left = makeColumn(screen, "Core", UDim2.new(0, 0, 0, 0),
		UDim2.new(0.34, -8, 1, 0), "REACTOR CORE")
	local middle = makeColumn(screen, "Rods", UDim2.new(0.34, 0, 0, 0),
		UDim2.new(0.32, -8, 1, 0), "CONTROL RODS")
	local right = makeColumn(screen, "Recirc", UDim2.new(0.66, 0, 0, 0),
		UDim2.new(0.34, 0, 1, 0), "RECIRC + EMERGENCY")

	local layoutL = gridContainer(left, 240, 60, 6)
	local _ = layoutL

	local g1 = Widgets.Gauge({
		Name = "ReactorPower",
		Label = "REACTOR POWER",
		Suffix = "%",
		Min = 0, Max = 130,
		WarnRange = {0, 110},
		CritRange = {0, 125},
		NormalRange = {20, 100},
		Color = Theme.Colors.Steam,
	}, left)
	gauges:Register("ReactorPower", g1)

	local g2 = Widgets.Gauge({
		Name = "CoreTemp",
		Label = "CORE TEMPERATURE",
		Suffix = " C",
		Min = 0, Max = 500,
		WarnRange = {200, R.MaxCoreTemp - 10},
		CritRange = {0, R.MeltdownTemp},
		Color = Theme.Colors.Bad,
	}, left)
	gauges:Register("CoreTemp", g2)

	local g3 = Widgets.Gauge({
		Name = "CorePressure",
		Label = "CORE PRESSURE",
		Suffix = " MPa",
		Min = 0, Max = 12,
		WarnRange = {2, R.MaxCorePressure - 0.5},
		CritRange = {0, R.OverpressureLimit},
		Color = Theme.Colors.Warn,
	}, left)
	gauges:Register("CorePressure", g3)

	local g4 = Widgets.Gauge({
		Name = "CoreWater",
		Label = "CORE WATER",
		Suffix = "%",
		Min = 0, Max = 100,
		NormalRange = {R.LowCoreWater, R.HighCoreWater},
		WarnRange = {R.LowCoreWater + 5, R.HighCoreWater - 5},
		CritRange = {R.MinCoreWater, R.HighCoreWater + 5},
		Color = Theme.Colors.Cool,
	}, left)
	gauges:Register("CoreWater", g4)

	local g5 = Widgets.Gauge({
		Name = "NeutronFlux",
		Label = "NEUTRON FLUX",
		Suffix = "%",
		Min = 0, Max = 130,
		Color = Theme.Colors.Accent,
	}, left)
	gauges:Register("NeutronFlux", g5)

	local g6 = Widgets.Gauge({
		Name = "DecayHeat",
		Label = "DECAY HEAT",
		Suffix = " MW",
		Min = 0, Max = 250,
		Color = Theme.Colors.Bad,
	}, left)
	gauges:Register("DecayHeat", g6)

	local rodSlider = Widgets.Slider({
		Name = "RodHeight",
		Label = "ROD HEIGHT TARGET",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
		Size = UDim2.new(1, -16, 0, 60),
	}, middle)
	rodSlider.Frame.Position = UDim2.new(0, 8, 0, 30)
	rodSlider.OnChange = function(v)
		PanelAction:FireServer("SetRodTarget", v)
	end
	sliders.RodTarget = rodSlider

	local rodGauge = Widgets.Gauge({
		Name = "RodHeightActual",
		Label = "ACTUAL ROD HEIGHT",
		Suffix = "%",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
	}, middle)
	rodGauge.Frame.Position = UDim2.new(0, 8, 0, 100)
	rodGauge.Frame.Size = UDim2.new(1, -16, 0, 60)
	gauges:Register("RodHeight", rodGauge)

	local rodModeBtn = Widgets.Button({
		Name = "RodModeButton",
		Text = "MODE: MANUAL",
	}, middle)
	rodModeBtn.Position = UDim2.new(0, 8, 0, 170)
	rodModeBtn.Size = UDim2.new(1, -16, 0, 32)
	extras.RodModeButton = rodModeBtn
	local autoMode = false
	rodModeBtn.MouseButton1Click:Connect(function()
		autoMode = not autoMode
		PanelAction:FireServer("SetRodMode", autoMode and "Auto" or "Manual")
		rodModeBtn.Text = "MODE: " .. (autoMode and "AUTO" or "MANUAL")
	end)

	local meltdown = Widgets.Gauge({
		Name = "MeltdownRisk",
		Label = "MELTDOWN RISK",
		Suffix = "",
		Min = 0, Max = 200,
		WarnRange = {0, 100},
		CritRange = {0, 200},
		Color = Theme.Colors.Bad,
	}, middle)
	meltdown.Frame.Position = UDim2.new(0, 8, 0, 210)
	meltdown.Frame.Size = UDim2.new(1, -16, 0, 60)
	gauges:Register("MeltdownRisk", meltdown)

	local recircA = Widgets.Switch({
		Name = "RecircA",
		Label = "RECIRC PUMP A",
		Size = UDim2.new(1, -16, 0, 32),
	}, right)
	recircA.Frame.Position = UDim2.new(0, 8, 0, 30)
	recircA.OnChange = function(v) PanelAction:FireServer("RecircA", v) end
	switches.RecircA = recircA

	local recircB = Widgets.Switch({
		Name = "RecircB",
		Label = "RECIRC PUMP B",
		Size = UDim2.new(1, -16, 0, 32),
	}, right)
	recircB.Frame.Position = UDim2.new(0, 8, 0, 70)
	recircB.OnChange = function(v) PanelAction:FireServer("RecircB", v) end
	switches.RecircB = recircB

	local battery = Widgets.Switch({
		Name = "BatteryPower",
		Label = "BATTERY / CONTROL POWER",
		Size = UDim2.new(1, -16, 0, 32),
	}, right)
	battery.Frame.Position = UDim2.new(0, 8, 0, 110)
	battery.OnChange = function(v) PanelAction:FireServer("BatteryPower", v) end
	switches.BatteryPower = battery

	local makeup = Widgets.Switch({
		Name = "MakeupPump",
		Label = "MAKEUP WATER PUMP",
		Size = UDim2.new(1, -16, 0, 32),
	}, right)
	makeup.Frame.Position = UDim2.new(0, 8, 0, 150)
	makeup.OnChange = function(v) PanelAction:FireServer("FeedSwitch", "MakeupPump", v) end
	switches.MakeupPump = makeup

	local cover = Instance.new("Frame")
	cover.Name = "ScramCover"
	cover.BackgroundColor3 = Color3.fromRGB(40, 8, 8)
	cover.BorderSizePixel = 0
	cover.Size = UDim2.new(1, -16, 0, 90)
	cover.Position = UDim2.new(0, 8, 1, -100)
	cover.Parent = right
	makeCorner(cover, 6)
	makeStroke(cover, Theme.Colors.Bad)

	local scramBtn = Instance.new("TextButton")
	scramBtn.Name = "ScramButton"
	scramBtn.Size = UDim2.new(1, -16, 1, -16)
	scramBtn.Position = UDim2.new(0, 8, 0, 8)
	scramBtn.BackgroundColor3 = Theme.Colors.Bad
	scramBtn.AutoButtonColor = true
	scramBtn.Text = "EMERGENCY SCRAM"
	scramBtn.Font = Theme.Fonts.Bold
	scramBtn.TextSize = 18
	scramBtn.TextColor3 = Color3.new(1, 1, 1)
	scramBtn.BorderSizePixel = 0
	scramBtn.Parent = cover
	makeCorner(scramBtn, 4)
	makeStroke(scramBtn, Color3.fromRGB(140, 20, 20))

	local clickCount = 0
	local lastClick = 0
	scramBtn.MouseButton1Click:Connect(function()
		local now = tick()
		if now - lastClick > 1.5 then clickCount = 0 end
		clickCount += 1
		lastClick = now
		if clickCount == 1 then
			scramBtn.Text = "CONFIRM SCRAM"
		elseif clickCount >= 2 then
			PanelAction:FireServer("SCRAM")
			scramBtn.Text = "EMERGENCY SCRAM"
			clickCount = 0
		end
	end)
end

local function buildCoolantScreen(screen)
	local left = makeColumn(screen, "LoopA", UDim2.new(0, 0, 0, 0),
		UDim2.new(0.5, -6, 1, 0), "COOLANT LOOP A")
	local right = makeColumn(screen, "LoopB", UDim2.new(0.5, 0, 0, 0),
		UDim2.new(0.5, 0, 1, 0), "COOLANT LOOP B")

	local function buildLoop(panel, suffix, switchAction, targetAction)
		local sw = Widgets.Switch({
			Name = "Pump" .. suffix .. "Switch",
			Label = "COOLANT PUMP " .. suffix .. " ENABLE",
			Size = UDim2.new(1, -16, 0, 32),
		}, panel)
		sw.Frame.Position = UDim2.new(0, 8, 0, 30)
		sw.OnChange = function(v) PanelAction:FireServer(switchAction, v) end
		switches["Pump" .. suffix] = sw

		local sl = Widgets.Slider({
			Name = "Pump" .. suffix .. "Slider",
			Label = "PUMP SPEED TARGET",
			Min = 0, Max = 100,
			Color = Theme.Colors.Cool,
		}, panel)
		sl.Frame.Position = UDim2.new(0, 8, 0, 70)
		sl.Frame.Size = UDim2.new(1, -16, 0, 50)
		sl.OnChange = function(v) PanelAction:FireServer(targetAction, v) end
		sliders["Pump" .. suffix .. "Target"] = sl

		local g1 = Widgets.Gauge({
			Name = "Pump" .. suffix,
			Label = "PUMP SPEED ACTUAL",
			Suffix = "%",
			Min = 0, Max = 100,
			Color = Theme.Colors.Cool,
		}, panel)
		g1.Frame.Position = UDim2.new(0, 8, 0, 130)
		g1.Frame.Size = UDim2.new(1, -16, 0, 50)
		gauges:Register("Pump" .. suffix, g1)

		local g2 = Widgets.Gauge({
			Name = "Flow" .. suffix,
			Label = "FLOW RATE",
			Suffix = "",
			Min = 0, Max = 120,
			NormalRange = {C.MinFlow, C.MaxFlow},
			Color = Theme.Colors.Cool,
		}, panel)
		g2.Frame.Position = UDim2.new(0, 8, 0, 190)
		g2.Frame.Size = UDim2.new(1, -16, 0, 50)
		gauges:Register("Flow" .. suffix, g2)

		local g3 = Widgets.Gauge({
			Name = "Loop" .. suffix .. "Level",
			Label = "LOOP WATER LEVEL",
			Suffix = "%",
			Min = 0, Max = 100,
			NormalRange = {30, 100},
			CritRange = {0, C.DryLevel + 5},
			Color = Theme.Colors.Cool,
		}, panel)
		g3.Frame.Position = UDim2.new(0, 8, 0, 250)
		g3.Frame.Size = UDim2.new(1, -16, 0, 50)
		gauges:Register("Loop" .. suffix .. "Level", g3)
	end

	buildLoop(left, "A", "CoolantPumpA", "CoolantPumpATarget")
	buildLoop(right, "B", "CoolantPumpB", "CoolantPumpBTarget")

	local g4 = Widgets.Gauge({
		Name = "InletTemp",
		Label = "COOLANT INLET TEMP",
		Suffix = " C",
		Min = 0, Max = 350,
		Color = Theme.Colors.Cool,
	}, left)
	g4.Frame.Position = UDim2.new(0, 8, 1, -120)
	g4.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("InletTemp", g4)

	local g5 = Widgets.Gauge({
		Name = "OutletTemp",
		Label = "COOLANT OUTLET TEMP",
		Suffix = " C",
		Min = 0, Max = 400,
		WarnRange = {0, 320},
		CritRange = {0, 360},
		Color = Theme.Colors.Bad,
	}, left)
	g5.Frame.Position = UDim2.new(0, 8, 1, -64)
	g5.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("OutletTemp", g5)

	local g6 = Widgets.Gauge({
		Name = "OutletPressure",
		Label = "OUTLET PRESSURE",
		Suffix = " MPa",
		Min = 0, Max = 12,
		WarnRange = {0, C.MaxOutletPressure},
		CritRange = {0, C.MaxOutletPressure + 1},
		Color = Theme.Colors.Warn,
	}, right)
	g6.Frame.Position = UDim2.new(0, 8, 1, -64)
	g6.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("OutletPressure", g6)
end

local function buildFeedwaterScreen(screen)
	local left = makeColumn(screen, "Pumps", UDim2.new(0, 0, 0, 0),
		UDim2.new(0.34, -8, 1, 0), "FEED + COND PUMPS")
	local middle = makeColumn(screen, "Hotwell", UDim2.new(0.34, 0, 0, 0),
		UDim2.new(0.32, -8, 1, 0), "HOTWELL + DEAERATORS")
	local right = makeColumn(screen, "Steam", UDim2.new(0.66, 0, 0, 0),
		UDim2.new(0.34, 0, 1, 0), "STEAM HEATING + RELIEF")

	local function pumpControl(parent, name, label, switchAction, targetAction, color, yOff)
		local sw = Widgets.Switch({
			Name = name .. "Switch",
			Label = label,
			Size = UDim2.new(1, -16, 0, 30),
		}, parent)
		sw.Frame.Position = UDim2.new(0, 8, 0, yOff)
		sw.OnChange = function(v) PanelAction:FireServer("FeedSwitch", switchAction, v) end
		switches[name] = sw

		local sl = Widgets.Slider({
			Name = name .. "Slider",
			Label = label .. " SPEED",
			Min = 0, Max = 100,
			Color = color,
		}, parent)
		sl.Frame.Position = UDim2.new(0, 8, 0, yOff + 36)
		sl.Frame.Size = UDim2.new(1, -16, 0, 46)
		sl.OnChange = function(v) PanelAction:FireServer("FeedTarget", targetAction, v) end
		sliders[name .. "Target"] = sl

		local g = Widgets.Gauge({
			Name = name .. "Gauge",
			Label = label .. " ACTUAL",
			Suffix = "%",
			Min = 0, Max = 100,
			Color = color,
		}, parent)
		g.Frame.Position = UDim2.new(0, 8, 0, yOff + 86)
		g.Frame.Size = UDim2.new(1, -16, 0, 38)
		gauges:Register(name, g)
	end

	pumpControl(left, "FeedPumpA", "FEED PUMP A", "FeedPumpA", "FeedPumpA", Theme.Colors.Cool, 30)
	pumpControl(left, "FeedPumpB", "FEED PUMP B", "FeedPumpB", "FeedPumpB", Theme.Colors.Cool, 160)
	pumpControl(left, "CondPumpA", "COND PUMP A", "CondPumpA", "CondPumpA", Theme.Colors.Steam, 290)
	pumpControl(left, "CondPumpB", "COND PUMP B", "CondPumpB", "CondPumpB", Theme.Colors.Steam, 420)

	local g1 = Widgets.Gauge({
		Name = "HotwellLevel",
		Label = "HOTWELL LEVEL",
		Suffix = "%",
		Min = 0, Max = 100,
		NormalRange = {F.LowHotwellLevel, F.HighHotwellLevel},
		CritRange = {0, F.LowHotwellLevel - 5},
		Color = Theme.Colors.Cool,
	}, middle)
	g1.Frame.Position = UDim2.new(0, 8, 0, 30)
	g1.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("HotwellLevel", g1)

	local g2 = Widgets.Gauge({
		Name = "DeaeratorALevel",
		Label = "DEAERATOR A LEVEL",
		Suffix = "%",
		Min = 0, Max = 100,
		NormalRange = {F.LowDeaeratorLevel, F.HighDeaeratorLevel},
		CritRange = {0, F.LowDeaeratorLevel - 5},
		Color = Theme.Colors.Cool,
	}, middle)
	g2.Frame.Position = UDim2.new(0, 8, 0, 90)
	g2.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("DeaeratorALevel", g2)

	local g3 = Widgets.Gauge({
		Name = "DeaeratorBLevel",
		Label = "DEAERATOR B LEVEL",
		Suffix = "%",
		Min = 0, Max = 100,
		NormalRange = {F.LowDeaeratorLevel, F.HighDeaeratorLevel},
		CritRange = {0, F.LowDeaeratorLevel - 5},
		Color = Theme.Colors.Cool,
	}, middle)
	g3.Frame.Position = UDim2.new(0, 8, 0, 150)
	g3.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("DeaeratorBLevel", g3)

	local g4 = Widgets.Gauge({
		Name = "DeaeratorATemp",
		Label = "DEAERATOR A TEMP",
		Suffix = " C",
		Min = 0, Max = 200,
		NormalRange = {F.LowDeaeratorTemp, F.MaxDeaeratorTemp},
		Color = Theme.Colors.Warn,
	}, middle)
	g4.Frame.Position = UDim2.new(0, 8, 0, 210)
	g4.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("DeaeratorATemp", g4)

	local g5 = Widgets.Gauge({
		Name = "DeaeratorBTemp",
		Label = "DEAERATOR B TEMP",
		Suffix = " C",
		Min = 0, Max = 200,
		NormalRange = {F.LowDeaeratorTemp, F.MaxDeaeratorTemp},
		Color = Theme.Colors.Warn,
	}, middle)
	g5.Frame.Position = UDim2.new(0, 8, 0, 270)
	g5.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("DeaeratorBTemp", g5)

	local sl1 = Widgets.Slider({
		Name = "SteamInletA",
		Label = "STEAM INLET VALVE A",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
	}, right)
	sl1.Frame.Position = UDim2.new(0, 8, 0, 30)
	sl1.Frame.Size = UDim2.new(1, -16, 0, 50)
	sl1.OnChange = function(v) PanelAction:FireServer("FeedTarget", "SteamInletA", v) end
	sliders.SteamInletA = sl1

	local sl2 = Widgets.Slider({
		Name = "SteamInletB",
		Label = "STEAM INLET VALVE B",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
	}, right)
	sl2.Frame.Position = UDim2.new(0, 8, 0, 90)
	sl2.Frame.Size = UDim2.new(1, -16, 0, 50)
	sl2.OnChange = function(v) PanelAction:FireServer("FeedTarget", "SteamInletB", v) end
	sliders.SteamInletB = sl2

	local sl3 = Widgets.Slider({
		Name = "ReliefValve",
		Label = "RELIEF VALVE",
		Min = 0, Max = 100,
		Color = Theme.Colors.Bad,
	}, right)
	sl3.Frame.Position = UDim2.new(0, 8, 0, 150)
	sl3.Frame.Size = UDim2.new(1, -16, 0, 50)
	sl3.OnChange = function(v) PanelAction:FireServer("FeedTarget", "ReliefValve", v) end
	sliders.ReliefValve = sl3
end

local function buildTurbineScreen(screen)
	local left = makeColumn(screen, "Steam", UDim2.new(0, 0, 0, 0),
		UDim2.new(0.34, -8, 1, 0), "STEAM SYSTEM")
	local middle = makeColumn(screen, "Turbine", UDim2.new(0.34, 0, 0, 0),
		UDim2.new(0.32, -8, 1, 0), "TURBINE")
	local right = makeColumn(screen, "Generator", UDim2.new(0.66, 0, 0, 0),
		UDim2.new(0.34, 0, 1, 0), "GENERATOR + GRID")

	local g1 = Widgets.Gauge({
		Name = "SteamPressure",
		Label = "STEAM PRESSURE",
		Suffix = " MPa",
		Min = 0, Max = 12,
		NormalRange = {4, S.MaxSteamPressure},
		CritRange = {0, S.OverpressureSteam},
		Color = Theme.Colors.Steam,
	}, left)
	g1.Frame.Position = UDim2.new(0, 8, 0, 30)
	g1.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("SteamPressure", g1)

	local sl1 = Widgets.Slider({
		Name = "MainSteamValve",
		Label = "MAIN STEAM VALVE",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
	}, left)
	sl1.Frame.Position = UDim2.new(0, 8, 0, 90)
	sl1.Frame.Size = UDim2.new(1, -16, 0, 50)
	sl1.OnChange = function(v) PanelAction:FireServer("MainSteamValve", v) end
	sliders.MainSteamValve = sl1

	local g2 = Widgets.Gauge({
		Name = "MainSteamValveActual",
		Label = "MAIN VALVE ACTUAL",
		Suffix = "%",
		Min = 0, Max = 100,
		Color = Theme.Colors.Steam,
	}, left)
	g2.Frame.Position = UDim2.new(0, 8, 0, 150)
	g2.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("MainSteamValve", g2)

	local sl2 = Widgets.Slider({
		Name = "BypassValve",
		Label = "BYPASS VALVE",
		Min = 0, Max = 100,
		Color = Theme.Colors.Cool,
	}, left)
	sl2.Frame.Position = UDim2.new(0, 8, 0, 210)
	sl2.Frame.Size = UDim2.new(1, -16, 0, 50)
	sl2.OnChange = function(v) PanelAction:FireServer("BypassValve", v) end
	sliders.BypassValve = sl2

	local g3 = Widgets.Gauge({
		Name = "BypassValveActual",
		Label = "BYPASS VALVE ACTUAL",
		Suffix = "%",
		Min = 0, Max = 100,
		Color = Theme.Colors.Cool,
	}, left)
	g3.Frame.Position = UDim2.new(0, 8, 0, 270)
	g3.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("BypassValve", g3)

	local g4 = Widgets.Gauge({
		Name = "TurbineRPM",
		Label = "TURBINE RPM",
		Suffix = "",
		Min = 0, Max = 4000,
		NormalRange = {S.SyncRPM, 3050},
		WarnRange = {0, 3200},
		CritRange = {0, S.TripRPM},
		Color = Theme.Colors.Steam,
	}, middle)
	g4.Frame.Position = UDim2.new(0, 8, 0, 30)
	g4.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("TurbineRPM", g4)

	local g5 = Widgets.Gauge({
		Name = "Vibration",
		Label = "TURBINE VIBRATION",
		Suffix = "",
		Min = 0, Max = 100,
		WarnRange = {0, 35},
		CritRange = {0, S.VibrationOverspeedThreshold},
		Color = Theme.Colors.Bad,
	}, middle)
	g5.Frame.Position = UDim2.new(0, 8, 0, 90)
	g5.Frame.Size = UDim2.new(1, -16, 0, 50)
	gauges:Register("Vibration", g5)

	local resetTurbine = Widgets.Button({
		Name = "ResetTurbine",
		Text = "RESET TURBINE",
	}, middle)
	resetTurbine.Position = UDim2.new(0, 8, 0, 160)
	resetTurbine.Size = UDim2.new(1, -16, 0, 32)
	resetTurbine.MouseButton1Click:Connect(function()
		PanelAction:FireServer("ResetTurbine")
	end)

	local resetReactor = Widgets.Button({
		Name = "ResetReactor",
		Text = "RESET REACTOR (after SCRAM)",
	}, middle)
	resetReactor.Position = UDim2.new(0, 8, 0, 200)
	resetReactor.Size = UDim2.new(1, -16, 0, 32)
	resetReactor.MouseButton1Click:Connect(function()
		PanelAction:FireServer("ResetReactor")
	end)

	local syncIndicator = Widgets.Indicator({
		Name = "SyncIndicator",
		Label = "GENERATOR SYNC",
	}, middle)
	syncIndicator.Frame.Position = UDim2.new(0, 8, 0, 240)
	syncIndicator.Frame.Size = UDim2.new(1, -16, 0, 32)
	indicators.Sync = syncIndicator

	local tripIndicator = Widgets.Indicator({
		Name = "TripIndicator",
		Label = "TURBINE TRIP",
	}, middle)
	tripIndicator.Frame.Position = UDim2.new(0, 8, 0, 280)
	tripIndicator.Frame.Size = UDim2.new(1, -16, 0, 32)
	indicators.Trip = tripIndicator

	local g6 = Widgets.Gauge({
		Name = "GeneratorMW",
		Label = "GENERATOR OUTPUT",
		Suffix = " MW",
		Min = 0, Max = 1300,
		NormalRange = {600, S.NominalGeneratorMW},
		WarnRange = {0, 1100},
		CritRange = {0, S.MaxGeneratorMW},
		Color = Theme.Colors.Good,
	}, right)
	g6.Frame.Position = UDim2.new(0, 8, 0, 30)
	g6.Frame.Size = UDim2.new(1, -16, 0, 60)
	gauges:Register("GeneratorMW", g6)

	local g7 = Widgets.Gauge({
		Name = "TransformerLoad",
		Label = "TRANSFORMER LOAD",
		Suffix = " MW",
		Min = 0, Max = 1300,
		WarnRange = {0, 1100},
		CritRange = {0, S.TransformerOverloadMW},
		Color = Theme.Colors.Warn,
	}, right)
	g7.Frame.Position = UDim2.new(0, 8, 0, 100)
	g7.Frame.Size = UDim2.new(1, -16, 0, 60)
	gauges:Register("TransformerLoad", g7)
end

local function buildAlarmScreen(screen)
	local panel = makeColumn(screen, "Alarms", UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 1, 0), "ANNUNCIATOR PANEL")

	local list = Instance.new("ScrollingFrame")
	list.Name = "AlarmList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.new(1, -16, 1, -32)
	list.Position = UDim2.new(0, 8, 0, 28)
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel

	extras.AlarmClient = AlarmClient.new(list, extras.AlarmBanner)
end

local function buildProcedureScreen(screen)
	local panel = makeColumn(screen, "Procedure", UDim2.new(0, 0, 0, 0),
		UDim2.new(0.5, -6, 1, 0), "STARTUP PROCEDURE")

	local list = Instance.new("ScrollingFrame")
	list.Name = "ProcedureList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.new(1, -16, 1, -32)
	list.Position = UDim2.new(0, 8, 0, 28)
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	extras.Procedure = ProcedureClient.new(list)

	local infoPanel = makeColumn(screen, "Mode", UDim2.new(0.5, 0, 0, 0),
		UDim2.new(0.5, 0, 1, 0), "MODE + STATUS")

	local function makeModeBtn(name, label, yOff)
		local btn = Widgets.Button({
			Name = name .. "ModeBtn",
			Text = label,
		}, infoPanel)
		btn.Position = UDim2.new(0, 8, 0, yOff)
		btn.Size = UDim2.new(1, -16, 0, 36)
		btn.MouseButton1Click:Connect(function()
			PanelAction:FireServer("SetMode", name)
		end)
		return btn
	end

	makeModeBtn("Training", "MODE: TRAINING (slow, hints on)", 30)
	makeModeBtn("Normal", "MODE: NORMAL (realistic, faults)", 76)
	makeModeBtn("Expert", "MODE: EXPERT (fast, more faults)", 122)

	local statusList = Instance.new("Frame")
	statusList.Name = "StatusList"
	statusList.BackgroundTransparency = 1
	statusList.Size = UDim2.new(1, -16, 1, -200)
	statusList.Position = UDim2.new(0, 8, 0, 180)
	statusList.Parent = infoPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = statusList

	local function statusRow(label)
		local row = Instance.new("TextLabel")
		row.BackgroundColor3 = Theme.Colors.PanelDark
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, 0, 0, 24)
		row.Font = Theme.Fonts.Mono
		row.TextSize = 12
		row.TextColor3 = Theme.Colors.Text
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = label
		row.Parent = statusList
		makeCorner(row, 3)
		return row
	end

	extras.StatusRows = {
		Score = statusRow("SCORE: 0"),
		Stable = statusRow("STABLE: 0s"),
		Production = statusRow("PRODUCTION: 0s"),
		Trips = statusRow("TRIPS: 0"),
		Scrams = statusRow("SCRAMS: 0"),
		Mode = statusRow("ACTIVE MODE: TRAINING"),
		BestMW = statusRow("CURRENT MW: 0"),
		Faults = statusRow("ACTIVE FAULTS: 0"),
	}
end

local function buildGraphScreen(screen)
	local panel = makeColumn(screen, "Overview", UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 1, 0), "POWER OUTPUT - LAST 60s")

	local canvas = Instance.new("Frame")
	canvas.Name = "GraphCanvas"
	canvas.BackgroundColor3 = Theme.Colors.PanelDark
	canvas.BorderSizePixel = 0
	canvas.Size = UDim2.new(1, -16, 0.55, 0)
	canvas.Position = UDim2.new(0, 8, 0, 32)
	canvas.Parent = panel
	makeCorner(canvas, 4)
	makeStroke(canvas)

	for i = 0, 4 do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Theme.Colors.Border
		line.BorderSizePixel = 0
		line.BackgroundTransparency = 0.5
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, i * 0.25, 0)
		line.Parent = canvas
	end

	extras.Graph = {
		Canvas = canvas,
		Bars = {},
		History = {},
		MaxPoints = 60,
	}

	local statsPanel = Instance.new("Frame")
	statsPanel.BackgroundColor3 = Theme.Colors.PanelDark
	statsPanel.BorderSizePixel = 0
	statsPanel.Size = UDim2.new(1, -16, 0.42, -8)
	statsPanel.Position = UDim2.new(0, 8, 0.55, 32)
	statsPanel.Parent = panel
	makeCorner(statsPanel, 4)
	makeStroke(statsPanel)

	local statsList = Instance.new("Frame")
	statsList.BackgroundTransparency = 1
	statsList.Size = UDim2.new(1, -16, 1, -16)
	statsList.Position = UDim2.new(0, 8, 0, 8)
	statsList.Parent = statsPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = statsList

	extras.OverviewRows = {}
	local function makeRow(name)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Theme.Colors.Text
		lbl.Font = Theme.Fonts.Mono
		lbl.TextSize = 13
		lbl.Size = UDim2.new(1, 0, 0, 18)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = name .. ": --"
		lbl.Parent = statsList
		extras.OverviewRows[name] = lbl
	end
	makeRow("REACTOR POWER")
	makeRow("THERMAL OUTPUT")
	makeRow("GENERATOR MW")
	makeRow("CORE TEMP")
	makeRow("CORE PRESSURE")
	makeRow("CORE WATER")
	makeRow("STEAM PRESSURE")
	makeRow("TURBINE RPM")
	makeRow("ACTIVE ALARMS")
	makeRow("OPERATOR SCORE")
end

local function pushGraphPoint(value)
	local g = extras.Graph
	if not g then return end
	table.insert(g.History, value)
	while #g.History > g.MaxPoints do
		table.remove(g.History, 1)
	end
	for i = #g.Bars + 1, g.MaxPoints do
		local bar = Instance.new("Frame")
		bar.Name = "Bar" .. i
		bar.BackgroundColor3 = Theme.Colors.Good
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.new((i - 1) / g.MaxPoints, 0, 1, 0)
		bar.Size = UDim2.new(1 / g.MaxPoints, -1, 0, 0)
		bar.Parent = g.Canvas
		g.Bars[i] = bar
	end
	for i = 1, g.MaxPoints do
		local v = g.History[i] or 0
		local pct = math.clamp(v / 1300, 0, 1)
		g.Bars[i].Size = UDim2.new(1 / g.MaxPoints, -1, pct, 0)
		if v > 1100 then
			g.Bars[i].BackgroundColor3 = Theme.Colors.Bad
		elseif v > 700 then
			g.Bars[i].BackgroundColor3 = Theme.Colors.Good
		elseif v > 200 then
			g.Bars[i].BackgroundColor3 = Theme.Colors.Cool
		else
			g.Bars[i].BackgroundColor3 = Theme.Colors.TextDim
		end
	end
end

local function applyClientFromState(snapshot)
	if not snapshot then return end
	gauges:UpdateFromState(snapshot)

	if extras.RodModeButton and snapshot.Reactor then
		extras.RodModeButton.Text = "MODE: " ..
			((snapshot.Reactor.ControlMode == "Auto") and "AUTO" or "MANUAL")
	end

	if switches.BatteryPower then
		switches.BatteryPower:Set(snapshot.BatteryPower)
	end
	if switches.RecircA then switches.RecircA:Set(snapshot.Reactor.RecircPumpA) end
	if switches.RecircB then switches.RecircB:Set(snapshot.Reactor.RecircPumpB) end
	if switches.MakeupPump then switches.MakeupPump:Set(snapshot.Feedwater.MakeupPump) end
	if switches.PumpA then switches.PumpA:Set(snapshot.Coolant.LoopAEnabled) end
	if switches.PumpB then switches.PumpB:Set(snapshot.Coolant.LoopBEnabled) end
	if switches.FeedPumpA then switches.FeedPumpA:Set(snapshot.Feedwater.FeedPumpA) end
	if switches.FeedPumpB then switches.FeedPumpB:Set(snapshot.Feedwater.FeedPumpB) end
	if switches.CondPumpA then switches.CondPumpA:Set(snapshot.Feedwater.CondPumpA) end
	if switches.CondPumpB then switches.CondPumpB:Set(snapshot.Feedwater.CondPumpB) end

	if indicators.Sync then
		indicators.Sync:Set(snapshot.Steam.Synced, "Advisory")
	end
	if indicators.Trip then
		indicators.Trip:Set(snapshot.Steam.TurbineTripped, "Critical")
	end

	if extras.AlarmClient then
		extras.AlarmClient:Render(snapshot.Alarms)
	end

	if extras.Procedure then
		local hintsEnabled = (snapshot.Mode == "Training")
		extras.Procedure:Render(snapshot.Procedure, hintsEnabled)
	end

	if extras.StatusLabel and snapshot.Score then
		extras.StatusLabel.Text = string.format(
			"MODE: %s | T+%ds | SCORE %d | MW %d",
			string.upper(snapshot.Mode),
			math.floor(snapshot.ElapsedTime or 0),
			snapshot.Score.Value or 0,
			math.floor(snapshot.Steam.GeneratorMW)
		)
	end

	if extras.StatusRows and snapshot.Score then
		extras.StatusRows.Score.Text = "SCORE: " .. tostring(snapshot.Score.Value or 0)
		extras.StatusRows.Stable.Text = "STABLE: " .. tostring(snapshot.Score.StableSeconds or 0) .. "s"
		extras.StatusRows.Production.Text = "PRODUCTION: " .. tostring(snapshot.Score.ProductionSeconds or 0) .. "s"
		extras.StatusRows.Trips.Text = "TRIPS: " .. tostring(snapshot.Score.TripCount or 0)
		extras.StatusRows.Scrams.Text = "SCRAMS: " .. tostring(snapshot.Score.ScramCount or 0)
		extras.StatusRows.Mode.Text = "ACTIVE MODE: " .. string.upper(snapshot.Mode)
		extras.StatusRows.BestMW.Text = string.format("CURRENT MW: %d", math.floor(snapshot.Steam.GeneratorMW))
		local fc = 0
		for _, _ in pairs(snapshot.Faults or {}) do fc += 1 end
		extras.StatusRows.Faults.Text = "ACTIVE FAULTS: " .. tostring(fc)
	end

	if extras.OverviewRows then
		local rows = extras.OverviewRows
		rows["REACTOR POWER"].Text = string.format("REACTOR POWER: %.1f%%", snapshot.Reactor.ReactorPowerPct)
		rows["THERMAL OUTPUT"].Text = string.format("THERMAL OUTPUT: %.0f MW", snapshot.Reactor.ThermalPowerMW)
		rows["GENERATOR MW"].Text = string.format("GENERATOR MW: %.0f", snapshot.Steam.GeneratorMW)
		rows["CORE TEMP"].Text = string.format("CORE TEMP: %.1f C", snapshot.Reactor.CoreTemp)
		rows["CORE PRESSURE"].Text = string.format("CORE PRESSURE: %.2f MPa", snapshot.Reactor.CorePressure)
		rows["CORE WATER"].Text = string.format("CORE WATER: %.1f%%", snapshot.Reactor.CoreWater)
		rows["STEAM PRESSURE"].Text = string.format("STEAM PRESSURE: %.2f MPa", snapshot.Steam.SteamPressure)
		rows["TURBINE RPM"].Text = string.format("TURBINE RPM: %.0f", snapshot.Steam.TurbineRPM)
		local cnt = 0
		for _, _ in pairs(snapshot.Alarms or {}) do cnt += 1 end
		rows["ACTIVE ALARMS"].Text = "ACTIVE ALARMS: " .. tostring(cnt)
		rows["OPERATOR SCORE"].Text = "OPERATOR SCORE: " .. tostring(snapshot.Score.Value or 0)
	end
end

local cameraShake = {
	Enabled = false,
	Power = 0,
}

local function tickCameraShake(dt)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if cameraShake.Power > 0 then
		local k = cameraShake.Power
		local cf = cam.CFrame
		cam.CFrame = cf * CFrame.new(
			(math.random() - 0.5) * k * 0.05,
			(math.random() - 0.5) * k * 0.05,
			0)
		cameraShake.Power = math.max(0, cameraShake.Power - dt * 1.4)
	end
end

local hum
local function ensureAmbient()
	if hum then return end
	hum = Instance.new("Sound")
	hum.Name = "ControlRoomHum"
	hum.SoundId = "rbxassetid://9114094993"
	hum.Volume = 0.18
	hum.Looped = true
	hum.Parent = SoundService
	pcall(function() hum:Play() end)
end

local lastSnapshot
function ControlPanelClient.Init()
	local main = ensureBackground()
	buildHeader(main)
	local tabs = buildTabs(main)
	buildScreens(main, tabs)

	buildReactorScreen(screens.ReactorScreen)
	buildCoolantScreen(screens.CoolantScreen)
	buildFeedwaterScreen(screens.FeedwaterScreen)
	buildTurbineScreen(screens.TurbineScreen)
	buildAlarmScreen(screens.AlarmScreen)
	buildProcedureScreen(screens.ProcedureScreen)
	buildGraphScreen(screens.GraphScreen)

	ensureAmbient()

	SystemUpdate.OnClientEvent:Connect(function(snapshot)
		lastSnapshot = snapshot
		applyClientFromState(snapshot)

		if snapshot.Reactor and snapshot.Reactor.Scrammed and not extras._lastScramSeen then
			extras._lastScramSeen = true
			cameraShake.Power = 5
		elseif snapshot.Reactor and not snapshot.Reactor.Scrammed then
			extras._lastScramSeen = false
		end
		if snapshot.Reactor and snapshot.Reactor.MeltdownRisk > 100 then
			cameraShake.Power = math.max(cameraShake.Power, snapshot.Reactor.MeltdownRisk * 0.02)
		end
		if snapshot.Steam and snapshot.Steam.TurbineTripped and not extras._lastTripSeen then
			extras._lastTripSeen = true
			cameraShake.Power = 4
		elseif snapshot.Steam and not snapshot.Steam.TurbineTripped then
			extras._lastTripSeen = false
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			if lastSnapshot and lastSnapshot.Steam then
				pushGraphPoint(lastSnapshot.Steam.GeneratorMW)
			end
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if extras.AlarmClient then
			extras.AlarmClient:Tick(dt)
		end
		tickCameraShake(dt)
	end)

	local ok, snap = pcall(function()
		return RequestSnapshot:InvokeServer()
	end)
	if ok and snap then
		lastSnapshot = snap
		applyClientFromState(snap)
	end
end

return ControlPanelClient
