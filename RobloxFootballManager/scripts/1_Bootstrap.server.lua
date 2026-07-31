-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Crea la carpeta de Remotes en ReplicatedStorage para la comunicacion
-- cliente-servidor de la interfaz del club.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("ClubRemotes") then
	return
end

local remotes = Instance.new("Folder")
remotes.Name = "ClubRemotes"
remotes.Parent = ReplicatedStorage

local function newRemoteEvent(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

local function newRemoteFunction(name)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = remotes
end

newRemoteFunction("GetState")
newRemoteEvent("UpgradeFacility")
newRemoteEvent("StartScout")
newRemoteEvent("CollectScout")
newRemoteEvent("StartCantera")
newRemoteEvent("CollectCantera")
newRemoteEvent("BuyMarketPlayer")
newRemoteEvent("SellSquadPlayer")
newRemoteEvent("StateUpdated") -- servidor -> cliente, empuja el estado tras una accion
newRemoteEvent("ActionResult") -- servidor -> cliente, mensajes de exito/error
