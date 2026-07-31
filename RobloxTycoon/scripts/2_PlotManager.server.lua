-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Crea el marcador de Cash (leaderstats) de cada jugador y asigna la parcela
-- cuando el jugador toca el ClaimPad de una parcela libre.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local plotsFolder = Workspace:WaitForChild("Plots")

local function getPlotOwner(plotModel)
	local owner = plotModel:GetAttribute("Owner")
	if owner == "" then
		return nil
	end
	return tonumber(owner)
end

local function findPlotForPlayer(userId)
	for _, plotModel in ipairs(plotsFolder:GetChildren()) do
		if getPlotOwner(plotModel) == userId then
			return plotModel
		end
	end
	return nil
end

local function claimPlot(plotModel, player)
	plotModel:SetAttribute("Owner", tostring(player.UserId))

	local claimPad = plotModel:FindFirstChild("ClaimPad")
	if claimPad then
		claimPad.BrickColor = BrickColor.new("Really black")
		local gui = claimPad:FindFirstChildOfClass("BillboardGui")
		local label = gui and gui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = player.Name .. "'s Tycoon"
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
end)

for _, plotModel in ipairs(plotsFolder:GetChildren()) do
	local claimPad = plotModel:WaitForChild("ClaimPad")
	claimPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		if getPlotOwner(plotModel) ~= nil then
			return
		end
		if findPlotForPlayer(player.UserId) then
			return
		end
		claimPlot(plotModel, player)
	end)
end
