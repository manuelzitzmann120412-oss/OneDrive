-- Zentrale Spiel-Konfiguration. Hier kannst du alles einfach anpassen!
local Config = {}

Config.GameName = "Mega Obby Simulator"

-- DataStore
Config.DataStoreName = "MegaObbyData_v1"
Config.LeaderboardStoreName = "MegaObbyCoins_v1"
Config.AutoSaveInterval = 120

-- Startwerte für neue Spieler
Config.DefaultData = {
	Coins = 0,
	TotalCoins = 0,
	Gems = 0,
	Stage = 1,
	MaxStage = 1,
	Rebirths = 0,
	SpeedLevel = 0,
	JumpLevel = 0,
	MagnetLevel = 0,
	Pets = {}, -- Liste von Pet-Namen
	EquippedPets = {}, -- Indizes in Pets
	Trails = { "None" },
	EquippedTrail = "None",
	RedeemedCodes = {},
	LastDaily = 0,
	DailyStreak = 0,
}

-- Obby
Config.ObbyStages = 30
Config.StageReward = function(stage: number): number
	return 10 + stage * 5
end

-- Münzen in der Lobby
Config.CoinCount = 40
Config.CoinValue = 1
Config.CoinRespawnTime = 8
Config.GemChance = 0.05 -- Chance, dass statt einer Münze ein Edelstein spawnt

-- Upgrades (Level 0 = Basis)
Config.Upgrades = {
	Speed = {
		DisplayName = "Turbo-Schuhe",
		Description = "+2 Laufgeschwindigkeit pro Level",
		MaxLevel = 10,
		BaseCost = 50,
		CostGrowth = 1.6,
		Field = "SpeedLevel",
	},
	Jump = {
		DisplayName = "Sprungfedern",
		Description = "+5 Sprungkraft pro Level",
		MaxLevel = 10,
		BaseCost = 60,
		CostGrowth = 1.6,
		Field = "JumpLevel",
	},
	Magnet = {
		DisplayName = "Münzmagnet",
		Description = "+4 Studs Sammelradius pro Level",
		MaxLevel = 8,
		BaseCost = 100,
		CostGrowth = 1.8,
		Field = "MagnetLevel",
	},
}

function Config.UpgradeCost(upgradeName: string, currentLevel: number): number
	local u = Config.Upgrades[upgradeName]
	return math.floor(u.BaseCost * (u.CostGrowth ^ currentLevel))
end

Config.BaseWalkSpeed = 16
Config.SpeedPerLevel = 2
Config.SprintBonus = 8
Config.BaseJumpPower = 50
Config.JumpPerLevel = 5
Config.BaseMagnetRadius = 0
Config.MagnetPerLevel = 4

-- Pets: Multiplier wird auf alle Münz-Einnahmen gerechnet
Config.Rarities = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(85, 220, 100),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 30),
	Mythic = Color3.fromRGB(255, 60, 120),
}

Config.Pets = {
	Hund = { Rarity = "Common", Multiplier = 1.1, Color = Color3.fromRGB(170, 120, 70), Shape = "Ball" },
	Katze = { Rarity = "Common", Multiplier = 1.15, Color = Color3.fromRGB(240, 160, 60), Shape = "Ball" },
	Hase = { Rarity = "Uncommon", Multiplier = 1.3, Color = Color3.fromRGB(240, 240, 240), Shape = "Ball" },
	Fuchs = { Rarity = "Uncommon", Multiplier = 1.4, Color = Color3.fromRGB(230, 100, 30), Shape = "Block" },
	Panda = { Rarity = "Rare", Multiplier = 1.75, Color = Color3.fromRGB(30, 30, 30), Shape = "Block" },
	Pinguin = { Rarity = "Rare", Multiplier = 1.9, Color = Color3.fromRGB(40, 60, 90), Shape = "Ball" },
	Einhorn = { Rarity = "Epic", Multiplier = 2.5, Color = Color3.fromRGB(255, 150, 230), Shape = "Ball" },
	Drache = { Rarity = "Legendary", Multiplier = 4, Color = Color3.fromRGB(200, 30, 30), Shape = "Block" },
	Phoenix = { Rarity = "Legendary", Multiplier = 4.5, Color = Color3.fromRGB(255, 120, 0), Shape = "Ball" },
	Galaxie = { Rarity = "Mythic", Multiplier = 8, Color = Color3.fromRGB(90, 40, 200), Shape = "Ball" },
}

Config.Eggs = {
	Basic = {
		DisplayName = "Basis-Ei",
		Cost = 100,
		Currency = "Coins",
		Color = Color3.fromRGB(240, 230, 200),
		Chances = { Hund = 40, Katze = 35, Hase = 15, Fuchs = 9, Panda = 1 },
	},
	Rare = {
		DisplayName = "Seltenes Ei",
		Cost = 750,
		Currency = "Coins",
		Color = Color3.fromRGB(90, 160, 255),
		Chances = { Hase = 35, Fuchs = 30, Panda = 20, Pinguin = 12, Einhorn = 3 },
	},
	Legendary = {
		DisplayName = "Legendäres Ei",
		Cost = 25,
		Currency = "Gems",
		Color = Color3.fromRGB(255, 190, 40),
		Chances = { Pinguin = 30, Einhorn = 40, Drache = 18, Phoenix = 10, Galaxie = 2 },
	},
}

Config.MaxPets = 50
Config.MaxEquippedPets = 3

-- Trails (kosmetisch)
Config.Trails = {
	None = { DisplayName = "Keiner", Cost = 0, Currency = "Coins" },
	Fire = {
		DisplayName = "Feuer",
		Cost = 500,
		Currency = "Coins",
		Colors = { Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 40, 0) },
	},
	Ice = {
		DisplayName = "Eis",
		Cost = 500,
		Currency = "Coins",
		Colors = { Color3.fromRGB(200, 255, 255), Color3.fromRGB(40, 120, 255) },
	},
	Toxic = {
		DisplayName = "Gift",
		Cost = 1500,
		Currency = "Coins",
		Colors = { Color3.fromRGB(180, 255, 60), Color3.fromRGB(20, 120, 20) },
	},
	Rainbow = { DisplayName = "Regenbogen", Cost = 15, Currency = "Gems", Rainbow = true },
}

-- Rebirth
Config.RebirthBaseCost = 2500
Config.RebirthCostGrowth = 2
Config.RebirthMultiplierPerLevel = 0.5 -- +50% Münzen pro Rebirth
Config.RebirthGemReward = 5

function Config.RebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths))
end

-- Tägliche Belohnung
Config.DailyCooldown = 20 * 60 * 60 -- 20 Stunden
Config.DailyStreakReset = 48 * 60 * 60
Config.DailyRewards = {
	{ Coins = 100 },
	{ Coins = 200 },
	{ Coins = 300, Gems = 1 },
	{ Coins = 500 },
	{ Coins = 750, Gems = 2 },
	{ Coins = 1000 },
	{ Coins = 2000, Gems = 5 },
}

-- Codes (Groß-/Kleinschreibung egal)
Config.Codes = {
	WELCOME = { Coins = 250 },
	RELEASE = { Coins = 500, Gems = 3 },
	PETLOVER = { Gems = 10 },
}

-- Spiel-Pass / Gamepass IDs (0 = deaktiviert). Trage deine echten IDs ein.
Config.GamePasses = {
	DoubleCoins = 0,
	VIP = 0,
}

return Config
