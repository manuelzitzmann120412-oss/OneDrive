-- Die komplette Benutzeroberfläche, per Code erstellt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Effects = require(script.Parent.Effects)
local Movement = require(script.Parent.Movement)

local UI = {}

local player = Players.LocalPlayer
local state: any = nil
local screen: ScreenGui
local hud = {}
local panel: Frame
local panelTitle: TextLabel
local panelContent: ScrollingFrame
local currentPanel: string? = nil
local toastHolder: Frame

local THEME = {
	Background = Color3.fromRGB(28, 30, 42),
	Card = Color3.fromRGB(44, 47, 64),
	Accent = Color3.fromRGB(90, 170, 255),
	Green = Color3.fromRGB(70, 200, 110),
	Red = Color3.fromRGB(235, 80, 80),
	Gold = Color3.fromRGB(255, 205, 50),
	Gem = Color3.fromRGB(80, 220, 255),
	Text = Color3.new(1, 1, 1),
	SubText = Color3.fromRGB(180, 185, 200),
}

---------------------------------------------------------------------
-- Hilfsfunktionen
---------------------------------------------------------------------
local function formatNumber(n: number): string
	n = math.floor(n)
	if n >= 1e9 then
		return ("%.2fB"):format(n / 1e9)
	elseif n >= 1e6 then
		return ("%.2fM"):format(n / 1e6)
	elseif n >= 1e4 then
		return ("%.1fK"):format(n / 1e3)
	end
	return tostring(n)
end

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function stroke(parent: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function label(props): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = THEME.Text
	l.TextScaled = true
	for k, v in props do
		if k ~= "Parent" then
			(l :: any)[k] = v
		end
	end
	l.Parent = props.Parent
	return l
end

local function button(props, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.Font = Enum.Font.FredokaOne
	b.TextColor3 = THEME.Text
	b.TextScaled = true
	b.BackgroundColor3 = THEME.Accent
	for k, v in props do
		if k ~= "Parent" then
			(b :: any)[k] = v
		end
	end
	corner(b, 10)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = b
	b.Parent = props.Parent
	b.Activated:Connect(function()
		Effects.Play("Click")
		onClick()
	end)
	return b
end

---------------------------------------------------------------------
-- Benachrichtigungen
---------------------------------------------------------------------
local TOAST_COLORS = {
	info = THEME.Accent,
	success = THEME.Green,
	error = THEME.Red,
	rare = Color3.fromRGB(255, 170, 40),
}

function UI.Toast(text: string, kind: string?)
	if not toastHolder then
		return
	end
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 44)
	toast.BackgroundColor3 = THEME.Background
	toast.BackgroundTransparency = 0.1
	corner(toast, 10)
	stroke(toast, TOAST_COLORS[kind or "info"] or THEME.Accent, 3)
	local l = label({
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
		Text = text,
		Parent = toast,
	})
	toast.Parent = toastHolder

	task.delay(3.5, function()
		local info = TweenInfo.new(0.4)
		TweenService:Create(toast, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, info, { TextTransparency = 1 }):Play()
		local s = toast:FindFirstChildOfClass("UIStroke")
		if s then
			TweenService:Create(s, info, { Transparency = 1 }):Play()
		end
		task.wait(0.45)
		toast:Destroy()
	end)
end

local function request(action: string, arg: any?)
	local ok, success, message = pcall(function()
		return Remotes.Request:InvokeServer(action, arg)
	end)
	if not ok then
		UI.Toast("Verbindungsfehler", "error")
		return false
	end
	if message then
		UI.Toast(message, success and "success" or "error")
	end
	return success
end

---------------------------------------------------------------------
-- HUD (Münzen, Edelsteine, Multiplikator, Stufe)
---------------------------------------------------------------------
local function buildHud()
	local holder = Instance.new("Frame")
	holder.Name = "Stats"
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(12, 12)
	holder.Size = UDim2.fromOffset(210, 170)
	holder.Parent = screen
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = holder

	local function stat(name: string, icon: string, color: Color3)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 36)
		f.BackgroundColor3 = THEME.Background
		f.BackgroundTransparency = 0.15
		corner(f, 18)
		stroke(f, color, 2)
		label({
			Size = UDim2.fromOffset(32, 28),
			Position = UDim2.fromOffset(6, 4),
			Text = icon,
			Parent = f,
		})
		hud[name] = label({
			Size = UDim2.new(1, -50, 0, 26),
			Position = UDim2.fromOffset(42, 5),
			Text = "0",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = color,
			Font = Enum.Font.FredokaOne,
			Parent = f,
		})
		f.Parent = holder
	end
	stat("Coins", "💰", THEME.Gold)
	stat("Gems", "💎", THEME.Gem)
	stat("Multiplier", "✖️", THEME.Green)
	stat("Stage", "🏁", THEME.Accent)
