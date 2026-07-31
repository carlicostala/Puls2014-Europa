-- Tipo de objeto en Studio: ModuleScript
-- Nombre exacto del objeto: ClubService
-- Va dentro de: ServerScriptService (como hermano directo de PlayerGenerator y LeagueUtil)
-- Toda la logica de negocio: cargar/guardar clubes, asignar y avanzar la
-- liga, instalaciones, ojeadores, cantera y mercado de fichajes.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerGenerator = require(script.Parent:WaitForChild("PlayerGenerator"))
local LeagueUtil = require(script.Parent:WaitForChild("LeagueUtil"))

local ClubsStore = DataStoreService:GetDataStore("Clubs_v2")
local LeaguesStore = DataStoreService:GetDataStore("Leagues_v2")
local LeagueIndexStore = DataStoreService:GetDataStore("LeagueIndex_v2")
local MarketStore = DataStoreService:GetDataStore("TransferMarket_v2")

local ClubService = {}

-- Clubes de los jugadores conectados a este servidor (en memoria).
local sessionClubs = {}

-- Cache de ligas y mercado para no golpear el DataStore en cada consulta de la UI.
local cachedLeagues = {}
local leagueLastKnownSimAt = {}
local cachedMarket = nil

local function clubKey(userId)
	return "Club_" .. userId
end

local function defaultClub(player)
	return {
		Name = player.Name .. " FC",
		Cash = GameConfig.StartingCash,
		Squad = PlayerGenerator.randomSquad(GameConfig.SquadSize, 40, 55),
		Facilities = { Stands = 0, Gym = 0, Shop = 0, Parking = 0 },
		ScoutMission = nil,
		CanteraMission = nil,
		LeagueId = nil,
		LastIncomeAt = os.time(),
	}
end

local function strengthSnapshot(club)
	local totalAttack, totalDefense, count = 0, 0, 0
	for _, p in ipairs(club.Squad) do
		totalAttack += p.Attack
		totalDefense += p.Defense
		count += 1
	end
	if count == 0 then
		return { Attack = 30, Defense = 30 }
	end
	local gymBonus = club.Facilities.Gym * GameConfig.Facilities.Gym.TrainingBonusPerLevel
	return { Attack = (totalAttack / count) + gymBonus, Defense = (totalDefense / count) + gymBonus }
end

local function syncStrengthToLeague(userId, club)
	if not club.LeagueId then
		return
	end
	local snapshot = strengthSnapshot(club)
	pcall(function()
		LeaguesStore:UpdateAsync(club.LeagueId, function(league)
			if not league or not league.Members[tostring(userId)] then
				return league
			end
			league.Members[tostring(userId)].Strength = snapshot
			league.Members[tostring(userId)].ClubName = club.Name
			return league
		end)
	end)
end

function ClubService.loadClub(player)
	local success, data = pcall(function()
		return ClubsStore:GetAsync(clubKey(player.UserId))
	end)

	local club = (success and data) or defaultClub(player)
	sessionClubs[player.UserId] = club
	return club
end

function ClubService.saveClub(userId)
	local club = sessionClubs[userId]
	if not club then
		return
	end
	local success, err = pcall(function()
		ClubsStore:SetAsync(clubKey(userId), club)
	end)
	if not success then
		warn("No se pudo guardar el club de " .. userId .. ": " .. tostring(err))
	end
end

function ClubService.getLeagueId(userId)
	local club = sessionClubs[userId]
	return club and club.LeagueId
end

-- ================= Liga =================

local function createEmptyLeague(leagueId)
	return {
		Id = leagueId,
		Members = {},
		MemberOrder = {},
		Schedule = nil,
		Table = {},
		CurrentMatchday = 0,
		LastSimulatedAt = os.time(),
		CreatedAt = os.time(),
	}
end

