local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(14, 16, 22),
	Panel = Color3.fromRGB(26, 30, 38),
	PanelDark = Color3.fromRGB(18, 21, 28),
	PanelHighlight = Color3.fromRGB(40, 46, 58),
	Border = Color3.fromRGB(58, 66, 82),
	Text = Color3.fromRGB(220, 225, 232),
	TextDim = Color3.fromRGB(150, 158, 172),
	Accent = Color3.fromRGB(255, 184, 28),
	Good = Color3.fromRGB(86, 200, 120),
	Warn = Color3.fromRGB(245, 175, 60),
	Bad = Color3.fromRGB(220, 70, 70),
	Critical = Color3.fromRGB(255, 80, 80),
	Cool = Color3.fromRGB(80, 160, 220),
	Steam = Color3.fromRGB(180, 195, 215),
	BarBackground = Color3.fromRGB(10, 12, 16),
	Switch = {
		On = Color3.fromRGB(86, 200, 120),
		Off = Color3.fromRGB(80, 88, 102),
		Frame = Color3.fromRGB(34, 38, 48),
	},
	Severity = {
		Critical = Color3.fromRGB(220, 60, 60),
		Warning = Color3.fromRGB(245, 175, 60),
		Advisory = Color3.fromRGB(220, 220, 80),
	},
}

Theme.Fonts = {
	Display = Enum.Font.Code,
	Label = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
	Mono = Enum.Font.RobotoMono,
}

return Theme
