-- Tipo de objeto en Studio: Script
-- Va dentro de: ServerScriptService
-- Cada segundo, paga el ingreso pasivo de cada parcela reclamada a su dueno.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local plotsFolder = Workspace:WaitForChild("Plots")

while true do
	task.wait(1)
	for _, plotModel in ipairs(plotsFolder:GetChildren()) do
		local ownerAttr = plotModel:GetAttribute("Owner")
		if ownerAttr ~= "" then
			local player = Players:GetPlayerByUserId(tonumber(ownerAttr))
			if player then
				local leaderstats = player:FindFirstChild("leaderstats")
				local cash = leaderstats and leaderstats:FindFirstChild("Cash")
				if cash then
					cash.Value += plotModel:GetAttribute("IncomePerSecond")
				end
			end
		end
	end
end
