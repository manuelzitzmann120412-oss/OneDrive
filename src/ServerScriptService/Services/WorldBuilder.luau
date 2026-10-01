-- Baut die komplette Welt per Code: Lobby, Obby, Ei-Stände, Bestenliste, Licht.
-- Dadurch brauchst du keine .rbxl-Datei – einfach per Rojo syncen und spielen.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local SECTION_LENGTH = 44
local PAD_SIZE = 12
local RISE = 3
local OBBY_START_Z = 124

local COLORS = {
	Grass = Color3.fromRGB(110, 200, 90),
	Path = Color3.fromRGB(230, 220, 190),
	Lava = Color3.fromRGB(255, 70, 20),
	Wood = Color3.fromRGB(150, 100, 60),
	Leaves = Color3.fromRGB(60, 170, 70),
}

local STAGE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 230, 70),
	Color3.fromRGB(110, 220, 110),
	Color3.fromRGB(70, 200, 230),
	Color3.fromRGB(100, 130, 255),
	Color3.fromRGB(190, 110, 255),
	Color3.fromRGB(255, 120, 200),
}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function kill(p: BasePart)
	p.Color = COLORS.Lava
	p.Material = Enum.Material.Neon
	CollectionService:AddTag(p, "Kill")
	return p
end

local function sign(parent: Instance, cframe: CFrame, text: string, size: Vector2?)
	local s = size or Vector2.new(16, 6)
	local board = part({
		Name = "Sign",
		Size = Vector3.new(s.X, s.Y, 0.6),
		CFrame = cframe,
		Color = Color3.fromRGB(40, 40, 55),
		Parent = parent,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Text = text
	label.Parent = gui
	return board, label
end

local function tree(parent: Instance, position: Vector3, rng: Random)
	local h = rng:NextNumber(8, 14)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = COLORS.Wood,
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	local r = rng:NextNumber(7, 11)
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(r, r, r),
		Position = position + Vector3.new(0, h + r / 3, 0),
		Color = COLORS.Leaves,
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

---------------------------------------------------------------------
-- Lobby
---------------------------------------------------------------------
local function buildLobby(world: Folder)
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = world

	part({
		Name = "Ground",
		Size = Vector3.new(240, 4, 240),
		Position = Vector3.new(0, -2, 0),
		Color = COLORS.Grass,
		Material = Enum.Material.Grass,
		Parent = lobby,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(80, 160, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby

	-- Weg zum Obby
	part({
		Name = "PathToObby",
		Size = Vector3.new(12, 1, OBBY_START_Z - PAD_SIZE / 2 - 7),
		Position = Vector3.new(0, 0.5, (OBBY_START_Z - PAD_SIZE / 2 + 7) / 2),
		Color = COLORS.Path,
		Material = Enum.Material.Slate,
		Parent = lobby,
	})
	-- SurfaceGui zeigt nach -Z (LookVector), also Richtung Spawn drehen
	sign(lobby, CFrame.new(0, 10, 30), "🏁 ZUM OBBY", Vector2.new(18, 6))
	sign(lobby, CFrame.new(0, 10, -45) * CFrame.Angles(0, math.rad(180), 0), "🥚 EIER  &  PETS", Vector2.new(18, 6))
	sign(
		lobby,
		CFrame.new(-60, 10, 0) * CFrame.Angles(0, math.rad(-90), 0),
		"💰 Sammle Münzen!\nRebirth = mehr Münzen",
		Vector2.new(20, 8)
	)

	local rng = Random.new(42)
	for _ = 1, 26 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(85, 112)
		local pos = Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		-- Weg zum Obby frei lassen
		if not (math.abs(pos.X) < 14 and pos.Z > 0) then
			tree(lobby, pos, rng)
		end
	end

	-- Brunnen in der Mitte
	part({
		Name = "Fountain",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 20, 20),
		CFrame = CFrame.new(0, 1, -22) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(200, 200, 210),
		Material = Enum.Material.Marble,
		Parent = lobby,
	})
	local water = part({
		Name = "Water",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 17, 17),
		CFrame = CFrame.new(0, 2.1, -22) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 170, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		CanCollide = false,
		Parent = lobby,
	})
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Rate = 8
	sparkle.Lifetime = NumberRange.new(1, 2)
	sparkle.Speed = NumberRange.new(4, 8)
	sparkle.SpreadAngle = Vector2.new(25, 25)
	sparkle.EmissionDirection = Enum.NormalId.Right
	sparkle.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
	sparkle.Parent = water

	return lobby
end

---------------------------------------------------------------------
-- Ei-Stände
---------------------------------------------------------------------
local function buildEggs(world: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Eggs"
	folder.Parent = world

	local names = {}
	for name in Config.Eggs do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		local ea, eb = Config.Eggs[a], Config.Eggs[b]
		if ea.Currency ~= eb.Currency then
			return ea.Currency == "Coins"
		end
		return ea.Cost < eb.Cost
	end)

	for i, name in names do
		local egg = Config.Eggs[name]
		local x = (i - (#names + 1) / 2) * 26
		local base = Vector3.new(x, 0, -70)

		part({
			Name = "Pedestal",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 14, 14),
			CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(60, 60, 80),
			Material = Enum.Material.Marble,
			Parent = folder,
		})
		-- Block + Kugel-Mesh ergibt eine Eiform (Ball-Parts wären immer rund)
		local eggPart = part({
			Name = name,
			Size = Vector3.new(7, 9, 7),
			Position = base + Vector3.new(0, 6.5, 0),
			Color = egg.Color,
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = eggPart
		eggPart:SetAttribute("Egg", name)
		CollectionService:AddTag(eggPart, "Egg")

		local currencyIcon = egg.Currency == "Gems" and "💎" or "💰"
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Öffnen"
		prompt.ObjectText = egg.DisplayName .. " – " .. egg.Cost .. " " .. currencyIcon
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = eggPart

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(220, 120)
		billboard.StudsOffset = Vector3.new(0, 8, 0)
		billboard.MaxDistance = 70
		billboard.Parent = eggPart
		local list = Instance.new("TextLabel")
		list.Size = UDim2.fromScale(1, 1)
		list.BackgroundTransparency = 1
		list.Font = Enum.Font.GothamBold
		list.TextScaled = true
		list.TextColor3 = Color3.new(1, 1, 1)
		list.TextStrokeTransparency = 0.3

		local lines = { egg.DisplayName .. " (" .. egg.Cost .. " " .. currencyIcon .. ")" }
		local entries = {}
		local total = 0
		for petName, chance in egg.Chances do
			total += chance
			table.insert(entries, { petName, chance })
		end
		table.sort(entries, function(a, b)
			return a[2] > b[2]
		end)
		for _, entry in entries do
			table.insert(lines, string.format("%s  %.1f%%", entry[1], entry[2] / total * 100))
		end
		list.Text = table.concat(lines, "\n")
		list.Parent = billboard
	end
end

---------------------------------------------------------------------
-- Bestenliste
---------------------------------------------------------------------
local function buildLeaderboard(world: Folder)
	local _, label = sign(
		world,
		CFrame.new(70, 12, -40) * CFrame.Angles(0, math.rad(135), 0),
		"🏆 Top Münzen\nLädt...",
		Vector2.new(16, 20)
	)
	label.Name = "LeaderboardText"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextScaled = false
	label.TextSize = 34
	label.Font = Enum.Font.GothamBold
	return label
end

---------------------------------------------------------------------
-- Obby-Hindernisse
-- Jede Funktion baut einen Abschnitt von z0 bis z1 auf Höhe y (Oberkante).
---------------------------------------------------------------------
local Obstacles = {}

-- Verteilt Plattformen gleichmäßig zwischen z0 und z1, so dass keine Lücke größer als maxGap ist.
local function layout(z0: number, z1: number, size: number, maxGap: number): { number }
	local length = z1 - z0
	local count = math.max(1, math.ceil((length - maxGap) / (size + maxGap)))
	local gap = (length - count * size) / (count + 1)
	local centers = {}
	for i = 1, count do
		table.insert(centers, z0 + gap * i + size * (i - 0.5))
	end
	return centers
end

function Obstacles.Gaps(folder, y, z0, z1, d, rng, color)
	local size = 7 - d * 2.5
	for _, z in layout(z0, z1, size, 3 + d * 3) do
		local x = rng:NextNumber(-6, 6) * d
		part({
			Size = Vector3.new(size, 1, size),
			Position = Vector3.new(x, y - 0.5, z),
			Color = color,
			Parent = folder,
		})
	end
end

function Obstacles.LavaStones(folder, y, z0, z1, d, rng, color)
	kill(part({
		Name = "Lava",
		Size = Vector3.new(30, 1, z1 - z0),
		Position = Vector3.new(0, y - 2, (z0 + z1) / 2),
		Parent = folder,
	}))
	local size = 5 - d * 2
	local x = 0
	for _, z in layout(z0, z1, size, 2 + d * 2.5) do
		x = math.clamp(x + rng:NextNumber(-5, 5), -10, 10)
		part({
			Size = Vector3.new(size, 1, size),
			Position = Vector3.new(x, y - 0.5, z),
			Color = color,
			Material = Enum.Material.Slate,
			Parent = folder,
		})
	end
end

function Obstacles.Moving(folder, y, z0, z1, d, _rng, color)
	local count = 3
	local spacing = (z1 - z0) / count
	for i = 1, count do
		local p = part({
			Name = "Mover",
			Size = Vector3.new(8, 1, 10),
			Position = Vector3.new(0, y - 0.5, z0 + spacing * (i - 0.5)),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		p:SetAttribute("BaseCFrame", p.CFrame)
		p:SetAttribute("Offset", Vector3.new(8 + d * 4, 0, 0) * (i % 2 == 0 and -1 or 1))
		p:SetAttribute("Period", 5 - d * 1.5)
		CollectionService:AddTag(p, "Mover")
	end
end

function Obstacles.Spinner(folder, y, z0, z1, d, _rng, color)
	part({
		Name = "Bridge",
		Size = Vector3.new(14, 1, z1 - z0),
		Position = Vector3.new(0, y - 0.5, (z0 + z1) / 2),
		Color = color,
		Parent = folder,
	})
	local count = d > 0.5 and 3 or 2
	for i = 1, count do
		local z = z0 + (z1 - z0) * i / (count + 1)
		part({
			Name = "Hub",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 3, 3),
			CFrame = CFrame.new(0, y + 1.5, z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(50, 50, 50),
			Parent = folder,
		})
		local bar = kill(part({
			Name = "Spinner",
			Size = Vector3.new(15, 1, 1),
			CFrame = CFrame.new(0, y + 1.2, z),
			CanCollide = false,
			Parent = folder,
		}))
		bar:SetAttribute("BaseCFrame", bar.CFrame)
		bar:SetAttribute("Speed", (1.6 + d * 1.8) * (i % 2 == 0 and -1 or 1))
		CollectionService:AddTag(bar, "Spinner")
	end
end

function Obstacles.Beam(folder, y, z0, z1, d, _rng, color)
	local width = math.max(0.9, 2 - d * 1.2)
	local mid = (z0 + z1) / 2
	local a = Vector3.new(0, y - 0.5, z0)
	local b = Vector3.new(7, y - 0.5, mid)
	local c = Vector3.new(0, y - 0.5, z1)
	for _, seg in { { a, b }, { b, c } } do
		local from, to = seg[1], seg[2]
		local len = (to - from).Magnitude + width
		part({
			Name = "Beam",
			Size = Vector3.new(width, 1, len),
			CFrame = CFrame.lookAt((from + to) / 2, to),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
	part({
		Name = "Corner",
		Size = Vector3.new(width * 2, 1, width * 2),
		Position = b,
		Color = color,
		Material = Enum.Material.Neon,
		Parent = folder,
	})
end

function Obstacles.Vanish(folder, y, z0, z1, d, rng, color)
	local size = 5
	local x = 0
	for _, z in layout(z0, z1, size, 1.5 + d * 2) do
		x = math.clamp(x + rng:NextNumber(-5, 5), -8, 8)
		local p = part({
			Name = "Vanish",
			Size = Vector3.new(size, 1, size),
			Position = Vector3.new(x, y - 0.5, z),
			Color = color,
			Material = Enum.Material.Glass,
			Transparency = 0.15,
			Parent = folder,
		})
		p:SetAttribute("VanishTime", 0.9 - d * 0.4)
		CollectionService:AddTag(p, "Vanish")
	end
end

function Obstacles.Truss(folder, y, z0, z1, d, _rng, color)
	local height = 12 + math.floor(d * 8)
	local wallZ = z0 + 14
	part({
		Name = "Floor",
		Size = Vector3.new(12, 1, wallZ - z0),
		Position = Vector3.new(0, y - 0.5, (z0 + wallZ) / 2),
		Color = color,
		Parent = folder,
	})
	part({
		Name = "Wall",
		Size = Vector3.new(30, height, 2),
		Position = Vector3.new(0, y + height / 2, wallZ + 1),
		Color = Color3.fromRGB(90, 90, 110),
		Material = Enum.Material.Brick,
		Parent = folder,
	})
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, height, 2)
	truss.Position = Vector3.new(0, y + height / 2, wallZ - 1)
	truss.Color = Color3.fromRGB(200, 200, 200)
	truss.Parent = folder
	part({
		Name = "Top",
		Size = Vector3.new(12, 1, z1 - wallZ - 2),
		Position = Vector3.new(0, y + height - 0.5, (wallZ + 2 + z1) / 2 - 1),
		Color = color,
		Parent = folder,
	})
	-- Treppe nach unten zum nächsten Checkpoint
	local steps = 4
	for i = 1, steps do
		part({
			Name = "Step",
			Size = Vector3.new(6, 1, 3),
			Position = Vector3.new(9, y + height - 0.5 - i * (height - RISE) / steps, z1 - 1.5 - (steps - i) * 3),
			Color = color,
			Parent = folder,
		})
	end
end

function Obstacles.LavaTiles(folder, y, z0, z1, d, rng, color)
	local tile = 4
	local cols = 5
	local rows = math.floor((z1 - z0) / tile)
	local safe = math.ceil(cols / 2)
	for r = 1, rows do
		-- Sicheren Weg zufällig weiterführen. Bei Spurwechsel sind alte und neue Spalte sicher,
		-- damit man nie diagonal über eine Lava-Ecke muss.
		local previous = safe
		safe = math.clamp(safe + rng:NextInteger(-1, 1), 1, cols)
		local extraSafe = rng:NextNumber() > d and math.clamp(safe + rng:NextInteger(-1, 1), 1, cols) or safe
		for c = 1, cols do
			local p = part({
				Size = Vector3.new(tile - 0.2, 1, tile - 0.2),
				Position = Vector3.new((c - (cols + 1) / 2) * tile, y - 0.5, z0 + (r - 0.5) * tile),
				Color = color,
				Parent = folder,
			})
			if c ~= safe and c ~= previous and c ~= extraSafe then
				kill(p)
			end
		end
	end
	-- Restlücke bis zum Checkpoint schließen
	local filled = z0 + rows * tile
	if filled < z1 then
		part({
			Size = Vector3.new(cols * tile, 1, z1 - filled),
			Position = Vector3.new(0, y - 0.5, (filled + z1) / 2),
			Color = color,
			Parent = folder,
		})
	end
end

local OBSTACLE_ORDER = { "Gaps", "LavaStones", "Moving", "Spinner", "Vanish", "Beam", "LavaTiles", "Truss" }

local function buildObby(world: Folder)
	local obby = Instance.new("Folder")
	obby.Name = "Obby"
	obby.Parent = world

	local checkpoints = {}
	local y = 1
	local z = OBBY_START_Z

	for stage = 1, Config.ObbyStages + 1 do
		local isFinish = stage == Config.ObbyStages + 1
		local color = STAGE_COLORS[(stage - 1) % #STAGE_COLORS + 1]

		local pad = part({
			Name = isFinish and "Finish" or ("Checkpoint" .. stage),
			Size = Vector3.new(isFinish and 30 or PAD_SIZE, 1, isFinish and 30 or PAD_SIZE),
			Position = Vector3.new(0, y - 0.5, z + (isFinish and (30 - PAD_SIZE) / 2 or 0)),
			Color = isFinish and Color3.fromRGB(255, 215, 0) or color,
			Material = Enum.Material.Neon,
			Parent = obby,
		})
		pad:SetAttribute("Stage", stage)
		CollectionService:AddTag(pad, isFinish and "Finish" or "Checkpoint")
		checkpoints[stage] = pad

		local _, label = sign(
			obby,
			CFrame.new(PAD_SIZE / 2 + 1, y + 4, z) * CFrame.Angles(0, math.rad(90), 0),
			isFinish and "🏆 ZIEL!" or ("Stufe " .. stage),
			Vector2.new(8, 3)
		)
		label.TextColor3 = color

		if isFinish then
			local fx = Instance.new("ParticleEmitter")
			fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			fx.Rate = 30
			fx.Speed = NumberRange.new(8, 16)
			fx.Lifetime = NumberRange.new(1.5, 2.5)
			fx.EmissionDirection = Enum.NormalId.Top
			fx.SpreadAngle = Vector2.new(40, 40)
			fx.Color = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 120, 200))
			fx.Parent = pad
			break
		end

		local section = Instance.new("Folder")
		section.Name = "Section" .. stage
		section.Parent = obby

		local z0 = z + PAD_SIZE / 2
		local z1 = z0 + SECTION_LENGTH
		local d = (stage - 1) / math.max(1, Config.ObbyStages - 1)
		local kind = OBSTACLE_ORDER[(stage - 1) % #OBSTACLE_ORDER + 1]
		Obstacles[kind](section, y, z0, z1, d, Random.new(stage * 1337), color)

		-- Sicherheitsnetz: Wer runterfällt, stirbt und startet am Checkpoint
		local net = kill(part({
			Name = "Void",
			Size = Vector3.new(80, 1, SECTION_LENGTH + PAD_SIZE),
			Position = Vector3.new(0, y - 14, (z0 + z1) / 2),
			Transparency = 0.6,
			Parent = section,
		}))
		net.Material = Enum.Material.ForceField

		y += RISE
		z = z1 + PAD_SIZE / 2
	end

	return checkpoints
end

---------------------------------------------------------------------
-- Licht & Atmosphäre
---------------------------------------------------------------------
local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(80, 80, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	Lighting.GlobalShadows = true

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Haze = 1
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 30
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting

	-- Tag-/Nacht-Zyklus (ein ganzer Tag = 10 Minuten)
	task.spawn(function()
		while true do
			Lighting.ClockTime = (Lighting.ClockTime + 24 / (10 * 60)) % 24
			task.wait(1)
		end
	end)
end

function WorldBuilder.Build()
	-- Studio-Standardteile entfernen, sonst landet man unter dem Obby auf der Baseplate
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace

	setupLighting()
	buildLobby(world)
	buildEggs(world)
	local leaderboardLabel = buildLeaderboard(world)
	local checkpoints = buildObby(world)

	local coins = Instance.new("Folder")
	coins.Name = "Coins"
	coins.Parent = workspace

	local pets = Instance.new("Folder")
	pets.Name = "Pets"
	pets.Parent = workspace

	return {
		Checkpoints = checkpoints,
		LeaderboardLabel = leaderboardLabel,
		CoinFolder = coins,
		PetFolder = pets,
		CoinArea = { Min = Vector2.new(-95, -95), Max = Vector2.new(95, 95) },
	}
end

return WorldBuilder