end

local function updateHud()
	if not state then
		return
	end
	local oldCoins = tonumber(hud.Coins:GetAttribute("Value")) or 0
	hud.Coins.Text = formatNumber(state.Coins)
	hud.Coins:SetAttribute("Value", state.Coins)
	hud.Gems.Text = formatNumber(state.Gems)
	hud.Multiplier.Text = ("x%.2f"):format(state.Multiplier)
	hud.Stage.Text = ("Stufe %d / %d"):format(state.Stage, Config.ObbyStages)
	if state.Coins > oldCoins then
		-- Kleiner "Pop"-Effekt
		hud.Coins.Size = UDim2.new(1, -44, 0, 30)
		TweenService:Create(hud.Coins, TweenInfo.new(0.2), { Size = UDim2.new(1, -50, 0, 26) }):Play()
	end
end

---------------------------------------------------------------------
-- Panel (Fenster für Shop, Pets, ...)
---------------------------------------------------------------------
local Panels = {}

local function clearContent()
	for _, child in panelContent:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function useList()
	local list = panelContent:FindFirstChildOfClass("UIListLayout")
	if not list then
		list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 8)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = panelContent
	end
	return list
end

local function card(height: number, order: number): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, height)
	f.BackgroundColor3 = THEME.Card
	f.LayoutOrder = order
	corner(f, 10)
	f.Parent = panelContent
	return f
end

local function renderPanel()
	if not currentPanel or not state then
		return
	end
	clearContent()
	Panels[currentPanel].Render()
end

function UI.OpenPanel(name: string)
	if currentPanel == name then
		UI.ClosePanel()
		return
	end
	currentPanel = name
	panelTitle.Text = Panels[name].Title
	panel.Visible = true
	panel.Size = UDim2.fromScale(0.42, 0.55)
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromScale(0.46, 0.62) })
		:Play()
	panelContent.CanvasPosition = Vector2.zero
	renderPanel()
end

function UI.ClosePanel()
	currentPanel = nil
	panel.Visible = false
end

local function buildPanel()
	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.46, 0.62)
	panel.BackgroundColor3 = THEME.Background
	panel.Visible = false
	corner(panel, 16)
	stroke(panel, THEME.Accent, 3)
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(320, 300)
	limit.MaxSize = Vector2.new(640, 560)
	limit.Parent = panel
	panel.Parent = screen

	panelTitle = label({
		Size = UDim2.new(1, -70, 0, 40),
		Position = UDim2.fromOffset(16, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.FredokaOne,
		Text = "",
		Parent = panel,
	})
	button({
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -50, 0, 8),
		BackgroundColor3 = THEME.Red,
		Text = "X",
		Parent = panel,
	}, UI.ClosePanel)

	panelContent = Instance.new("ScrollingFrame")
	panelContent.Size = UDim2.new(1, -24, 1, -64)
	panelContent.Position = UDim2.fromOffset(12, 56)
	panelContent.BackgroundTransparency = 1
	panelContent.BorderSizePixel = 0
	panelContent.ScrollBarThickness = 6
	panelContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panelContent.CanvasSize = UDim2.new()
	panelContent.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = panelContent
end

