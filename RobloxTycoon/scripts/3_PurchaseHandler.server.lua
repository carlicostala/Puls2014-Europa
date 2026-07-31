-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Gestiona la compra de mejoras cuando el dueno de una parcela toca su boton activo.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local plotsFolder = Workspace:WaitForChild("Plots")

local debounces = {}

local function getPlotOwner(plotModel)
	local owner = plotModel:GetAttribute("Owner")
	if owner == "" then
		return nil
	end
	return tonumber(owner)
end

local function unlockNextButton(plotModel, purchasedCount)
	local nextUpgrade = GameConfig.Upgrades[purchasedCount + 1]
	if not nextUpgrade then
		return
	end
	local nextButton = plotModel:FindFirstChild("Button_" .. nextUpgrade.Id)
	if nextButton then
		nextButton.BrickColor = BrickColor.new("Bright green")
		nextButton.Transparency = 0
		nextButton.CanTouch = true
	end
end

local function handleButtonTouched(plotModel, button, upgrade, hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if getPlotOwner(plotModel) ~= player.UserId then
		return
	end

	-- Touched dispara muchas veces por el mismo toque; el debounce evita comprar varias veces.
	if debounces[button] then
		return
	end
	debounces[button] = true

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash then
		local purchasedCount = plotModel:GetAttribute("UpgradesPurchased")
		local expectedUpgrade = GameConfig.Upgrades[purchasedCount + 1]

		if expectedUpgrade and expectedUpgrade.Id == upgrade.Id and cash.Value >= upgrade.Price then
			cash.Value -= upgrade.Price
			plotModel:SetAttribute("IncomePerSecond", plotModel:GetAttribute("IncomePerSecond") + upgrade.IncomeAdd)
			plotModel:SetAttribute("UpgradesPurchased", purchasedCount + 1)

			button.CanTouch = false
			button.Transparency = 1

			unlockNextButton(plotModel, purchasedCount + 1)
		end
	end

	task.wait(0.5)
	debounces[button] = false
end

for _, plotModel in ipairs(plotsFolder:GetChildren()) do
	for _, upgrade in ipairs(GameConfig.Upgrades) do
		local button = plotModel:FindFirstChild("Button_" .. upgrade.Id)
		if button then
			button.Touched:Connect(function(hit)
				handleButtonTouched(plotModel, button, upgrade, hit)
			end)
		end
	end
end
