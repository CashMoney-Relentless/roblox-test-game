local ReactorConstants = {}

ReactorConstants.Reactor = {
	MaxRodHeight = 100,
	MinRodHeight = 0,
	IdleRodHeight = 0,
	NominalCoreTemp = 285,
	MaxCoreTemp = 360,
	MeltdownTemp = 410,
	AmbientCoreTemp = 25,
	NominalCorePressure = 7.0,
	MaxCorePressure = 8.6,
	OverpressureLimit = 9.2,
	NominalCoreWater = 75,
	LowCoreWater = 35,
	HighCoreWater = 90,
	MinCoreWater = 15,
	NominalNeutronFlux = 1.0,
	MaxThermalPowerMW = 3200,
	DecayHeatFraction = 0.06,
	DecayTimeConstant = 35,
	RodReactivityGain = 0.018,
	XenonTransientGain = 0.04,
}

ReactorConstants.Coolant = {
	MaxFlow = 100,
	NominalFlow = 80,
	MinFlow = 10,
	PumpRampRate = 12,
	CavitationLevel = 25,
	DryLevel = 8,
	NominalInletTemp = 215,
	NominalOutletTemp = 290,
	MaxOutletPressure = 9.0,
}

ReactorConstants.Feedwater = {
	NominalHotwellLevel = 70,
	LowHotwellLevel = 25,
	HighHotwellLevel = 95,
	NominalDeaeratorLevel = 65,
	LowDeaeratorLevel = 25,
	HighDeaeratorLevel = 92,
	NominalDeaeratorTemp = 145,
	LowDeaeratorTemp = 95,
	MaxDeaeratorTemp = 175,
	FeedPumpRampRate = 10,
	CondPumpRampRate = 14,
	MakeupRate = 6,
}

ReactorConstants.Steam = {
	NominalSteamPressure = 6.8,
	MaxSteamPressure = 8.4,
	OverpressureSteam = 9.0,
	NominalTurbineRPM = 3000,
	SyncRPM = 2980,
	OverspeedRPM = 3300,
	TripRPM = 3450,
	MaxBypass = 100,
	NominalGeneratorMW = 1000,
	MaxGeneratorMW = 1200,
	TransformerOverloadMW = 1150,
	TurbineRampRate = 60,
	VibrationOverspeedThreshold = 60,
}

ReactorConstants.Alarms = {
	["CoreWaterLow"] = {
		Severity = "Critical",
		Display = "CORE WATER LOW",
		Hint = "Increase feedwater pump speed and verify makeup water valve is open.",
	},
	["CoreWaterHigh"] = {
		Severity = "Warning",
		Display = "CORE WATER HIGH",
		Hint = "Reduce feedwater flow; risk of carryover into the turbine.",
	},
	["CoreTempHigh"] = {
		Severity = "Critical",
		Display = "CORE TEMPERATURE HIGH",
		Hint = "Lower control rods or increase coolant flow.",
	},
	["CorePressureHigh"] = {
		Severity = "Critical",
		Display = "CORE PRESSURE HIGH",
		Hint = "Open bypass valve, lower rods, verify steam path open.",
	},
	["CoolantLoopADry"] = {
		Severity = "Critical",
		Display = "COOLANT LOOP A DRY",
		Hint = "Stop pump A, refill via makeup, verify upstream feedwater.",
	},
	["CoolantLoopBDry"] = {
		Severity = "Critical",
		Display = "COOLANT LOOP B DRY",
		Hint = "Stop pump B, refill via makeup, verify upstream feedwater.",
	},
	["FeedLoopDry"] = {
		Severity = "Critical",
		Display = "FEED LOOP DRY",
		Hint = "Stop feed pumps until deaerator level recovers.",
	},
	["RecircLoopDry"] = {
		Severity = "Warning",
		Display = "RECIRC LOOP DRY",
		Hint = "Stop recirc pumps. Restore core water level.",
	},
	["PumpCavitation"] = {
		Severity = "Warning",
		Display = "PUMP CAVITATION",
		Hint = "Reduce pump speed; raise upstream water level.",
	},
	["LowHotwellLevel"] = {
		Severity = "Warning",
		Display = "LOW HOTWELL LEVEL",
		Hint = "Open makeup water; reduce condensate demand.",
	},
	["DeaeratorALow"] = {
		Severity = "Warning",
		Display = "DEAERATOR A WATER LOW",
		Hint = "Increase condensate pump A or open makeup valve.",
	},
	["DeaeratorBLow"] = {
		Severity = "Warning",
		Display = "DEAERATOR B WATER LOW",
		Hint = "Increase condensate pump B or open makeup valve.",
	},
	["DeaeratorATempLow"] = {
		Severity = "Advisory",
		Display = "DEAERATOR A TEMP LOW",
		Hint = "Open steam inlet valve A to heat the deaerator.",
	},
	["DeaeratorBTempLow"] = {
		Severity = "Advisory",
		Display = "DEAERATOR B TEMP LOW",
		Hint = "Open steam inlet valve B to heat the deaerator.",
	},
	["CircuitOverpressure"] = {
		Severity = "Critical",
		Display = "CIRCUIT OVERPRESSURE",
		Hint = "Open relief valve; reduce reactor power.",
	},
	["HighOutletPressure"] = {
		Severity = "Warning",
		Display = "HIGH OUTLET PRESSURE",
		Hint = "Increase coolant flow; reduce rod height.",
	},
	["TransformerOverload"] = {
		Severity = "Critical",
		Display = "TRANSFORMER OVERLOAD",
		Hint = "Reduce generator MW load; shed auxiliary loads.",
	},
	["TurbineOverspeed"] = {
		Severity = "Critical",
		Display = "TURBINE OVERSPEED",
		Hint = "Close main steam valve; open bypass.",
	},
	["TurbineTrip"] = {
		Severity = "Critical",
		Display = "TURBINE TRIP",
		Hint = "Stabilize core, open bypass to dump steam, restart procedure.",
	},
	["ReactorSCRAM"] = {
		Severity = "Critical",
		Display = "REACTOR SCRAM",
		Hint = "Hold cooling. Manage decay heat. Restart procedure.",
	},
	["MeltdownWarning"] = {
		Severity = "Critical",
		Display = "MELTDOWN WARNING",
		Hint = "Initiate SCRAM. Maximize cooling. Open all relief valves.",
	},
}

ReactorConstants.RankBrackets = {
	{ XP = 0,      Title = "Trainee Operator" },
	{ XP = 1500,   Title = "Junior Operator" },
	{ XP = 5000,   Title = "Reactor Operator" },
	{ XP = 12000,  Title = "Senior Operator" },
	{ XP = 25000,  Title = "Shift Supervisor" },
	{ XP = 50000,  Title = "Plant Manager" },
	{ XP = 100000, Title = "Chief Reactor Engineer" },
}

return ReactorConstants
