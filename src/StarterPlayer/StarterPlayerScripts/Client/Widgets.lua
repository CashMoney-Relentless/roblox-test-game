local Widgets = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent:WaitForChild("Theme"))

local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Border
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = parent
	return c
end

function Widgets.Panel(name, parent)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent
	makeCorner(frame, 6)
	makeStroke(frame, Theme.Colors.Border)
	return frame
end

function Widgets.SectionLabel(text, parent)
	local lbl = Instance.new("TextLabel")
	lbl.Name = "SectionLabel"
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.Colors.Accent
	lbl.Font = Theme.Fonts.Bold
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.upper(text)
	lbl.Size = UDim2.new(1, -8, 0, 18)
	lbl.Position = UDim2.new(0, 8, 0, 4)
	lbl.Parent = parent
	return lbl
end

function Widgets.Gauge(opts, parent)
	local frame = Instance.new("Frame")
	frame.Name = opts.Name or "Gauge"
	frame.BackgroundColor3 = Theme.Colors.PanelDark
	frame.BorderSizePixel = 0
	frame.Size = opts.Size or UDim2.new(1, 0, 0, 60)
	frame.Position = opts.Position or UDim2.new()
	frame.Parent = parent
	makeCorner(frame, 4)
	makeStroke(frame, Theme.Colors.Border)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.TextDim
	label.Font = Theme.Fonts.Label
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = opts.Label or ""
	label.Size = UDim2.new(1, -8, 0, 16)
	label.Position = UDim2.new(0, 6, 0, 2)
	label.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = Theme.Colors.Text
	valueLabel.Font = Theme.Fonts.Mono
	valueLabel.TextSize = 18
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = "0"
	valueLabel.Size = UDim2.new(1, -8, 0, 18)
	valueLabel.Position = UDim2.new(0, 4, 0, 18)
	valueLabel.Name = "Value"
	valueLabel.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.BackgroundColor3 = Theme.Colors.BarBackground
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, -10, 0, 8)
	barBg.Position = UDim2.new(0, 5, 1, -14)
	barBg.Parent = frame
	makeCorner(barBg, 2)

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.BackgroundColor3 = opts.Color or Theme.Colors.Cool
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.Parent = barBg
	makeCorner(barFill, 2)

	local api = {}
	api.Frame = frame
	api.Min = opts.Min or 0
	api.Max = opts.Max or 100
	api.Suffix = opts.Suffix or ""
	api.NormalRange = opts.NormalRange
	api.WarnRange = opts.WarnRange
	api.CritRange = opts.CritRange
	api.BaseColor = opts.Color or Theme.Colors.Cool
	api._fill = barFill
	api._value = valueLabel

	function api:Set(v)
		if v == nil or v ~= v then return end
		local pct = math.clamp((v - self.Min) / (self.Max - self.Min), 0, 1)
		TweenService:Create(self._fill, TweenInfo.new(0.15), {
			Size = UDim2.fromScale(pct, 1),
		}):Play()
		local color = self.BaseColor
		if self.CritRange and (v <= self.CritRange[1] or v >= self.CritRange[2]) then
			color = Theme.Colors.Bad
		elseif self.WarnRange and (v <= self.WarnRange[1] or v >= self.WarnRange[2]) then
			color = Theme.Colors.Warn
		elseif self.NormalRange then
			color = Theme.Colors.Good
		end
		self._fill.BackgroundColor3 = color
		local format = "%.1f%s"
		if self.Max >= 1000 then format = "%.0f%s" end
		self._value.Text = string.format(format, v, self.Suffix)
	end
	return api
end

