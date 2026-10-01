-- Spawnt Münzen & Edelsteine in der Lobby. Einsammeln inkl. Magnet-Upgrade.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)

local CoinService = {}

local PICKUP_RADIUS = 4
local rng = Random.new()
local active: { [BasePart]: boolean } = {}
local folder: Folder
local area

local function randomPosition(): Vector3
	while true do
		local x = rng:NextNumber(area.Min.X, area.Max.X)
		local z = rng:NextNumber(area.Min.Y, area.Max.Y)
		-- Nicht auf dem Spawn, Brunnen oder bei den Eiern
		local nearSpawn = math.abs(x) < 12 and z > -35 and z < 10
		local nearEggs = z < -58 and z > -82 and math.abs(x) < 45
		if not nearSpawn and not nearEggs then
			return Vector3.new(x, 2.5, z)
		end
	end
end

local function spawnCoin()
	local isGem = rng:NextNumber() < Config.GemChance
	local coin = Instance.new("Part")
	coin.Name = isGem and "Gem" or "Coin"
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CastShadow = false
	coin.Material = Enum.Material.Neon
	if isGem then
		coin.Size = Vector3.new(1.6, 2.4, 1.6)
		coin.Color = Color3.fromRGB(80, 220, 255)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = coin
	else
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.4, 2.4, 2.4)
		coin.Color = Color3.fromRGB(255, 205, 40)
	end
	coin.CFrame = CFrame.new(randomPosition())
	coin:SetAttribute("Kind", isGem and "Gem" or "Coin")
	coin.Parent = folder
	active[coin] = true
end

local function collect(player: Player, coin: BasePart)
	if not active[coin] then
		return
	end
	active[coin] = nil
	local kind = coin:GetAttribute("Kind")
	local position = coin.Position
	coin:Destroy()

	if kind == "Gem" then
		PlayerService.GiveReward(player, { Gems = 1 })
		Remotes.CoinCollected:FireClient(player, 1, position, "Gem")
	else
		local amount = PlayerService.EarnCoins(player, Config.CoinValue)
		Remotes.CoinCollected:FireClient(player, amount, position, "Coin")
	end

	task.delay(Config.CoinRespawnTime, spawnCoin)
end

function CoinService.Init(world)
	folder = world.CoinFolder
	area = world.CoinArea

	for _ = 1, Config.CoinCount do
		spawnCoin()
	end

	-- Statt Touched: Abstands-Check, damit der Magnet funktioniert
	task.spawn(function()
		while true do
			task.wait(0.1)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if data and root then
					local radius = PICKUP_RADIUS + Config.BaseMagnetRadius + data.MagnetLevel * Config.MagnetPerLevel
					local pos = root.Position
					for coin in active do
						if (coin.Position - pos).Magnitude <= radius then
							collect(player, coin)
						end
					end
				end
			end
		end
	end)
end

return CoinService
