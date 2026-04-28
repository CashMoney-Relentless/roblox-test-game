local AlarmClient = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Widgets = require(script.Parent:WaitForChild("Widgets"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PanelAction = Remotes:WaitForChild("PanelAction")

local function ensureSound(id, volume, looped)
	local s = SoundService:FindFirstChild("Alarm_" .. id)
	if not s then
		s = Instance.new("Sound")
		s.Name = "Alarm_" .. id
		s.SoundId = "rbxassetid://" .. id
		s.Volume = volume or 0.4
		s.Looped = looped or false
		s.Parent = SoundService
	end
	return s
end

function AlarmClient.new(scrollFrame, banner)
	local self = {
		Frame = scrollFrame,
		Banner = banner,
		Tiles = {},
		_blink = 0,
		_lastAlarmCount = 0,
	}

	local sirenSound = ensureSound(133715403, 0.45, true)
	local chimeSound = ensureSound(8755323878, 0.3, false)

	function self:Render(alarmsTable)
		local seen = {}
		local count = 0
		for id, info in pairs(alarmsTable or {}) do
			seen[id] = true
			count += 1
			local tile = self.Tiles[id]
			if not tile then
				tile = Widgets.AlarmTile(self.Frame)
				tile.Ack.MouseButton1Click:Connect(function()
					PanelAction:FireServer("AcknowledgeAlarm", id)
				end)
				self.Tiles[id] = tile
			end
			tile.Title.Text = info.Display or id
			tile.Hint.Text = info.Hint or ""
			tile.Lamp.BackgroundColor3 = Theme.Colors.Severity[info.Severity] or Theme.Colors.Bad
			if info.Acknowledged then
				tile.Lamp.BackgroundTransparency = 0
				tile.Ack.Text = "ACKED"
				tile.Ack.AutoButtonColor = false
			else
				tile.Ack.Text = "ACK"
				tile.Ack.AutoButtonColor = true
			end
		end
		for id, tile in pairs(self.Tiles) do
			if not seen[id] then
				tile.Frame:Destroy()
				self.Tiles[id] = nil
			end
		end

		local layout = self.Frame:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.Name
			layout.Padding = UDim.new(0, 4)
			layout.Parent = self.Frame
		end

		local hasCritical = false
		for _, info in pairs(alarmsTable or {}) do
			if info.Severity == "Critical" and not info.Acknowledged then
				hasCritical = true
				break
			end
		end

		if hasCritical then
			if not sirenSound.IsPlaying then
				sirenSound:Play()
			end
		else
			if sirenSound.IsPlaying then
				sirenSound:Stop()
			end
		end

		if count > self._lastAlarmCount then
			chimeSound:Play()
		end
		self._lastAlarmCount = count

		if self.Banner then
			if hasCritical then
				self.Banner.Visible = true
				self.Banner.Text = "CRITICAL ALARM ACTIVE"
				self.Banner.BackgroundColor3 = Theme.Colors.Bad
			elseif count > 0 then
				self.Banner.Visible = true
				self.Banner.Text = string.format("%d ACTIVE ALARM%s", count, count > 1 and "S" or "")
				self.Banner.BackgroundColor3 = Theme.Colors.Warn
			else
				self.Banner.Visible = false
			end
		end
	end

	function self:Tick(dt)
		self._blink = (self._blink + dt) % 1
		local intensity = math.sin(self._blink * math.pi * 2) * 0.5 + 0.5
		for _, tile in pairs(self.Tiles) do
			tile.Lamp.BackgroundTransparency = intensity * 0.6
		end
	end

	return self
end

return AlarmClient
