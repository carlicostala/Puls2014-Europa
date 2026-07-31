-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Se ejecuta una vez al arrancar el servidor y construye las parcelas (plots)
-- y sus botones de compra por codigo, para que no tengas que colocar piezas a mano.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PLOT_SPACING = 120
local PLOT_SIZE = Vector3.new(60, 2, 60)

if Workspace:FindFirstChild("Plots") then
	-- Ya se construyeron los plots (por ejemplo si el script se reejecuta), no dupliques.
	return
end

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = Workspace

local function createButton(plotModel, index, upgrade, basePosition)
	local button = Instance.new("Part")
	button.Name = "Button_" .. upgrade.Id
	button.Size = Vector3.new(6, 6, 6)
	button.Anchored = true
	button.CanCollide = true
	button.Position = basePosition + Vector3.new(0, 3, index * 10)
	button:SetAttribute("UpgradeId", upgrade.Id)
	button.Parent = plotModel

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = button

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = upgrade.Name .. "\n$" .. upgrade.Price
	label.Parent = billboard

	if index == 1 then
		button.BrickColor = BrickColor.new("Bright green")
		button.Transparency = 0
		button.CanTouch = true
	else
		button.BrickColor = BrickColor.new("Medium stone grey")
		button.Transparency = 0.7
		button.CanTouch = false
	end

	return button
end

for i = 1, GameConfig.PlotCount do
	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot" .. i

	local origin = Vector3.new((i - 1) * PLOT_SPACING, 0, 0)

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = PLOT_SIZE
	base.Anchored = true
	base.Position = origin
	base.BrickColor = BrickColor.new("Medium stone grey")
	base.Parent = plotModel

	local claimPad = Instance.new("Part")
	claimPad.Name = "ClaimPad"
	claimPad.Size = Vector3.new(8, 1, 8)
	claimPad.Anchored = true
	claimPad.CanCollide = false
	claimPad.BrickColor = BrickColor.new("Cyan")
	claimPad.Position = origin + Vector3.new(0, 1.5, -25)
	claimPad.Parent = plotModel

	local claimGui = Instance.new("BillboardGui")
	claimGui.Size = UDim2.new(6, 0, 2, 0)
	claimGui.StudsOffset = Vector3.new(0, 2, 0)
	claimGui.AlwaysOnTop = true
	claimGui.Parent = claimPad

	local claimLabel = Instance.new("TextLabel")
	claimLabel.Size = UDim2.new(1, 0, 1, 0)
	claimLabel.BackgroundTransparency = 1
	claimLabel.TextScaled = true
	claimLabel.Font = Enum.Font.GothamBold
	claimLabel.TextColor3 = Color3.new(1, 1, 1)
	claimLabel.Text = "Toca para reclamar"
	claimLabel.Parent = claimGui

	for index, upgrade in ipairs(GameConfig.Upgrades) do
		createButton(plotModel, index, upgrade, origin + Vector3.new(15, 0, -15))
	end

	plotModel:SetAttribute("Owner", "")
	plotModel:SetAttribute("IncomePerSecond", GameConfig.StartingIncomePerSecond)
	plotModel:SetAttribute("UpgradesPurchased", 0)
	plotModel.Parent = plotsFolder
end