function Widgets.Switch(opts, parent)
	local frame = Instance.new("Frame")
	frame.Name = opts.Name or "Switch"
	frame.BackgroundColor3 = Theme.Colors.PanelDark
	frame.BorderSizePixel = 0
	frame.Size = opts.Size or UDim2.new(1, 0, 0, 36)
	frame.Parent = parent
	makeCorner(frame, 4)
	makeStroke(frame, Theme.Colors.Border)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.Font = Theme.Fonts.Label
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = opts.Label or "SWITCH"
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.Parent = frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 50, 0, 22)
	button.Position = UDim2.new(1, -56, 0.5, -11)
	button.BackgroundColor3 = Theme.Colors.Switch.Frame
	button.AutoButtonColor = false
	button.Text = "OFF"
	button.Font = Theme.Fonts.Bold
	button.TextSize = 11
	button.TextColor3 = Theme.Colors.Text
	button.BorderSizePixel = 0
	button.Parent = frame
	makeCorner(button, 11)

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 18, 0, 18)
	indicator.Position = UDim2.new(0, 2, 0.5, -9)
	indicator.BackgroundColor3 = Theme.Colors.Switch.Off
	indicator.BorderSizePixel = 0
	indicator.Parent = button
	makeCorner(indicator, 9)

	local api = {}
	api.Frame = frame
	api.State = false
	api._button = button
	api._indicator = indicator

	local function render()
		button.Text = api.State and "ON " or "OFF"
		TweenService:Create(indicator, TweenInfo.new(0.12), {
			Position = api.State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
			BackgroundColor3 = api.State and Theme.Colors.Switch.On or Theme.Colors.Switch.Off,
		}):Play()
	end

	button.MouseButton1Click:Connect(function()
		api.State = not api.State
		render()
		if api.OnChange then
			api.OnChange(api.State)
		end
	end)

	function api:Set(v)
		if api.State == v then return end
		api.State = v and true or false
		render()
	end

	render()
	return api
end

function Widgets.Slider(opts, parent)
	local frame = Instance.new("Frame")
	frame.Name = opts.Name or "Slider"
	frame.BackgroundColor3 = Theme.Colors.PanelDark
	frame.BorderSizePixel = 0
	frame.Size = opts.Size or UDim2.new(1, 0, 0, 50)
	frame.Parent = parent
	makeCorner(frame, 4)
	makeStroke(frame, Theme.Colors.Border)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.Font = Theme.Fonts.Label
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = opts.Label or "VALVE"
	label.Size = UDim2.new(1, -60, 0, 18)
	label.Position = UDim2.new(0, 8, 0, 2)
	label.Parent = frame

	local valueText = Instance.new("TextLabel")
	valueText.BackgroundTransparency = 1
	valueText.TextColor3 = Theme.Colors.Accent
	valueText.Font = Theme.Fonts.Mono
	valueText.TextSize = 13
	valueText.TextXAlignment = Enum.TextXAlignment.Right
	valueText.Text = "0%"
	valueText.Size = UDim2.new(0, 60, 0, 18)
	valueText.Position = UDim2.new(1, -64, 0, 2)
	valueText.Parent = frame

	local track = Instance.new("Frame")
	track.BackgroundColor3 = Theme.Colors.BarBackground
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -16, 0, 14)
	track.Position = UDim2.new(0, 8, 1, -22)
	track.Parent = frame
	makeCorner(track, 4)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = opts.Color or Theme.Colors.Accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	makeCorner(fill, 4)

	local thumb = Instance.new("TextButton")
	thumb.Size = UDim2.new(0, 18, 0, 22)
	thumb.Position = UDim2.new(0, -9, 0.5, -11)
	thumb.BackgroundColor3 = Theme.Colors.Text
	thumb.AutoButtonColor = false
	thumb.Text = ""
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 2
	thumb.Parent = track
	makeCorner(thumb, 3)

	local api = {}
	api.Frame = frame
	api.Min = opts.Min or 0
	api.Max = opts.Max or 100
	api.Value = opts.Value or 0
	api._fill = fill
	api._thumb = thumb
	api._track = track
	api._value = valueText

	local function render()
		local pct = math.clamp((api.Value - api.Min) / (api.Max - api.Min), 0, 1)
		fill.Size = UDim2.fromScale(pct, 1)
		thumb.Position = UDim2.new(pct, -9, 0.5, -11)
		valueText.Text = string.format("%d%%", math.floor(api.Value + 0.5))
	end

	function api:Set(v, fireChange)
		v = math.clamp(v, api.Min, api.Max)
		api.Value = v
		render()
		if fireChange and api.OnChange then
			api.OnChange(api.Value)
		end
	end

	local dragging = false
	local function updateFromMouse()
		local mouse = UserInputService:GetMouseLocation()
		local rel = (mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		local newVal = api.Min + math.clamp(rel, 0, 1) * (api.Max - api.Min)
		api:Set(newVal, true)
	end

	thumb.MouseButton1Down:Connect(function()
		dragging = true
	end)
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromMouse()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromMouse()
		end
	end)

	render()
	return api
