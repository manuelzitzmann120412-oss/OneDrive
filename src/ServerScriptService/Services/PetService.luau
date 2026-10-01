-- Eier ausbrüten, Pets ausrüsten und als Begleiter in der Welt anzeigen.
-- Die Pets werden vom Server erzeugt und vom Client flüssig animiert.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)

local PetService = {}

local rng = Random.new()
local petFolder: Folder
local hatchCooldown: { [Player]: number } = {}

local function rollPet(eggName: string): string?
	local egg = Config.Eggs[eggName]
	local total = 0
	for _, chance in egg.Chances do
		total += chance
	end
	local roll = rng:NextNumber(0, total)
	local last
	for petName, chance in egg.Chances do
		last = petName
		roll -= chance
		if roll <= 0 then
			return petName
		end
	end
	return last
end

local function buildPetModel(player: Player, petName: string, slot: number): BasePart
	local pet = Config.Pets[petName]
	local body = Instance.new("Part")
	body.Name = player.Name .. "_" .. petName
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Size = Vector3.new(2, 2, 2)
	body.Shape = pet.Shape == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
	body.Color = pet.Color
	body.Material = Enum.Material.SmoothPlastic
	body:SetAttribute("Owner", player.UserId)
	body:SetAttribute("Slot", slot)

	-- Augen
	for _, side in { -0.45, 0.45 } do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.45, 0.45, 0.45)
		eye.Color = Color3.new(1, 1, 1)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CanCollide = false
		eye.CanQuery = false
		eye.CanTouch = false
		eye.Anchored = false
		eye.Massless = true
		eye.CFrame = body.CFrame * CFrame.new(side, 0.3, -0.85)
		local pupil = eye:Clone()
		pupil.Size = Vector3.new(0.22, 0.22, 0.22)
		pupil.Color = Color3.new(0, 0, 0)
		pupil.CFrame = body.CFrame * CFrame.new(side, 0.3, -1.05)
		for _, p in { eye, pupil } do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = p
			weld.Parent = p
			p.Parent = body
		end
	end

	local rarityColor = Config.Rarities[pet.Rarity]
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(120, 30)
	tag.StudsOffset = Vector3.new(0, 2, 0)
	tag.MaxDistance = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = rarityColor
	label.TextStrokeTransparency = 0.4
	label.Text = petName
	label.Parent = tag
	tag.Parent = body

	if pet.Rarity == "Legendary" or pet.Rarity == "Mythic" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rarityColor
		sparkles.Parent = body
	end

	CollectionService:AddTag(body, "Pet")
	return body
end

function PetService.RefreshPets(player: Player)
	local data = DataService.Get(player)
	for _, existing in petFolder:GetChildren() do
		if existing:GetAttribute("Owner") == player.UserId then
			existing:Destroy()
		end
	end
	if not data then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for slot, index in data.EquippedPets do
		local petName = data.Pets[index]
		if petName and Config.Pets[petName] then
			local model = buildPetModel(player, petName, slot)
			if root then
				model.CFrame = root.CFrame * CFrame.new(slot * 3 - 6, 1, 4)
			end
			model.Parent = petFolder
		end
	end
end

-- Sortiert ausgerüstete Indizes neu, nachdem ein Pet aus der Liste entfernt wurde
local function removePetAt(data, index: number)
	table.remove(data.Pets, index)
	local equipped = {}
	for _, i in data.EquippedPets do
		if i ~= index then
			table.insert(equipped, i > index and i - 1 or i)
		end
	end
	data.EquippedPets = equipped
end

function PetService.EquipBest(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local indices = {}
	for i, petName in data.Pets do
		if Config.Pets[petName] then
			table.insert(indices, i)
		end
	end
	table.sort(indices, function(a, b)
		return Config.Pets[data.Pets[a]].Multiplier > Config.Pets[data.Pets[b]].Multiplier
	end)
	data.EquippedPets = {}
	for i = 1, math.min(Config.MaxEquippedPets, #indices) do
		table.insert(data.EquippedPets, indices[i])
	end
	DataService.MarkChanged(player)
	PetService.RefreshPets(player)
end

function PetService.Hatch(player: Player, eggName: string)
	local egg = Config.Eggs[eggName]
	local data = DataService.Get(player)
	if not egg or not data then
		return false, "Unbekanntes Ei"
	end
	local now = os.clock()
	if hatchCooldown[player] and now - hatchCooldown[player] < 1.5 then
		return false, "Nicht so schnell!"
	end
	if #data.Pets >= Config.MaxPets then
		return false, "Dein Inventar ist voll! Lösche ein paar Pets."
	end
	if not PlayerService.TrySpend(player, egg.Currency, egg.Cost) then
		return false, "Nicht genug " .. (egg.Currency == "Gems" and "Edelsteine 💎" or "Münzen 💰")
	end
	hatchCooldown[player] = now

	local petName = rollPet(eggName)
	table.insert(data.Pets, petName)

	-- Automatisch ausrüsten, falls ein Slot frei ist
	if #data.EquippedPets < Config.MaxEquippedPets then
		table.insert(data.EquippedPets, #data.Pets)
	end

	DataService.MarkChanged(player)
	PetService.RefreshPets(player)
	Remotes.EggHatched:FireClient(player, eggName, petName)

	local rarity = Config.Pets[petName].Rarity
	if rarity == "Legendary" or rarity == "Mythic" then
		PlayerService.NotifyAll(("✨ %s hat ein %s %s ausgebrütet!"):format(player.DisplayName, rarity, petName), "rare")
	end
	return true, petName
end

function PetService.ToggleEquip(player: Player, index: number)
	local data = DataService.Get(player)
	if not data or type(index) ~= "number" or not data.Pets[index] then
		return false, "Pet nicht gefunden"
	end
	local found = table.find(data.EquippedPets, index)
	if found then
		table.remove(data.EquippedPets, found)
	else
		if #data.EquippedPets >= Config.MaxEquippedPets then
			return false, ("Maximal %d Pets ausrüstbar"):format(Config.MaxEquippedPets)
		end
		table.insert(data.EquippedPets, index)
	end
	DataService.MarkChanged(player)
	PetService.RefreshPets(player)
	return true
end

function PetService.Delete(player: Player, index: number)
	local data = DataService.Get(player)
	if not data or type(index) ~= "number" or not data.Pets[index] then
		return false, "Pet nicht gefunden"
	end
	removePetAt(data, index)
	DataService.MarkChanged(player)
	PetService.RefreshPets(player)
	return true
end

function PetService.Init(world)
	petFolder = world.PetFolder

	for _, eggPart in CollectionService:GetTagged("Egg") do
		local prompt = eggPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				local ok, result = PetService.Hatch(player, eggPart:GetAttribute("Egg"))
				if not ok then
					PlayerService.Notify(player, result, "error")
				end
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		hatchCooldown[player] = nil
		for _, existing in petFolder:GetChildren() do
			if existing:GetAttribute("Owner") == player.UserId then
				existing:Destroy()
			end
		end
	end)
end

function PetService.SetupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		PetService.RefreshPets(player)
	end)
	PetService.RefreshPets(player)
end

return PetService