function ClubService.assignLeague(player, club)
	if club.LeagueId then
		return club.LeagueId
	end

	local assignedLeagueId

	local indexSuccess = pcall(function()
		LeagueIndexStore:UpdateAsync("Index", function(index)
			index = index or { OpenLeagueId = "League_1", OpenLeagueCount = 0, NextLeagueNumber = 2 }

			assignedLeagueId = index.OpenLeagueId
			index.OpenLeagueCount += 1

			if index.OpenLeagueCount >= GameConfig.LeagueSize then
				index.OpenLeagueId = "League_" .. index.NextLeagueNumber
				index.NextLeagueNumber += 1
				index.OpenLeagueCount = 0
			end

			return index
		end)
	end)

	if not indexSuccess or not assignedLeagueId then
		return nil
	end

	local leagueSuccess, updatedLeague = pcall(function()
		return LeaguesStore:UpdateAsync(assignedLeagueId, function(league)
			league = league or createEmptyLeague(assignedLeagueId)

			local userIdString = tostring(player.UserId)
			if not league.Members[userIdString] then
				league.Members[userIdString] = {
					ClubName = club.Name,
					Strength = strengthSnapshot(club),
					JoinedAt = os.time(),
				}
				table.insert(league.MemberOrder, player.UserId)
				league.Table[userIdString] = { Points = 0, Wins = 0, Draws = 0, Losses = 0, GF = 0, GA = 0 }
			end

			if not league.Schedule and #league.MemberOrder == GameConfig.LeagueSize then
				league.Schedule = LeagueUtil.generateSchedule(league.MemberOrder)
				league.LastSimulatedAt = os.time()
			end

			return league
		end)
	end)

	club.LeagueId = assignedLeagueId

	if leagueSuccess and updatedLeague then
		cachedLeagues[assignedLeagueId] = updatedLeague
		leagueLastKnownSimAt[assignedLeagueId] = updatedLeague.LastSimulatedAt
	end

	return assignedLeagueId
end

function ClubService.getLeagueSnapshot(leagueId)
	if not leagueId then
		return nil
	end
	if not cachedLeagues[leagueId] then
		local success, league = pcall(function()
			return LeaguesStore:GetAsync(leagueId)
		end)
		if success then
			cachedLeagues[leagueId] = league
		end
	end
	return cachedLeagues[leagueId]
end

-- Revisa (y si toca, resuelve) las jornadas pendientes de una liga. Se apoya
-- en la instantanea de fuerza guardada dentro de la propia liga, para no
-- tener que leer los clubes de otros jugadores durante la actualizacion.
function ClubService.catchUpLeague(leagueId)
	local lastKnown = leagueLastKnownSimAt[leagueId]
	if lastKnown and (os.time() - lastKnown) < GameConfig.MatchdayIntervalSeconds then
		return
	end

	local success, updatedLeague = pcall(function()
		return LeaguesStore:UpdateAsync(leagueId, function(league)
			if not league or not league.Schedule then
				return league
			end

			local totalMatchdays = #league.Schedule
			if league.CurrentMatchday >= totalMatchdays then
				return league
			end

			local now = os.time()
			local due = math.floor((now - league.LastSimulatedAt) / GameConfig.MatchdayIntervalSeconds)
			if due <= 0 then
				return league
			end

			for _ = 1, due do
				if league.CurrentMatchday >= totalMatchdays then
					break
				end

				league.CurrentMatchday += 1
				local matchday = league.Schedule[league.CurrentMatchday]

				for _, fixture in ipairs(matchday) do
					local homeId = tostring(fixture.Home)
					local awayId = tostring(fixture.Away)
					local homeMember = league.Members[homeId]
					local awayMember = league.Members[awayId]

					if homeMember and awayMember then
						local homeGoals, awayGoals = LeagueUtil.simulateMatch(homeMember.Strength, awayMember.Strength)

						local homeStats = league.Table[homeId]
						local awayStats = league.Table[awayId]

						homeStats.GF += homeGoals
						homeStats.GA += awayGoals
						awayStats.GF += awayGoals
						awayStats.GA += homeGoals

						if homeGoals > awayGoals then
							homeStats.Wins += 1
							homeStats.Points += 3
							awayStats.Losses += 1
						elseif awayGoals > homeGoals then
							awayStats.Wins += 1
							awayStats.Points += 3
							homeStats.Losses += 1
						else
							homeStats.Draws += 1
							awayStats.Draws += 1
							homeStats.Points += 1
							awayStats.Points += 1
						end
					end
				end

				league.LastSimulatedAt += GameConfig.MatchdayIntervalSeconds
			end

			return league
		end)
	end)

	if success and updatedLeague then
		cachedLeagues[leagueId] = updatedLeague
		leagueLastKnownSimAt[leagueId] = updatedLeague.LastSimulatedAt
	end
