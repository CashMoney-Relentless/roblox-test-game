local Config = {}

Config.GameVersion = "1.0.0"
Config.FacilityName = "Oakridge Nuclear Power Station"

Config.Tick = {
	SimulationStep = 0.25,
	BroadcastStep = 0.25,
	AlarmStep = 0.5,
	FaultStep = 5.0,
}

Config.Difficulty = {
	Training = {
		Name = "Training",
		ChangeRateMultiplier = 0.5,
		FaultIntervalMin = 240,
		FaultIntervalMax = 480,
		FaultProbability = 0.0,
		HintsEnabled = true,
		AlarmExplain = true,
		ScoreMultiplier = 0.5,
	},
	Normal = {
		Name = "Normal",
		ChangeRateMultiplier = 1.0,
		FaultIntervalMin = 90,
		FaultIntervalMax = 240,
		FaultProbability = 0.35,
		HintsEnabled = false,
		AlarmExplain = false,
		ScoreMultiplier = 1.0,
	},
	Expert = {
		Name = "Expert",
		ChangeRateMultiplier = 1.6,
		FaultIntervalMin = 45,
		FaultIntervalMax = 120,
		FaultProbability = 0.65,
		HintsEnabled = false,
		AlarmExplain = false,
		ScoreMultiplier = 1.6,
	},
}

Config.Roles = {
	"ReactorOperator",
	"TurbineOperator",
	"BalanceOfPlantOperator",
	"Supervisor",
}

Config.Score = {
	BaseMWPerSecond = 0.05,
	StabilityBonusPerSecond = 0.10,
	TripPenalty = 250,
	ScramPenalty = 500,
	MeltdownPenalty = 5000,
	AlarmPenaltyPerSecond = 0.25,
	StartupBonus = 750,
	StableProductionBonus = 1500,
}

Config.Save = {
	DataStoreName = "OakridgeOperator_v1",
	AutosaveInterval = 60,
}

return Config
