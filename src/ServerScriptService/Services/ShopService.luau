-- Alle Anfragen vom Client: Upgrades, Trails, Rebirth, Daily, Codes, Teleports, Pets.
-- Alles wird hier auf dem Server geprüft – der Client kann nicht schummeln.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)
local PetService = require(script.Parent.PetService)
local ObbyService = require(script.Parent.ObbyService)

local ShopService = {}

local lastRequest: { [Player]: number } = {}

---------------------------------------------------------------------
-- Trails
---------------------------------------------------------------------
local function applyTrail(player: Player)
	local data = DataService.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = root:FindFirstChild("CoolTrail")
	if old then
		old:Destroy()
	end
	for _, name in { "TrailA0", "TrailA1" } do
		local a = root:FindFirstChild(name)
		if a then
			a:Destroy()
		end
	end

	local trailConfig = Config.Trails[data.EquippedTrail]
	if not trailConfig or data.EquippedTrail == "None" then
		return
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0.8, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, -0.8, 0)
	a1.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "CoolTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.6
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new(0, 1)
	if trailConfig.Rainbow then
		local keypoints = {}
		for i = 0, 6 do
			table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
		end
		trail.Color = ColorSequence.new(keypoints)
	else
		trail.Color = ColorSequence.new(trailConfig.Colors[1], trailConfig.Colors[2])
	end
	trail.Parent = root
end

---------------------------------------------------------------------
-- Aktionen
---------------------------------------------------------------------
local Actions = {}

function Actions.BuyUpgrade(player, data, upgradeName)
	local upgrade = Config.Upgrades[upgradeName]
	if not upgrade then
		return false, "Unbekanntes Upgrade"
	end
	local level = data[upgrade.Field]
	if level >= upgrade.MaxLevel then
		return false, "Schon auf Max-Level!"
	end
	local cost = Config.UpgradeCost(upgradeName, level)
	if not PlayerService.TrySpend(player, "Coins", cost) then
		return false, "Nicht genug Münzen 💰"
	end
	data[upgrade.Field] = level + 1
	DataService.MarkChanged(player)
	return true, ("%s Level %d!"):format(upgrade.DisplayName, level + 1)
end

function Actions.BuyTrail(player, data, trailName)
	local trail = Config.Trails[trailName]
	if not trail then
		return false, "Unbekannter Trail"
	end
	if not table.find(data.Trails, trailName) then
		if not PlayerService.TrySpend(player, trail.Currency, trail.Cost) then
			return false, "Nicht genug " .. (trail.Currency == "Gems" and "Edelsteine 💎" or "Münzen 💰")
		end
		table.insert(data.Trails, trailName)
	end
	data.EquippedTrail = trailName
	DataService.MarkChanged(player)
	applyTrail(player)
	return true, trail.DisplayName .. " ausgerüstet!"
end

function Actions.Rebirth(player, data)
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Coins < cost then
		return false, ("Du brauchst %d Münzen für einen Rebirth"):format(cost)
	end
	data.Coins = 0
	data.SpeedLevel = 0
	data.JumpLevel = 0
	data.MagnetLevel = 0
	data.Rebirths += 1
	data.Gems += Config.RebirthGemReward
	DataService.MarkChanged(player)
	PlayerService.NotifyAll(("🔁 %s hat Rebirth %d erreicht!"):format(player.DisplayName, data.Rebirths), "rare")
	return true,
		("Rebirth! Jetzt x%.1f Münzen  +%d 💎"):format(PlayerService.GetMultiplier(player), Config.RebirthGemReward)
end

function Actions.ClaimDaily(player, data)
	local now = os.time()
	local since = now - data.LastDaily
	if since < Config.DailyCooldown then
		local left = Config.DailyCooldown - since
		return false, ("Noch %dh %dmin warten"):format(left // 3600, (left % 3600) // 60)
	end
	if since > Config.DailyStreakReset then
		data.DailyStreak = 0
	end
	data.DailyStreak += 1
	data.LastDaily = now
	local day = (data.DailyStreak - 1) % #Config.DailyRewards + 1
	local reward = Config.DailyRewards[day]
	PlayerService.GiveReward(player, reward)
	local text = ("Tag %d: +%d 💰"):format(day, reward.Coins or 0)
	if reward.Gems then
		text ..= (" +%d 💎"):format(reward.Gems)
	end
	return true, text
end

function Actions.RedeemCode(player, data, code)
	if type(code) ~= "string" or #code > 30 then
		return false, "Ungültiger Code"
	end
	code = string.upper((string.gsub(code, "%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		return false, "Ungültiger Code"
	end
	if table.find(data.RedeemedCodes, code) then
		return false, "Code schon eingelöst"
	end
	table.insert(data.RedeemedCodes, code)
	PlayerService.GiveReward(player, reward)
	local parts = {}
	if reward.Coins then
		table.insert(parts, "+" .. reward.Coins .. " 💰")
	end
	if reward.Gems then
		table.insert(parts, "+" .. reward.Gems .. " 💎")
	end
	return true, "Code eingelöst! " .. table.concat(parts, " ")
end

function Actions.TeleportCheckpoint(player, data)
	ObbyService.TeleportToStage(player, data.Stage)
	return true
end

function Actions.TeleportLobby(player)
	ObbyService.TeleportToLobby(player)
	return true
end

function Actions.HatchEgg(player, _data, eggName)
	return PetService.Hatch(player, eggName)
end

function Actions.ToggleEquipPet(player, _data, index)
	return PetService.ToggleEquip(player, index)
end

function Actions.DeletePet(player, _data, index)
	return PetService.Delete(player, index)
end

function Actions.EquipBestPets(player)
	PetService.EquipBest(player)
	return true, "Beste Pets ausgerüstet!"
end

function Actions.BuyGamePass(player, _data, passName)
	local id = Config.GamePasses[passName]
	if not id or id == 0 then
		return false, "Dieser Gamepass ist noch nicht eingerichtet"
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
	return true
end

function ShopService.Init()
	Remotes.Request.OnServerInvoke = function(player, action, arg)
		-- Einfacher Spam-Schutz
		local now = os.clock()
		if lastRequest[player] and now - lastRequest[player] < 0.15 then
			return false, "Langsam!"
		end
		lastRequest[player] = now

		local handler = type(action) == "string" and Actions[action]
		local data = DataService.Get(player)
		if not handler or not data then
			return false, "Ungültige Anfrage"
		end
		local ok, success, message = pcall(handler, player, data, arg)
		if not ok then
			warn("[ShopService]", action, success)
			return false, "Fehler – bitte nochmal versuchen"
		end
		return success, message
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

function ShopService.SetupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		applyTrail(player)
	end)
	if player.Character then
		task.spawn(applyTrail, player)
	end
end

return ShopService