end

function Widgets.Indicator(opts, parent)
	local frame = Instance.new("Frame")
	frame.Name = opts.Name or "Indicator"
	frame.BackgroundColor3 = Theme.Colors.PanelDark
	frame.BorderSizePixel = 0
	frame.Size = opts.Size or UDim2.new(1, 0, 0, 28)
	frame.Parent = parent
	makeCorner(frame, 4)
	makeStroke(frame, Theme.Colors.Border)

	local lamp = Instance.new("Frame")
	lamp.Size = UDim2.new(0, 12, 0, 12)
	lamp.Position = UDim2.new(0, 8, 0.5, -6)
	lamp.BackgroundColor3 = Theme.Colors.Switch.Off
	lamp.BorderSizePixel = 0
	lamp.Parent = frame
	makeCorner(lamp, 6)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.Font = Theme.Fonts.Label
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = opts.Label or ""
	label.Size = UDim2.new(1, -28, 1, 0)
	label.Position = UDim2.new(0, 24, 0, 0)
	label.Parent = frame

	local api = {}
	api.Frame = frame
	api._lamp = lamp

	function api:Set(state, severity)
		if state then
			local c = Theme.Colors.Good
			if severity == "Critical" then c = Theme.Colors.Bad
			elseif severity == "Warning" then c = Theme.Colors.Warn
			elseif severity == "Advisory" then c = Theme.Colors.Severity.Advisory
			end
			lamp.BackgroundColor3 = c
		else
			lamp.BackgroundColor3 = Theme.Colors.Switch.Off
		end
	end
	return api
end

function Widgets.Button(opts, parent)
	local btn = Instance.new("TextButton")
	btn.Name = opts.Name or "Button"
	btn.Size = opts.Size or UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = opts.Color or Theme.Colors.PanelHighlight
	btn.AutoButtonColor = true
	btn.Text = opts.Text or "BUTTON"
	btn.Font = Theme.Fonts.Bold
	btn.TextSize = 13
	btn.TextColor3 = Theme.Colors.Text
	btn.BorderSizePixel = 0
	btn.Parent = parent
	makeCorner(btn, 4)
	makeStroke(btn, Theme.Colors.Border)
	return btn
end

function Widgets.AlarmTile(parent)
	local frame = Instance.new("Frame")
	frame.Name = "AlarmTile"
	frame.BackgroundColor3 = Theme.Colors.PanelDark
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 0, 48)
	frame.Parent = parent
	makeCorner(frame, 4)
	makeStroke(frame, Theme.Colors.Border)

	local lamp = Instance.new("Frame")
	lamp.Size = UDim2.new(0, 8, 1, -16)
	lamp.Position = UDim2.new(0, 6, 0, 8)
	lamp.BackgroundColor3 = Theme.Colors.Bad
	lamp.BorderSizePixel = 0
	lamp.Parent = frame
	makeCorner(lamp, 2)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Theme.Colors.Text
	title.Font = Theme.Fonts.Bold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = ""
	title.Size = UDim2.new(1, -150, 0, 18)
	title.Position = UDim2.new(0, 22, 0, 4)
	title.Name = "Title"
	title.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Theme.Colors.TextDim
	hint.Font = Theme.Fonts.Label
	hint.TextSize = 11
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = ""
	hint.Size = UDim2.new(1, -150, 0, 18)
	hint.Position = UDim2.new(0, 22, 0, 24)
	hint.Name = "Hint"
	hint.Parent = frame

	local ack = Instance.new("TextButton")
	ack.Size = UDim2.new(0, 80, 0, 28)
	ack.Position = UDim2.new(1, -88, 0.5, -14)
	ack.BackgroundColor3 = Theme.Colors.PanelHighlight
	ack.Text = "ACK"
	ack.Font = Theme.Fonts.Bold
	ack.TextSize = 12
	ack.TextColor3 = Theme.Colors.Text
	ack.BorderSizePixel = 0
	ack.AutoButtonColor = true
	ack.Name = "Ack"
	ack.Parent = frame
	makeCorner(ack, 4)
	makeStroke(ack, Theme.Colors.Border)

	return {
		Frame = frame,
		Lamp = lamp,
		Title = title,
		Hint = hint,
		Ack = ack,
	}
end

return Widgets
