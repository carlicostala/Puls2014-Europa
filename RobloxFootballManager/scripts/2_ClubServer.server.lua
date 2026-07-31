-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Conecta los jugadores y los Remotes con ClubService, y corre el bucle
-- periodico (ingresos pasivos, jornadas de liga, mercado, autoguardado).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClubService = require(script.Parent:WaitForChild("ClubService"))

local remotes = ReplicatedStorage:WaitForChild("ClubRemotes")

local function pushState(player)
	local state = ClubService.getPublicState(player.UserId)
	if state then
		remotes.StateUpdated:FireClient(player, state)
	end
end

local function sendResult(player, success, message)
	remotes.ActionResult:FireClient(player, success, message)
end

Players.PlayerAdded:Connect(function(player)
	local club = ClubService.loadClub(player)
	ClubService.assignLeague(player, club)
	pushState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	ClubService.saveClub(player.UserId)
end)

remotes.GetState.OnServerInvoke = function(player)
	return ClubService.getPublicState(player.UserId)
end

remotes.UpgradeFacility.OnServerEvent:Connect(function(player, facilityKey)
	local success, message = ClubService.upgradeFacility(player.UserId, facilityKey)
	sendResult(player, success, message)
	pushState(player)
end)

remotes.StartScout.OnServerEvent:Connect(function(player)
	local success, message = ClubService.startScout(player.UserId)
	sendResult(player, success, message)
	pushState(player)
end)

remotes.CollectScout.OnServerEvent:Connect(function(player)
	local success, result = ClubService.collectScout(player.UserId)
	sendResult(player, success, success and ("Fichaste a " .. result.Name) or result)
	pushState(player)
end)

remotes.StartCantera.OnServerEvent:Connect(function(player)
	local success, message = ClubService.startCantera(player.UserId)
	sendResult(player, success, message)
	pushState(player)
end)

remotes.CollectCantera.OnServerEvent:Connect(function(player)
	local success, result = ClubService.collectCantera(player.UserId)
	sendResult(player, success, success and ("Subio de la cantera: " .. result.Name) or result)
	pushState(player)
end)

remotes.BuyMarketPlayer.OnServerEvent:Connect(function(player, playerId)
	local success, result = ClubService.buyMarketPlayer(player.UserId, playerId)
	sendResult(player, success, success and ("Fichaste a " .. result.Name) or result)
	pushState(player)
end)

remotes.SellSquadPlayer.OnServerEvent:Connect(function(player, playerId)
	local success, message = ClubService.sellPlayer(player.UserId, playerId)
	sendResult(player, success, message)
	pushState(player)
end)

task.spawn(function()
	while true do
		task.wait(30)

		local seenLeagues = {}
		for _, player in ipairs(Players:GetPlayers()) do
			ClubService.collectPassiveIncome(player.UserId)

			local leagueId = ClubService.getLeagueId(player.UserId)
			if leagueId and not seenLeagues[leagueId] then
				seenLeagues[leagueId] = true
				ClubService.catchUpLeague(leagueId)
			end
		end

		ClubService.refreshMarketIfNeeded()

		for _, player in ipairs(Players:GetPlayers()) do
			pushState(player)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			ClubService.saveClub(player.UserId)
		end
	end
end)
