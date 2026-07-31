-- Tipo de objeto en Studio: ModuleScript
-- Nombre exacto del objeto: GameConfig
-- Va dentro de: ReplicatedStorage

local GameConfig = {}

GameConfig.PlotCount = 4
GameConfig.StartingIncomePerSecond = 1

-- Cada mejora se compra en orden (primero la Id 1, luego la 2, etc).
-- IncomeAdd se suma al ingreso pasivo por segundo del jugador al comprarla.
GameConfig.Upgrades = {
	{ Id = 1, Name = "Generador de Efectivo",  Price = 25,    IncomeAdd = 2 },
	{ Id = 2, Name = "Cinta Transportadora",   Price = 100,   IncomeAdd = 5 },
	{ Id = 3, Name = "Almacen",                Price = 350,   IncomeAdd = 15 },
	{ Id = 4, Name = "Fabrica Automatizada",    Price = 1000,  IncomeAdd = 40 },
	{ Id = 5, Name = "Centro de Distribucion", Price = 3000,  IncomeAdd = 120 },
	{ Id = 6, Name = "Sede Corporativa",       Price = 10000, IncomeAdd = 400 },
}

return GameConfig