end

-- ================= Instalaciones =================

function ClubService.upgradeFacility(userId, facilityKey)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end

	local facilityConfig = GameConfig.Facilities[facilityKey]
	if not facilityConfig then
		return false, "Instalacion invalida"
	end

	local currentLevel = club.Facilities[facilityKey] or 0
	if currentLevel >= facilityConfig.MaxLevel then
		return false, "Nivel maximo alcanzado"
	end

	local cost = math.floor(facilityConfig.BaseCost * (facilityConfig.CostMultiplier ^ currentLevel))
	if club.Cash < cost then
		return false, "No tienes suficiente dinero"
	end

	club.Cash -= cost
	club.Facilities[facilityKey] = currentLevel + 1

	syncStrengthToLeague(userId, club) -- el gimnasio afecta la fuerza del equipo
	return true
end

function ClubService.collectPassiveIncome(userId)
	local club = sessionClubs[userId]
	if not club then
		return
	end

	local now = os.time()
	local elapsed = now - (club.LastIncomeAt or now)
	local ticks = math.floor(elapsed / GameConfig.PassiveIncomeIntervalSeconds)
	if ticks <= 0 then
		return
	end

	local incomePerTick = (club.Facilities.Stands * GameConfig.Facilities.Stands.IncomePerLevelPerTick)
		+ (club.Facilities.Shop * GameConfig.Facilities.Shop.IncomePerLevelPerTick)
		+ (club.Facilities.Parking * GameConfig.Facilities.Parking.IncomePerLevelPerTick)

	club.Cash += incomePerTick * ticks
	club.LastIncomeAt += ticks * GameConfig.PassiveIncomeIntervalSeconds
end

-- ================= Ojeadores y cantera =================

