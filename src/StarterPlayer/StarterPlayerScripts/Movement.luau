-- Doppelsprung + Sprint (Shift am PC, Knopf auf dem Handy).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local Movement = {}

local player = Players.LocalPlayer
local sprinting = false
local humanoid: Humanoid?
local canDoubleJump = false
local hasDoubleJumped = false

local function updateSpeed()
	if not humanoid then
		return
	end
	local base = humanoid:GetAttribute("BaseWalkSpeed") or Config.BaseWalkSpeed
	humanoid.WalkSpeed = base + (sprinting and Config.SprintBonus or 0)
end

function Movement.SetSprinting(value: boolean)
	sprinting = value
	updateSpeed()
end

function Movement.IsSprinting(): boolean
	return sprinting
end

local function onCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local h = humanoid :: Humanoid
	canDoubleJump = false
	hasDoubleJumped = false

	h.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			canDoubleJump = false
			hasDoubleJumped = false
		elseif new == Enum.HumanoidStateType.Freefall then
			task.wait(0.15)
			if not hasDoubleJumped then
				canDoubleJump = true
			end
		end
	end)
	-- Server setzt die Basis-Geschwindigkeit nach Upgrades neu
	h:GetAttributeChangedSignal("BaseWalkSpeed"):Connect(updateSpeed)
	updateSpeed()
end

function Movement.Init()
	UserInputService.JumpRequest:Connect(function()
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		if canDoubleJump and not hasDoubleJumped then
			hasDoubleJumped = true
			canDoubleJump = false
			local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
			if root then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, humanoid.JumpPower * 0.9, v.Z)
			end
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			Movement.SetSprinting(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			Movement.SetSprinting(false)
		end
	end)

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Movement
