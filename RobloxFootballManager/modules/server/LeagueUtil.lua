-- Tipo de objeto en Studio: ModuleScript
-- Nombre exacto del objeto: LeagueUtil
-- Va dentro de: ServerScriptService
-- Genera el calendario de la liga (ida y vuelta) y simula partidos a partir
-- de la fuerza de ataque/defensa de cada equipo.

local LeagueUtil = {}

-- Metodo del circulo: reparte enfrentamientos para que cada equipo juegue
-- contra todos los demas una vez de local y una de visitante.
function LeagueUtil.generateSchedule(teams)
	local n = #teams
	assert(n % 2 == 0, "LeagueUtil.generateSchedule requiere un numero par de equipos")

	local rotation = {}
	for i = 1, n do
		rotation[i] = teams[i]
	end

	local firstRoundMatchdays = {}
	for round = 1, n - 1 do
		local matchday = {}
		for i = 1, n / 2 do
			local home = rotation[i]
			local away = rotation[n - i + 1]
			if round % 2 == 0 then
				home, away = away, home
			end
			table.insert(matchday, { Home = home, Away = away })
		end
		table.insert(firstRoundMatchdays, matchday)

		local last = table.remove(rotation, n)
		table.insert(rotation, 2, last)
	end

	local schedule = {}
	for _, matchday in ipairs(firstRoundMatchdays) do
		table.insert(schedule, matchday)
	end
	for _, matchday in ipairs(firstRoundMatchdays) do
		local reversed = {}
		for _, match in ipairs(matchday) do
			table.insert(reversed, { Home = match.Away, Away = match.Home })
		end
		table.insert(schedule, reversed)
	end

	return schedule
end

-- homeStrength/awayStrength: { Attack = numero, Defense = numero }
-- Devuelve homeGoals, awayGoals.
function LeagueUtil.simulateMatch(homeStrength, awayStrength)
	local HOME_ADVANTAGE = 5

	local homeExpected = math.max(0.2, ((homeStrength.Attack + HOME_ADVANTAGE) / math.max(awayStrength.Defense, 1)) * 1.3)
	local awayExpected = math.max(0.2, (awayStrength.Attack / math.max(homeStrength.Defense + HOME_ADVANTAGE, 1)) * 1.3)

	local function goalsFromExpected(expected)
		local goals = 0
		for _ = 1, 6 do
			if math.random() < (expected / 6) then
				goals += 1
			end
		end
		return goals
	end

	return goalsFromExpected(homeExpected), goalsFromExpected(awayExpected)
end

return LeagueUtil
