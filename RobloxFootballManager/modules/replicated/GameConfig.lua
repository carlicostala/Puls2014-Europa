-- Tipo de objeto en Studio: ModuleScript
-- Nombre exacto del objeto: GameConfig
-- Va dentro de: ReplicatedStorage
-- Balance del juego. Cliente y servidor leen de aqui.

local GameConfig = {}

GameConfig.LeagueSize = 12
GameConfig.MatchdayIntervalSeconds = 24 * 60 * 60 -- 1 dia real = 1 jornada. Bajalo para probar mas rapido.

GameConfig.StartingCash = 500
GameConfig.SquadSize = 16

GameConfig.PassiveIncomeIntervalSeconds = 60

GameConfig.ScoutCost = 150
GameConfig.ScoutDurationSeconds = 300 -- 5 minutos reales

GameConfig.CanteraCost = 100
GameConfig.CanteraDurationSeconds = 600 -- 10 minutos reales

GameConfig.TransferMarketSize = 8
GameConfig.TransferMarketRefreshSeconds = 1800 -- 30 minutos

GameConfig.Facilities = {
	Stands = { Name = "Gradas", MaxLevel = 5, BaseCost = 300, CostMultiplier = 2.2, IncomePerLevelPerTick = 5 },
	Gym = { Name = "Gimnasio", MaxLevel = 5, BaseCost = 400, CostMultiplier = 2.2, TrainingBonusPerLevel = 1 },
	Shop = { Name = "Tienda", MaxLevel = 5, BaseCost = 250, CostMultiplier = 2.0, IncomePerLevelPerTick = 3 },
	Parking = { Name = "Parking", MaxLevel = 5, BaseCost = 200, CostMultiplier = 2.0, IncomePerLevelPerTick = 2 },
}

return GameConfig
