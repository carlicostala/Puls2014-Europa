-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Guarda y carga el progreso del jugador (cash y mejoras compradas).
-- IMPORTANTE: en Studio, activa "Enable Studio Access to API Services" en
-- Home > Game Settings > Security para que el guardado funcione en pruebas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local tycoonStore = DataStoreService:GetDataStore("TycoonSaveData_v1")
local plotsFolder = Workspace:WaitForChild("Plots")

local function findPlotForPlayer(userId)
	for _, plotModel in ipairs(plotsFolder:GetChildren()) do
		if plotModel:GetAttribute("Owner") == tostring(userId) then
			return plotModel
		end
	end
	return nil
end

local function applyUpgradesToPlot(plotModel, upgradesPurchased)
	local income = GameConfig.StartingIncomePerSecond
	for index, upgrade in ipairs(GameConfig.Upgrades) do
		local button = plotModel:FindFirstChild("Button_" .. upgrade.Id)
		if index <= upgradesPurchased then
			income += upgrade.IncomeAdd
			if button then
				button.CanTouch = false
				button.Transparency = 1
			end
		elseif index == upgradesPurchased + 1 and button then
			button.BrickColor = BrickColor.new("Bright green")
			button.CanTouch = true
			button.Transparency = 0
		end
	end
	plotModel:SetAttribute("IncomePerSecond", income)
	plotModel:SetAttribute("UpgradesPurchased", upgradesPurchased)
end

local function loadPlayerData(player)
	local success, data = pcall(function()
		return tycoonStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		local leaderstats = player:WaitForChild("leaderstats")
		local cash = leaderstats:WaitForChild("Cash")
		cash.Value = data.Cash or 0

		-- El plot se asigna al tocar el ClaimPad, asi que esperamos (hasta 30s) a que exista.
		task.spawn(function()
			local plotModel = nil
			for _ = 1, 30 do
				plotModel = findPlotForPlayer(player.UserId)
				if plotModel then
					break
				end
				task.wait(1)
			end
			if plotModel then
				applyUpgradesToPlot(plotModel, data.UpgradesPurchased or 0)
			end
		end)
	end
end

local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	local plotModel = findPlotForPlayer(player.UserId)

	local data = {
		Cash = cash and cash.Value or 0,
		UpgradesPurchased = plotModel and plotModel:GetAttribute("UpgradesPurchased") or 0,
	}

	pcall(function()
		tycoonStore:SetAsync("Player_" .. player.UserId, data)
	end)
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)
