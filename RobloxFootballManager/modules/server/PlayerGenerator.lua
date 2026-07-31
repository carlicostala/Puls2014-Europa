-- Tipo de objeto en Studio: ModuleScript
-- Nombre exacto del objeto: PlayerGenerator
-- Va dentro de: ServerScriptService
-- Genera jugadores de futbol aleatorios (para el club inicial, ojeadores,
-- cantera y mercado de fichajes).

local HttpService = game:GetService("HttpService")

local PlayerGenerator = {}

local FIRST_NAMES = {
	"Carlos", "Diego", "Luis", "Marco", "Sergio", "Pablo", "Iker", "Alex",
	"Hugo", "Mario", "Adrian", "Bruno", "Dani", "Fran", "Ivan", "Jorge",
	"Kike", "Leo", "Nico", "Oscar",
}

local LAST_NAMES = {
	"Garcia", "Martinez", "Lopez", "Sanchez", "Perez", "Gomez", "Ruiz",
	"Torres", "Diaz", "Vega", "Ortiz", "Castro", "Romero", "Flores",
	"Reyes", "Silva", "Nunez", "Rios", "Campos", "Morales",
}

local POSITIONS = { "POR", "DEF", "MED", "DEL" }

function PlayerGenerator.random(minOverall, maxOverall)
	minOverall = minOverall or 40
	maxOverall = maxOverall or 70

	local overall = math.random(minOverall, maxOverall)
	local variance = math.random(-5, 5)

	return {
		Id = HttpService:GenerateGUID(false),
		Name = FIRST_NAMES[math.random(#FIRST_NAMES)] .. " " .. LAST_NAMES[math.random(#LAST_NAMES)],
		Position = POSITIONS[math.random(#POSITIONS)],
		Attack = math.clamp(overall + variance, 1, 99),
		Defense = math.clamp(overall - variance, 1, 99),
		Age = math.random(16, 34),
		Price = overall * 40,
	}
end

function PlayerGenerator.randomSquad(count, minOverall, maxOverall)
	local squad = {}
	for _ = 1, count do
		table.insert(squad, PlayerGenerator.random(minOverall, maxOverall))
	end
	return squad
end

return PlayerGenerator
