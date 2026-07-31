-- Tipo de objeto en Studio: LocalScript
-- Va dentro de: StarterPlayer > StarterPlayerScripts
-- Construye la interfaz del club (plantilla, instalaciones, ojeadores,
-- cantera, mercado y tabla de la liga) y la conecta con el servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ClubRemotes")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClubManagerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 500, 0, 40)
topBar.Position = UDim2.new(0, 10, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.Parent = screenGui

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextScaled = true
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "Cargando club..."
nameLabel.Parent = topBar

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0.5, 0, 1, 0)
cashLabel.Position = UDim2.new(0.5, 0, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLabel.Text = "$0"
cashLabel.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0, 60)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.Parent = screenGui

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -10, 1, -40)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.ScrollBarThickness = 6
contentFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = contentFrame

local TABS = { "Plantilla", "Instalaciones", "Ojeadores y Cantera", "Mercado", "Liga" }
local FACILITY_ORDER = { "Stands", "Gym", "Shop", "Parking" }

local currentTab = TABS[1]
local latestState = nil

local tabButtons = {}
for i, tabName in ipairs(TABS) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1 / #TABS, -2, 1, 0)
	button.Position = UDim2.new((i - 1) / #TABS, 0, 0, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextScaled = true
	button.Text = tabName
	button.Parent = tabBar
	tabButtons[tabName] = button
end

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function addRow(text, buttonText, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	row.Parent = contentFrame

	local label = Instance.new("TextLabel")
	label.Size = buttonText and UDim2.new(0.7, 0, 1, 0) or UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "  " .. text
	label.Parent = row

	if buttonText then
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.3, -4, 1, -4)
		button.Position = UDim2.new(0.7, 0, 0, 2)
		button.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextScaled = true
		button.Text = buttonText
		button.Parent = row
		button.MouseButton1Click:Connect(onClick)
	end

	return row
end

local function renderSquad(state)
	addRow("Plantilla (" .. #state.Squad .. "/" .. GameConfig.SquadSize .. " jugadores)", nil, nil)
	for _, p in ipairs(state.Squad) do
		local info = string.format(
			"%s (%s, %d anos) - ATA %d / DEF %d",
			p.Name, p.Position, p.Age, p.Attack, p.Defense
		)
		addRow(info, "Vender", function()
			remotes.SellSquadPlayer:FireServer(p.Id)
		end)
	end
end

local function renderFacilities(state)
	for _, key in ipairs(FACILITY_ORDER) do
		local config = GameConfig.Facilities[key]
		local level = state.Facilities[key] or 0
		local maxed = level >= config.MaxLevel

		local info = string.format("%s - Nivel %d/%d", config.Name, level, config.MaxLevel)
		if maxed then
			addRow(info .. " (maximo)", nil, nil)
		else
			local cost = math.floor(config.BaseCost * (config.CostMultiplier ^ level))
			addRow(info, "Mejorar $" .. cost, function()
				remotes.UpgradeFacility:FireServer(key)
			end)
		end
	end
end

local function formatTimeLeft(endsAt)
	local remaining = math.max(0, endsAt - os.time())
	return math.floor(remaining / 60) .. "m " .. (remaining % 60) .. "s"
end

local function renderScouting(state)
	if state.ScoutMission then
		if os.time() >= state.ScoutMission.EndsAt then
			addRow("Tu ojeador ha vuelto con un fichaje", "Recoger", function()
				remotes.CollectScout:FireServer()
			end)
		else
			addRow("Ojeador buscando... vuelve en " .. formatTimeLeft(state.ScoutMission.EndsAt), nil, nil)
		end
	else
		addRow("Enviar ojeador ($" .. GameConfig.ScoutCost .. ")", "Enviar", function()
			remotes.StartScout:FireServer()
		end)
	end

	if state.CanteraMission then
		if os.time() >= state.CanteraMission.EndsAt then
			addRow("Un juvenil esta listo para subir", "Recoger", function()
				remotes.CollectCantera:FireServer()
			end)
		else
			addRow("Cantera trabajando... listo en " .. formatTimeLeft(state.CanteraMission.EndsAt), nil, nil)
		end
	else
		addRow("Activar cantera ($" .. GameConfig.CanteraCost .. ")", "Activar", function()
			remotes.StartCantera:FireServer()
		end)
	end
end

local function renderMarket(state)
	addRow("Mercado de fichajes", nil, nil)
	for _, p in ipairs(state.Market) do
		local info = string.format(
			"%s (%s, %d anos) - ATA %d / DEF %d - $%d",
			p.Name, p.Position, p.Age, p.Attack, p.Defense, p.Price
		)
		addRow(info, "Fichar", function()
			remotes.BuyMarketPlayer:FireServer(p.Id)
		end)
	end
end

local function renderLeague(state)
	addRow(string.format("Jornada %d / %d", state.LeagueMatchday, state.LeagueTotalMatchdays), nil, nil)
	for position, row in ipairs(state.LeagueTable) do
		local info = string.format(
			"%d. %s - %d pts (%dG %dE %dP, %d:%d)",
			position, row.ClubName, row.Points, row.Wins, row.Draws, row.Losses, row.GF, row.GA
		)
		addRow(info, nil, nil)
	end
	if #state.LeagueTable == 0 then
		addRow("Esperando a que se llene la liga (faltan jugadores)...", nil, nil)
	end
end

local RENDERERS = {
	["Plantilla"] = renderSquad,
	["Instalaciones"] = renderFacilities,
	["Ojeadores y Cantera"] = renderScouting,
	["Mercado"] = renderMarket,
	["Liga"] = renderLeague,
}

local function render()
	if not latestState then
		return
	end

	nameLabel.Text = latestState.Name
	cashLabel.Text = "$" .. latestState.Cash

	clearContent()
	RENDERERS[currentTab](latestState)
end

for tabName, button in pairs(tabButtons) do
	button.MouseButton1Click:Connect(function()
		currentTab = tabName
		render()
	end)
end

remotes.StateUpdated.OnClientEvent:Connect(function(state)
	latestState = state
	render()
end)

remotes.ActionResult.OnClientEvent:Connect(function(success, message)
	if message then
		print((success and "[OK] " or "[ERROR] ") .. message)
	end
end)

latestState = remotes.GetState:InvokeServer()
render()

-- Refresco ligero para que las cuentas atras de ojeadores/cantera se vean
-- avanzar sin esperar al proximo empujon de estado del servidor.
task.spawn(function()
	while true do
		task.wait(5)
		if latestState and currentTab == "Ojeadores y Cantera" then
			render()
		end
	end
end)