function ClubService.startScout(userId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end
	if club.ScoutMission then
		return false, "Ya tienes un ojeador buscando"
	end
	if club.Cash < GameConfig.ScoutCost then
		return false, "No tienes suficiente dinero"
	end

	club.Cash -= GameConfig.ScoutCost
	club.ScoutMission = { EndsAt = os.time() + GameConfig.ScoutDurationSeconds }
	return true
end

function ClubService.collectScout(userId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end
	local mission = club.ScoutMission
	if not mission then
		return false, "No hay ningun ojeador activo"
	end
	if os.time() < mission.EndsAt then
		return false, "El ojeador todavia no ha vuelto"
	end
	if #club.Squad >= GameConfig.SquadSize then
		return false, "Tu plantilla esta llena, vende a alguien primero"
	end

	local newPlayer = PlayerGenerator.random(50, 75)
	table.insert(club.Squad, newPlayer)
	club.ScoutMission = nil

	syncStrengthToLeague(userId, club)
	return true, newPlayer
end

function ClubService.startCantera(userId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end
	if club.CanteraMission then
		return false, "La cantera ya esta trabajando"
	end
	if club.Cash < GameConfig.CanteraCost then
		return false, "No tienes suficiente dinero"
	end

	club.Cash -= GameConfig.CanteraCost
	club.CanteraMission = { EndsAt = os.time() + GameConfig.CanteraDurationSeconds }
	return true
end

function ClubService.collectCantera(userId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end
	local mission = club.CanteraMission
	if not mission then
		return false, "No hay ningun juvenil en camino"
	end
	if os.time() < mission.EndsAt then
		return false, "El juvenil todavia no esta listo"
	end
	if #club.Squad >= GameConfig.SquadSize then
		return false, "Tu plantilla esta llena, vende a alguien primero"
	end

	local youthPlayer = PlayerGenerator.random(30, 50)
	youthPlayer.Age = math.random(16, 19)
	table.insert(club.Squad, youthPlayer)
	club.CanteraMission = nil

	syncStrengthToLeague(userId, club)
	return true, youthPlayer
end

function ClubService.sellPlayer(userId, playerId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end

	for index, player in ipairs(club.Squad) do
		if player.Id == playerId then
			if #club.Squad <= 1 then
				return false, "No puedes quedarte sin jugadores"
			end
			table.remove(club.Squad, index)
			club.Cash += math.floor(player.Price / 2)
			syncStrengthToLeague(userId, club)
			return true
		end
	end

	return false, "Jugador no encontrado"
end

-- ================= Mercado de fichajes =================

local function generateMarket()
	return {
		Players = PlayerGenerator.randomSquad(GameConfig.TransferMarketSize, 55, 85),
		RefreshedAt = os.time(),
	}
end

function ClubService.refreshMarketIfNeeded()
	if cachedMarket and (os.time() - cachedMarket.RefreshedAt) < GameConfig.TransferMarketRefreshSeconds then
		return
	end

	local success, market = pcall(function()
		return MarketStore:UpdateAsync("Global", function(current)
			if not current or (os.time() - current.RefreshedAt) >= GameConfig.TransferMarketRefreshSeconds then
				return generateMarket()
			end
			return current
		end)
	end)

	if success and market then
		cachedMarket = market
	elseif not cachedMarket then
		cachedMarket = generateMarket()
	end
end

function ClubService.buyMarketPlayer(userId, playerId)
	local club = sessionClubs[userId]
	if not club then
		return false, "Club no cargado"
	end
	if #club.Squad >= GameConfig.SquadSize then
		return false, "Tu plantilla esta llena, vende a alguien primero"
	end

	local boughtPlayer
	pcall(function()
		MarketStore:UpdateAsync("Global", function(market)
			if not market then
				return market
			end
			for index, player in ipairs(market.Players) do
				if player.Id == playerId then
					if club.Cash >= player.Price then
						boughtPlayer = player
						table.remove(market.Players, index)
					end
					break
				end
			end
			return market
		end)
	end)

	if not boughtPlayer then
		return false, "Ese jugador ya no esta disponible o no tienes suficiente dinero"
	end

	club.Cash -= boughtPlayer.Price
	table.insert(club.Squad, boughtPlayer)

	if cachedMarket then
		for index, player in ipairs(cachedMarket.Players) do
			if player.Id == boughtPlayer.Id then
				table.remove(cachedMarket.Players, index)
				break
			end
		end
	end

	syncStrengthToLeague(userId, club)
	return true, boughtPlayer
end

-- ================= Estado publico para la interfaz =================

function ClubService.getPublicState(userId)
	local club = sessionClubs[userId]
	if not club then
		return nil
	end

	if not cachedMarket then
		ClubService.refreshMarketIfNeeded()
	end

	local leagueTable = {}
	local league = ClubService.getLeagueSnapshot(club.LeagueId)
	if league then
		for memberId, stats in pairs(league.Table or {}) do
			table.insert(leagueTable, {
				ClubName = league.Members[memberId] and league.Members[memberId].ClubName or "?",
				Points = stats.Points,
				Wins = stats.Wins,
				Draws = stats.Draws,
				Losses = stats.Losses,
				GF = stats.GF,
				GA = stats.GA,
			})
		end
		table.sort(leagueTable, function(a, b)
			if a.Points ~= b.Points then
				return a.Points > b.Points
			end
			return (a.GF - a.GA) > (b.GF - b.GA)
		end)
	end

	return {
		Name = club.Name,
		Cash = club.Cash,
		Squad = club.Squad,
		Facilities = club.Facilities,
		ScoutMission = club.ScoutMission,
		CanteraMission = club.CanteraMission,
		LeagueId = club.LeagueId,
		LeagueMatchday = league and league.CurrentMatchday or 0,
		LeagueTotalMatchdays = (league and league.Schedule) and #league.Schedule or 0,
		LeagueTable = leagueTable,
		Market = cachedMarket and cachedMarket.Players or {},
	}
end

return ClubService