---------------------------------------------------------------------
-- Shop: Upgrades & Gamepässe
---------------------------------------------------------------------
Panels.Shop = {
	Title = "🛒 Shop",
	Render = function()
		useList()
		local order = 0
		for _, name in { "Speed", "Jump", "Magnet" } do
			local u = Config.Upgrades[name]
			local level = state[u.Field]
			order += 1
			local c = card(70, order)
			label({
				Size = UDim2.new(0.6, -10, 0, 28),
				Position = UDim2.fromOffset(10, 6),
				Text = ("%s  (Lv. %d/%d)"):format(u.DisplayName, level, u.MaxLevel),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = c,
			})
			label({
				Size = UDim2.new(0.6, -10, 0, 20),
				Position = UDim2.fromOffset(10, 40),
				Text = u.Description,
				TextColor3 = THEME.SubText,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = c,
			})
			local maxed = level >= u.MaxLevel
			local cost = Config.UpgradeCost(name, level)
			button({
				Size = UDim2.new(0.38, -10, 0, 46),
				Position = UDim2.new(0.62, 0, 0, 12),
				BackgroundColor3 = maxed and THEME.SubText or (state.Coins >= cost and THEME.Green or THEME.Red),
				Text = maxed and "MAX" or (formatNumber(cost) .. " 💰"),
				Parent = c,
			}, function()
				if not maxed then
					request("BuyUpgrade", name)
				end
			end)
		end

		for passName, id in Config.GamePasses do
			if id ~= 0 then
				order += 1
				local c = card(60, order)
				label({
					Size = UDim2.new(0.6, -10, 1, -16),
					Position = UDim2.fromOffset(10, 8),
					Text = passName == "DoubleCoins" and "⭐ 2x Münzen (Gamepass)" or "👑 VIP: x1.25 + Tag",
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = c,
				})
				button({
					Size = UDim2.new(0.38, -10, 0, 40),
					Position = UDim2.new(0.62, 0, 0, 10),
					BackgroundColor3 = THEME.Gold,
					Text = "Robux",
					Parent = c,
				}, function()
					request("BuyGamePass", passName)
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Pets
---------------------------------------------------------------------
Panels.Pets = {
	Title = "🐾 Pets",
	Render = function()
		useList()
		-- Eier kaufen
		local eggNames = {}
		for name in Config.Eggs do
			table.insert(eggNames, name)
		end
		table.sort(eggNames, function(a, b)
			local ea, eb = Config.Eggs[a], Config.Eggs[b]
			if ea.Currency ~= eb.Currency then
				return ea.Currency == "Coins"
			end
			return ea.Cost < eb.Cost
		end)
		local eggRow = card(56, 1)
		eggRow.BackgroundTransparency = 1
		local eggLayout = Instance.new("UIListLayout")
		eggLayout.FillDirection = Enum.FillDirection.Horizontal
		eggLayout.Padding = UDim.new(0, 6)
		eggLayout.Parent = eggRow
		for _, eggName in eggNames do
			local egg = Config.Eggs[eggName]
			button({
				Size = UDim2.new(1 / #eggNames, -6, 1, 0),
				BackgroundColor3 = egg.Color,
				TextColor3 = Color3.new(0.1, 0.1, 0.1),
				Text = ("🥚 %s\n%s %s"):format(egg.DisplayName, formatNumber(egg.Cost), egg.Currency == "Gems" and "💎" or "💰"),
				Parent = eggRow,
			}, function()
				request("HatchEgg", eggName)
			end)
		end

		local info = card(40, 2)
		info.BackgroundTransparency = 1
		label({
			Size = UDim2.new(0.6, 0, 1, 0),
			Text = ("%d/%d Pets  •  %d/%d ausgerüstet"):format(
				#state.Pets,
				Config.MaxPets,
				#state.EquippedPets,
				Config.MaxEquippedPets
			),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.SubText,
			Parent = info,
		})
		button({
			Size = UDim2.new(0.38, 0, 1, 0),
			Position = UDim2.fromScale(0.62, 0),
			BackgroundColor3 = THEME.Green,
			Text = "⭐ Beste ausrüsten",
			Parent = info,
		}, function()
			request("EquipBestPets")
		end)

		if #state.Pets == 0 then
			local empty = card(60, 3)
			empty.BackgroundTransparency = 1
			label({
				Size = UDim2.fromScale(1, 1),
				Text = "Noch keine Pets – öffne ein Ei! 🥚",
				TextColor3 = THEME.SubText,
				Parent = empty,
			})
			return
		end

		-- Pets sortiert nach Stärke
		local indices = {}
		for i, petName in state.Pets do
			if Config.Pets[petName] then
				table.insert(indices, i)
			end
		end
		table.sort(indices, function(a, b)
			local ea = table.find(state.EquippedPets, a) ~= nil
			local eb = table.find(state.EquippedPets, b) ~= nil
			if ea ~= eb then
				return ea
			end
			return Config.Pets[state.Pets[a]].Multiplier > Config.Pets[state.Pets[b]].Multiplier
		end)

		local grid = card(0, 3)
		grid.BackgroundTransparency = 1
		grid.AutomaticSize = Enum.AutomaticSize.Y
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.fromOffset(120, 130)
		layout.CellPadding = UDim2.fromOffset(8, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid

		for order, index in indices do
			local petName = state.Pets[index]
			local pet = Config.Pets[petName]
			local equipped = table.find(state.EquippedPets, index) ~= nil
			local rarityColor = Config.Rarities[pet.Rarity]

			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = THEME.Card
			cell.LayoutOrder = order
			corner(cell, 10)
			stroke(cell, equipped and THEME.Green or rarityColor, equipped and 4 or 2)
			cell.Parent = grid

			local icon = Instance.new("Frame")
			icon.Size = UDim2.fromOffset(44, 44)
			icon.Position = UDim2.new(0.5, -22, 0, 8)
			icon.BackgroundColor3 = pet.Color
			corner(icon, pet.Shape == "Ball" and 22 or 8)
			icon.Parent = cell

			label({
				Size = UDim2.new(1, -8, 0, 18),
				Position = UDim2.fromOffset(4, 56),
				Text = petName,
				Parent = cell,
			})
			label({
				Size = UDim2.new(1, -8, 0, 14),
				Position = UDim2.fromOffset(4, 74),
				Text = ("%s • x%.2f"):format(pet.Rarity, pet.Multiplier),
				TextColor3 = rarityColor,
				Font = Enum.Font.Gotham,
				Parent = cell,
			})
			button({
				Size = UDim2.new(0.7, -6, 0, 30),
				Position = UDim2.new(0, 4, 1, -34),
				BackgroundColor3 = equipped and THEME.SubText or THEME.Green,
				Text = equipped and "Ablegen" or "Ausrüsten",
				Parent = cell,
			}, function()
				request("ToggleEquipPet", index)
			end)
			local confirmDelete = false
			local deleteButton
			deleteButton = button({
				Size = UDim2.new(0.3, -4, 0, 30),
				Position = UDim2.new(0.7, 0, 1, -34),
				BackgroundColor3 = THEME.Red,
				Text = "🗑",
				Parent = cell,
			}, function()
				-- Zweimal klicken zum Löschen, damit man nicht aus Versehen löscht
				if not confirmDelete then
					confirmDelete = true
					deleteButton.Text = "OK?"
					task.delay(2, function()
						confirmDelete = false
						if deleteButton.Parent then
							deleteButton.Text = "🗑"
						end
					end)
					return
				end
				request("DeletePet", index)
			end)
		end
	end,
}

---------------------------------------------------------------------
-- Trails
---------------------------------------------------------------------
Panels.Trails = {
	Title = "✨ Trails",
	Render = function()
		useList()
		local names = {}
		for name in Config.Trails do
			table.insert(names, name)
		end
		table.sort(names, function(a, b)
			local ta, tb = Config.Trails[a], Config.Trails[b]
			if ta.Currency ~= tb.Currency then
				return ta.Currency == "Coins"
			end
			return ta.Cost < tb.Cost
		end)
		for order, name in names do
			local trail = Config.Trails[name]
			local owned = table.find(state.Trails, name) ~= nil
			local equipped = state.EquippedTrail == name
			local c = card(56, order)

			local preview = Instance.new("Frame")
			preview.Size = UDim2.fromOffset(60, 36)
			preview.Position = UDim2.fromOffset(10, 10)
			preview.BackgroundColor3 = Color3.new(1, 1, 1)
			corner(preview, 8)
			local gradient = Instance.new("UIGradient")
			if trail.Rainbow then
				local keypoints = {}
				for i = 0, 6 do
					table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
				end
				gradient.Color = ColorSequence.new(keypoints)
			elseif trail.Colors then
				gradient.Color = ColorSequence.new(trail.Colors[1], trail.Colors[2])
			else
				preview.BackgroundColor3 = THEME.Background
			end
			gradient.Parent = preview
			preview.Parent = c

			label({
				Size = UDim2.new(0.5, -90, 0, 30),
				Position = UDim2.fromOffset(80, 13),
				Text = trail.DisplayName,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = c,
			})

			local text, color
			if equipped then
				text, color = "Ausgerüstet", THEME.SubText
			elseif owned then
				text, color = "Ausrüsten", THEME.Accent
			else
				text = formatNumber(trail.Cost) .. (trail.Currency == "Gems" and " 💎" or " 💰")
				color = THEME.Green
			end
			button({
				Size = UDim2.new(0.38, -10, 0, 40),
				Position = UDim2.new(0.62, 0, 0, 8),
				BackgroundColor3 = color,
				Text = text,
				Parent = c,
			}, function()
				if not equipped then
					request("BuyTrail", name)
				end
			end)
		end
	end,
}

---------------------------------------------------------------------
-- Rebirth
---------------------------------------------------------------------
Panels.Rebirth = {
	Title = "🔁 Rebirth",
	Render = function()
		useList()
		local cost = Config.RebirthCost(state.Rebirths)
		local nextMult = 1 + (state.Rebirths + 1) * Config.RebirthMultiplierPerLevel
		local c = card(150, 1)
		label({
			Size = UDim2.new(1, -20, 0, 110),
			Position = UDim2.fromOffset(10, 10),
			TextWrapped = true,
			Font = Enum.Font.Gotham,
			Text = ("Rebirths: %d\n\nSetzt Münzen & Upgrades zurück.\nDafür bekommst du dauerhaft x%.1f Rebirth-Bonus und %d 💎!\n\nKosten: %s 💰"):format(
				state.Rebirths,
				nextMult,
				Config.RebirthGemReward,
				formatNumber(cost)
			),
			Parent = c,
		})
		local progress = card(30, 2)
		progress.BackgroundColor3 = THEME.Background
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(math.clamp(state.Coins / cost, 0, 1), 1)
		fill.BackgroundColor3 = THEME.Gold
		corner(fill, 10)
		fill.Parent = progress
		label({
			Size = UDim2.fromScale(1, 0.8),
			Position = UDim2.fromScale(0, 0.1),
			Text = ("%s / %s"):format(formatNumber(state.Coins), formatNumber(cost)),
			Parent = progress,
		})
		local canRebirth = state.Coins >= cost
		local holder = card(56, 3)
		holder.BackgroundTransparency = 1
		button({
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = canRebirth and THEME.Green or THEME.SubText,
			Text = canRebirth and "🔁 REBIRTH!" or "Noch nicht genug Münzen",
			Parent = holder,
		}, function()
			request("Rebirth")
		end)
	end,
}

---------------------------------------------------------------------
-- Tägliche Belohnung
---------------------------------------------------------------------
local serverTimeOffset = 0

Panels.Daily = {
	Title = "🎁 Tägliche Belohnung",
	Render = function()
		useList()
		local now = os.time() + serverTimeOffset
		local since = now - state.LastDaily
		local streakAlive = since <= Config.DailyStreakReset
		local nextDay = ((streakAlive and state.DailyStreak or 0) % #Config.DailyRewards) + 1

		local row = card(90, 1)
		row.BackgroundTransparency = 1
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.Parent = row
		for day, reward in Config.DailyRewards do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.new(1 / #Config.DailyRewards, -4, 1, 0)
			cell.BackgroundColor3 = day == nextDay and THEME.Green or (day < nextDay and THEME.Background or THEME.Card)
			corner(cell, 8)
			cell.Parent = row
			local text = ("Tag %d\n%s💰"):format(day, formatNumber(reward.Coins or 0))
			if reward.Gems then
				text ..= ("\n%d💎"):format(reward.Gems)
			end
			label({
				Size = UDim2.new(1, -4, 1, -6),
				Position = UDim2.fromOffset(2, 3),
				Text = text,
				Parent = cell,
			})
		end

		local ready = since >= Config.DailyCooldown
		local holder = card(56, 2)
		holder.BackgroundTransparency = 1
		local text
		if ready then
			text = "🎁 Abholen!"
		else
			local left = Config.DailyCooldown - since
			text = ("Wieder in %dh %dmin"):format(left // 3600, (left % 3600) // 60)
		end
		button({
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = ready and THEME.Green or THEME.SubText,
			Text = text,
			Parent = holder,
		}, function()
			request("ClaimDaily")
		end)
	end,
}

---------------------------------------------------------------------
-- Codes
---------------------------------------------------------------------
Panels.Codes = {
	Title = "🎟️ Codes",
	-- Nicht bei jeder Datenänderung neu zeichnen, sonst verschwindet der getippte Text
	Static = true,
	Render = function()
		useList()
		local c = card(60, 1)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.62, -10, 0, 44)
		box.Position = UDim2.fromOffset(8, 8)
		box.BackgroundColor3 = THEME.Background
		box.TextColor3 = THEME.Text
		box.PlaceholderText = "Code eingeben..."
		box.PlaceholderColor3 = THEME.SubText
		box.Font = Enum.Font.GothamBold
		box.TextScaled = true
		box.ClearTextOnFocus = false
		box.Text = ""
		corner(box, 8)
		box.Parent = c
		button({
			Size = UDim2.new(0.38, -8, 0, 44),
			Position = UDim2.new(0.62, 0, 0, 8),
			BackgroundColor3 = THEME.Green,
			Text = "Einlösen",
			Parent = c,
		}, function()
			if request("RedeemCode", box.Text) then
				box.Text = ""
			end
		end)
		local hint = card(40, 2)
		hint.BackgroundTransparency = 1
		label({
			Size = UDim2.fromScale(1, 1),
			Text = "Tipp: Probier mal WELCOME 😉",
			TextColor3 = THEME.SubText,
			Font = Enum.Font.Gotham,
			Parent = hint,
		})
	end,
}

---------------------------------------------------------------------
-- Seitenmenü
---------------------------------------------------------------------
local function buildMenu()
	local menu = Instance.new("Frame")
	menu.Name = "Menu"
	menu.BackgroundTransparency = 1
	menu.AnchorPoint = Vector2.new(0, 0.5)
	menu.Position = UDim2.new(0, 12, 0.55, 0)
	menu.Size = UDim2.fromOffset(150, 420)
	menu.Parent = screen
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = menu

	local entries = {
		{ "🛒 Shop", THEME.Accent, function()
			UI.OpenPanel("Shop")
		end },
		{ "🐾 Pets", Color3.fromRGB(240, 130, 60), function()
			UI.OpenPanel("Pets")
		end },
		{ "✨ Trails", Color3.fromRGB(180, 100, 255), function()
			UI.OpenPanel("Trails")
		end },
		{ "🔁 Rebirth", THEME.Green, function()
			UI.OpenPanel("Rebirth")
		end },
		{ "🎁 Täglich", THEME.Gold, function()
			UI.OpenPanel("Daily")
		end },
		{ "🎟️ Codes", Color3.fromRGB(255, 110, 170), function()
			UI.OpenPanel("Codes")
		end },
		{ "📍 Checkpoint", Color3.fromRGB(90, 90, 120), function()
			request("TeleportCheckpoint")
		end },
		{ "🏠 Lobby", Color3.fromRGB(90, 90, 120), function()
			request("TeleportLobby")
		end },
	}
	for _, entry in entries do
		local b = button({
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = entry[2],
			Text = entry[1],
			Parent = menu,
		}, entry[3])
		stroke(b, Color3.new(0, 0, 0), 2)
	end

	-- Kleinere Bildschirme (Handy): Menü verkleinern
	local scale = Instance.new("UIScale")
	scale.Parent = menu
	local function resize()
		local viewport = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(viewport.Y / 800, 0.6, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()
end

local function buildSprintButton()
	if not UserInputService.TouchEnabled then
		return
	end
	local b
	b = button({
		Name = "Sprint",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -150, 1, -40),
		Size = UDim2.fromOffset(80, 80),
		BackgroundColor3 = THEME.Accent,
		BackgroundTransparency = 0.25,
		Text = "🏃",
		Parent = screen,
	}, function()
		Movement.SetSprinting(not Movement.IsSprinting())
		b.BackgroundColor3 = Movement.IsSprinting() and THEME.Green or THEME.Accent
	end)
	corner(b, 40)
end

function UI.Init()
	screen = Instance.new("ScreenGui")
	screen.Name = "GameUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")

	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.BackgroundTransparency = 1
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 10)
	toastHolder.Size = UDim2.fromOffset(420, 300)
	toastHolder.ZIndex = 40
	toastHolder.Parent = screen
	local toastList = Instance.new("UIListLayout")
	toastList.Padding = UDim.new(0, 6)
	toastList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastList.Parent = toastHolder

	buildHud()
	buildMenu()
	buildPanel()
	buildSprintButton()

	Remotes.DataChanged.OnClientEvent:Connect(function(newState)
		state = newState
		serverTimeOffset = newState.ServerTime - os.time()
		updateHud()
		if currentPanel and not Panels[currentPanel].Static then
			renderPanel()
		end
	end)

	Remotes.Notify.OnClientEvent:Connect(function(text, kind)
		UI.Toast(text, kind)
	end)

	Remotes.EggHatched.OnClientEvent:Connect(function(eggName, petName)
		UI.ClosePanel()
		task.spawn(Effects.PlayHatch, screen, eggName, petName)
	end)

	-- Tastenkürzel
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local shortcuts = {
			[Enum.KeyCode.B] = "Shop",
			[Enum.KeyCode.P] = "Pets",
			[Enum.KeyCode.T] = "Trails",
			[Enum.KeyCode.R] = "Rebirth",
		}
		local name = shortcuts[input.KeyCode]
		if name then
			UI.OpenPanel(name)
		elseif input.KeyCode == Enum.KeyCode.Escape and currentPanel then
			UI.ClosePanel()
		end
	end)
end

return UI
