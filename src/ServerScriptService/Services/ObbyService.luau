-- Checkpoints, Kill-Blöcke, bewegte/drehende/verschwindende Plattformen und das Ziel.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)

local ObbyService = {}

local checkpoints: { BasePart } = {}
local finishCooldown: { [Player]: number } = {}

local function playerFromHit(hit: BasePart): (Player?, Humanoid?)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	return player, humanoid
end

function ObbyService.TeleportToStage(player: Player, stage: number?)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local target = checkpoints[math.clamp(stage or data.Stage, 1, #checkpoints)]
	if target then
		character:PivotTo(CFrame.new(target.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(180), 0))
	end
end

function ObbyService.TeleportToLobby(player: Player)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(0, 5, 0))
	end
end

local function onCheckpoint(pad: BasePart)
	local stage = pad:GetAttribute("Stage")
	pad.Touched:Connect(function(hit)
		local player, humanoid = playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		local data = DataService.Get(player)
		-- Nur vorwärts: wer zurückläuft, verliert seinen Checkpoint nicht
		if not data or stage <= data.Stage then
			return
		end
		-- Kein Überspringen: man kann nur die nächste Stufe oder bereits erreichte freischalten
		if stage > data.MaxStage + 1 then
			return
		end
		data.Stage = stage
		if stage > data.MaxStage then
			data.MaxStage = stage
			local earned = PlayerService.EarnCoins(player, Config.StageReward(stage))
			PlayerService.Notify(player, ("Stufe %d erreicht! +%d 💰"):format(stage, earned), "success")
		end
		DataService.MarkChanged(player)
	end)
end

local function onFinish(pad: BasePart)
	local finalStage = pad:GetAttribute("Stage")
	pad.Touched:Connect(function(hit)
		local player, humanoid = playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		local data = DataService.Get(player)
		if not data or data.MaxStage < finalStage - 1 then
			return
		end
		local now = os.clock()
		if finishCooldown[player] and now - finishCooldown[player] < 10 then
			return
		end
		finishCooldown[player] = now

		local firstTime = data.MaxStage < finalStage
		data.MaxStage = math.max(data.MaxStage, finalStage)
		data.Stage = 1
		local earned = PlayerService.EarnCoins(player, Config.StageReward(finalStage) * 5)
		local gems = firstTime and 10 or 2
		PlayerService.GiveReward(player, { Gems = gems })
		PlayerService.NotifyAll(("🏆 %s hat das Obby geschafft!"):format(player.DisplayName), "success")
		PlayerService.Notify(player, ("Geschafft! +%d 💰  +%d 💎"):format(earned, gems), "success")
		task.delay(2, ObbyService.TeleportToLobby, player)
	end)
end

local function onKill(p: BasePart)
	p.Touched:Connect(function(hit)
		local _, humanoid = playerFromHit(hit)
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

local function onVanish(p: BasePart)
	local busy = false
	local original = p.Transparency
	p.Touched:Connect(function(hit)
		if busy then
			return
		end
		local player = playerFromHit(hit)
		if not player then
			return
		end
		busy = true
		local fade = TweenService:Create(p, TweenInfo.new(tonumber(p:GetAttribute("VanishTime")) or 0.8), { Transparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		p.CanCollide = false
		task.wait(2)
		p.CanCollide = true
		p.Transparency = original
		busy = false
	end)
end

local function startAnimators()
	local start = os.clock()
	RunService.Heartbeat:Connect(function()
		local t = os.clock() - start
		for _, p in CollectionService:GetTagged("Mover") do
			local base = p:GetAttribute("BaseCFrame")
			local offset = p:GetAttribute("Offset")
			local period = p:GetAttribute("Period")
			local w = math.pi * 2 / period
			p.CFrame = base + offset * math.sin(t * w)
			-- Geschwindigkeit setzen, damit Spieler auf der Plattform mitbewegt werden
			p.AssemblyLinearVelocity = offset * math.cos(t * w) * w
		end
		for _, p in CollectionService:GetTagged("Spinner") do
			local base = p:GetAttribute("BaseCFrame")
			p.CFrame = base * CFrame.Angles(0, t * p:GetAttribute("Speed"), 0)
		end
	end)
end

function ObbyService.Init(world)
	checkpoints = world.Checkpoints

	for _, pad in CollectionService:GetTagged("Checkpoint") do
		onCheckpoint(pad)
	end
	for _, pad in CollectionService:GetTagged("Finish") do
		onFinish(pad)
	end
	for _, p in CollectionService:GetTagged("Kill") do
		onKill(p)
	end
	for _, p in CollectionService:GetTagged("Vanish") do
		onVanish(p)
	end
	startAnimators()

	Players.PlayerRemoving:Connect(function(player)
		finishCooldown[player] = nil
	end)
end

-- Beim Respawn zum letzten Checkpoint teleportieren
function ObbyService.SetupPlayer(player: Player)
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		local data = DataService.Get(player)
		if data and data.Stage > 1 then
			task.wait(0.1)
			ObbyService.TeleportToStage(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return ObbyService
