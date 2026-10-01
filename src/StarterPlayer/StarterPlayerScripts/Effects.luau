-- Visuelle Effekte nur auf dem Client: Münzen drehen, Pets folgen, Popups, Ei-Animation.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Effects = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local sounds = {}
local function makeSound(name: string, id: string, volume: number)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = volume
	s.Parent = SoundService
	sounds[name] = s
end
makeSound("Coin", "rbxasset://sounds/electronicpingshort.wav", 0.4)
makeSound("Click", "rbxasset://sounds/button.wav", 0.5)

function Effects.Play(name: string)
	local s = sounds[name]
	if s then
		SoundService:PlayLocalSound(s)
	end
end

---------------------------------------------------------------------
-- Pets folgen ihrem Besitzer (für alle Spieler, lokal animiert)
---------------------------------------------------------------------
local function updatePets(t: number, dt: number)
	local petsByOwner = {}
	for _, pet in CollectionService:GetTagged("Pet") do
		local owner = pet:GetAttribute("Owner")
		if owner then
			petsByOwner[owner] = petsByOwner[owner] or {}
			table.insert(petsByOwner[owner], pet)
		end
	end
	for userId, pets in petsByOwner do
		local owner = Players:GetPlayerByUserId(userId)
		local root = owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local count = #pets
			for _, pet in pets do
				local slot = pet:GetAttribute("Slot") or 1
				local spread = (slot - (count + 1) / 2) * 3.5
				local bob = math.sin(t * 4 + slot) * 0.35
				local target = root.CFrame * CFrame.new(spread, 0.5 + bob, 5)
				-- Pet schaut in Laufrichtung des Besitzers
				local goal = CFrame.lookAt(target.Position, target.Position + root.CFrame.LookVector)
				pet.CFrame = pet.CFrame:Lerp(goal, math.clamp(dt * 10, 0, 1))
			end
		end
	end
end

-- Weiteres Sichtfeld beim Sprinten
local function updateFov(dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local base = humanoid:GetAttribute("BaseWalkSpeed") or Config.BaseWalkSpeed
	local sprinting = humanoid.WalkSpeed > base and humanoid.MoveDirection.Magnitude > 0
	local target = sprinting and 80 or 70
	camera.FieldOfView += (target - camera.FieldOfView) * math.clamp(dt * 8, 0, 1)
end

---------------------------------------------------------------------
-- Popup-Text in der Welt (z.B. "+5")
---------------------------------------------------------------------
local function worldPopup(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.Position = position
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(100, 40)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui

	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, anchor.Destroy, anchor)
end

---------------------------------------------------------------------
-- Ei-Animation
---------------------------------------------------------------------
function Effects.PlayHatch(screenGui: ScreenGui, eggName: string, petName: string)
	local egg = Config.Eggs[eggName]
	local pet = Config.Pets[petName]
	if not egg or not pet then
		return
	end
	local rarityColor = Config.Rarities[pet.Rarity]

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 50
	overlay.Parent = screenGui

	local eggFrame = Instance.new("Frame")
	eggFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	eggFrame.Position = UDim2.fromScale(0.5, 0.5)
	eggFrame.Size = UDim2.fromOffset(0, 0)
	eggFrame.BackgroundColor3 = egg.Color
	eggFrame.ZIndex = 51
	eggFrame.Parent = overlay
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = eggFrame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = eggFrame

	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.4 }):Play()
	TweenService:Create(eggFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(160, 200) })
		:Play()
	task.wait(0.45)

	-- Wackeln
	for i = 1, 6 do
		local angle = (i % 2 == 0) and 15 or -15
		TweenService:Create(eggFrame, TweenInfo.new(0.12), { Rotation = angle * (i / 3) }):Play()
		task.wait(0.13)
	end
	eggFrame.Rotation = 0

	-- Aufploppen
	TweenService:Create(eggFrame, TweenInfo.new(0.2), { Size = UDim2.fromOffset(240, 240), BackgroundTransparency = 1 })
		:Play()
	stroke.Transparency = 1
	Effects.Play("Coin")

	local petCircle = Instance.new("Frame")
	petCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	petCircle.Position = UDim2.fromScale(0.5, 0.45)
	petCircle.Size = UDim2.fromOffset(0, 0)
	petCircle.BackgroundColor3 = pet.Color
	petCircle.ZIndex = 52
	petCircle.Parent = overlay
	local petCorner = Instance.new("UICorner")
	petCorner.CornerRadius = UDim.new(pet.Shape == "Ball" and 0.5 or 0.15, 0)
	petCorner.Parent = petCircle
	local glow = Instance.new("UIStroke")
	glow.Thickness = 6
	glow.Color = rarityColor
	glow.Parent = petCircle

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.62)
	title.Size = UDim2.fromOffset(500, 90)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.RichText = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.ZIndex = 52
	title.Text = ('%s\n<font color="#%s">%s</font>  •  x%.2f'):format(
		petName,
		rarityColor:ToHex(),
		pet.Rarity,
		pet.Multiplier
	)
	title.TextTransparency = 1
	title.Parent = overlay

	TweenService:Create(petCircle, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(150, 150) })
		:Play()
	TweenService:Create(title, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
	task.wait(2.2)
	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	for _, obj in overlay:GetDescendants() do
		if obj:IsA("GuiObject") then
			TweenService:Create(obj, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		end
	end
	TweenService:Create(title, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.wait(0.35)
	overlay:Destroy()
end

function Effects.Init()
	local start = os.clock()
	local coinFolder = workspace:WaitForChild("Coins")

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - start
		-- Münzen drehen & schweben
		for _, coin in coinFolder:GetChildren() do
			if coin:IsA("BasePart") then
				local base = coin:GetAttribute("ClientBase")
				if not base then
					base = coin.Position
					coin:SetAttribute("ClientBase", base)
				end
				local offset = math.sin(t * 2 + base.X) * 0.4
				coin.CFrame = CFrame.new(base + Vector3.new(0, offset, 0)) * CFrame.Angles(0, t * 2 + base.Z, 0)
			end
		end
		updatePets(t, dt)
		updateFov(dt)
	end)

	Remotes.CoinCollected.OnClientEvent:Connect(function(amount, position, kind)
		Effects.Play("Coin")
		if kind == "Gem" then
			worldPopup(position, "+" .. amount .. " 💎", Color3.fromRGB(80, 220, 255))
		else
			worldPopup(position, "+" .. amount, Color3.fromRGB(255, 215, 50))
		end
	end)
end

return Effects
