local ProcedureClient = {}

local Theme = require(script.Parent:WaitForChild("Theme"))

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

function ProcedureClient.new(scrollFrame)
	local self = {
		Frame = scrollFrame,
		Rows = {},
	}

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = self.Frame

	local function ensureRow(i, data)
		local row = self.Rows[i]
		if not row then
			row = Instance.new("Frame")
			row.Name = "Step" .. i
			row.LayoutOrder = i
			row.BackgroundColor3 = Theme.Colors.PanelDark
			row.BorderSizePixel = 0
			row.Size = UDim2.new(1, -4, 0, 44)
			row.Parent = self.Frame
			makeCorner(row, 4)
			makeStroke(row)

			local check = Instance.new("Frame")
			check.Name = "Check"
			check.Size = UDim2.new(0, 14, 0, 14)
			check.Position = UDim2.new(0, 8, 0, 6)
			check.BackgroundColor3 = Theme.Colors.Switch.Off
			check.BorderSizePixel = 0
			check.Parent = row
			makeCorner(check, 3)

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.TextColor3 = Theme.Colors.Text
			title.Font = Theme.Fonts.Bold
			title.TextSize = 13
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Size = UDim2.new(1, -32, 0, 18)
			title.Position = UDim2.new(0, 28, 0, 4)
			title.Parent = row

			local hint = Instance.new("TextLabel")
			hint.Name = "Hint"
			hint.BackgroundTransparency = 1
			hint.TextColor3 = Theme.Colors.TextDim
			hint.Font = Theme.Fonts.Label
			hint.TextSize = 11
			hint.TextXAlignment = Enum.TextXAlignment.Left
			hint.Size = UDim2.new(1, -32, 0, 18)
			hint.Position = UDim2.new(0, 28, 0, 22)
			hint.Parent = row

			row._check = check
			row._title = title
			row._hint = hint
			self.Rows[i] = row
		end
		row._title.Text = data.Title or ""
		row._hint.Text = data.Hint or ""
		return row
	end

	function self:Render(snapshot, hintsEnabled)
		if not snapshot then return end
		local steps = snapshot.Steps or {}
		for i = 1, #steps do
			local row = ensureRow(i, steps[i])
			local data = steps[i]
			local completed = snapshot.CompletedSteps and snapshot.CompletedSteps[data.Id]
			local current = (snapshot.CurrentStep == i) and not snapshot.Done
			row._hint.Visible = hintsEnabled or current
			if completed then
				row._check.BackgroundColor3 = Theme.Colors.Good
				row._title.TextColor3 = Theme.Colors.TextDim
				row._title.Font = Theme.Fonts.Label
			elseif current then
				row._check.BackgroundColor3 = Theme.Colors.Accent
				row._title.TextColor3 = Theme.Colors.Text
				row._title.Font = Theme.Fonts.Bold
			else
				row._check.BackgroundColor3 = Theme.Colors.Switch.Off
				row._title.TextColor3 = Theme.Colors.Text
				row._title.Font = Theme.Fonts.Label
			end
		end
		for i = #steps + 1, #self.Rows do
			if self.Rows[i] then
				self.Rows[i]:Destroy()
				self.Rows[i] = nil
			end
		end
	end

	return self
end

return ProcedureClient
