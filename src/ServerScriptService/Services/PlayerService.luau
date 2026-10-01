-- Währung, Multiplikatoren, Leaderstats, Charakterwerte, Gamepässe.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local PlayerService = {}

local ownedPasses: { [Player]: { [string]: boolean } } = {}

local function checkPasses(player: Player)
	local owned = {}
	for name, id in Config.GamePasses do
		if id ~= 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			owned[name] = ok and has or false
		end
	end
	ownedPasses[player] = owned
end

function PlayerService.HasPass(player: Player, passName: string): boolean
	local owned = ownedPasses[player]
	return owned ~= nil and owned[passName] == true
end

function PlayerService.GetPetMultiplier(data): number
	local mult = 1
	for _, index in data.EquippedPets do
		local petName = data.Pets[index]
		local pet = petName and Config.Pets[petName]
		if pet then
			mult += pet.Multiplier - 1
		end
	end
	return mult
end

function PlayerService.GetMultiplier(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 1
	end
	local mult = 1 + data.Rebirths * Config.RebirthMultiplierPerLevel
	mult *= PlayerService.GetPetMultiplier(data)
	if PlayerService.HasPass(player, "DoubleCoins") then
		mult *= 2
	end
	if PlayerService.HasPass(player, "VIP") then
		mult *= 1.25
	end
	return mult
end

-- Gibt Münzen MIT Multiplikator. Gibt die tatsächliche Menge zurück.
function PlayerService.EarnCoins(player: Player, baseAmount: number): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	local amount = math.max(1, math.floor(baseAmount * PlayerService.GetMultiplier(player)))
	data.Coins += amount
	data.TotalCoins += amount
	DataService.MarkChanged(player)
	return amount
end

-- Gibt Belohnungen OHNE Multiplikator (Codes, Daily, ...)
function PlayerService.GiveReward(player: Player, reward: { Coins: number?, Gems: number? })
	local data = DataService.Get(player)
	if not data then
		return
	end
	if reward.Coins then
		data.Coins += reward.Coins
		data.TotalCoins += reward.Coins
	end
	if reward.Gems then
		data.Gems += reward.Gems
	end
	DataService.MarkChanged(player)
end

function PlayerService.TrySpend(player: Player, currency: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or (currency ~= "Coins" and currency ~= "Gems") then
		return false
	end
	if data[currency] < amount then
		return false
	end
	data[currency] -= amount
	DataService.MarkChanged(player)
	return true
end

function PlayerService.Notify(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

function PlayerService.NotifyAll(text: string, kind: string?)
	Remotes.Notify:FireAllClients(text, kind or "info")
end

local function applyCharacterStats(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.BaseJumpPower + data.JumpLevel * Config.JumpPerLevel
	-- Nur bei Änderung setzen, sonst würde der Sprint des Clients ständig überschrieben.
	-- Der Client liest das Attribut und rechnet den Sprint-Bonus drauf.
	local walkSpeed = Config.BaseWalkSpeed + data.SpeedLevel * Config.SpeedPerLevel
	if humanoid:GetAttribute("BaseWalkSpeed") ~= walkSpeed then
		humanoid.WalkSpeed = walkSpeed
		humanoid:SetAttribute("BaseWalkSpeed", walkSpeed)
	end
end
PlayerService.ApplyCharacterStats = applyCharacterStats

local function updateOverhead(player: Player)
	local data = DataService.Get(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not data or not head then
		return
	end
	local gui = head:FindFirstChild("Overhead")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "Overhead"
		gui.Size = UDim2.fromOffset(200, 50)
		gui.StudsOffset = Vector3.new(0, 2.5, 0)
		gui.MaxDistance = 80
		gui.AlwaysOnTop = false
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextStrokeTransparency = 0.3
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
		gui.Parent = head
	end
	local parts = {}
	if PlayerService.HasPass(player, "VIP") then
		table.insert(parts, "👑 VIP")
	end
	if data.Rebirths > 0 then
		table.insert(parts, "🔁 " .. data.Rebirths)
	end
	table.insert(parts, "🏁 " .. data.MaxStage)
	gui.Label.Text = table.concat(parts, "  ")
end

local function setupLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Münzen"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local stage = Instance.new("IntValue")
	stage.Name = "Stufe"
	stage.Value = data.MaxStage
	stage.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
end

-- Schickt dem Client die Daten, die das UI braucht
local function buildClientData(player: Player, data)
	return {
		Coins = data.Coins,
		Gems = data.Gems,
		Stage = data.Stage,
		MaxStage = data.MaxStage,
		Rebirths = data.Rebirths,
		SpeedLevel = data.SpeedLevel,
		JumpLevel = data.JumpLevel,
		MagnetLevel = data.MagnetLevel,
		Pets = data.Pets,
		EquippedPets = data.EquippedPets,
		Trails = data.Trails,
		EquippedTrail = data.EquippedTrail,
		LastDaily = data.LastDaily,
		DailyStreak = data.DailyStreak,
		Multiplier = PlayerService.GetMultiplier(player),
		ServerTime = os.time(),
	}
end

function PlayerService.SyncClient(player: Player)
	local data = DataService.Get(player)
	if data then
		Remotes.DataChanged:FireClient(player, buildClientData(player, data))
	end
end

function PlayerService.Init()
	DataService.OnChanged(function(player, data)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats["Münzen"].Value = data.Coins
			leaderstats.Stufe.Value = data.MaxStage
			leaderstats.Rebirths.Value = data.Rebirths
		end
		applyCharacterStats(player)
		updateOverhead(player)
		PlayerService.SyncClient(player)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for name, id in Config.GamePasses do
			if id == passId then
				ownedPasses[player] = ownedPasses[player] or {}
				ownedPasses[player][name] = true
				PlayerService.Notify(player, "Danke für den Kauf von " .. name .. "! 🎉", "success")
				DataService.MarkChanged(player)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player] = nil
	end)
end

-- Wird von Main aufgerufen, nachdem die Daten geladen sind
function PlayerService.SetupPlayer(player: Player, data)
	checkPasses(player)
	setupLeaderstats(player, data)

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		character:WaitForChild("Head", 10)
		applyCharacterStats(player)
		updateOverhead(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	PlayerService.SyncClient(player)
end

return PlayerService
