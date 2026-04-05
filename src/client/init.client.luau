local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local RemoteNames = require(Shared.RemoteNames)
local BallState = require(Shared.BallState)

local InputController = require(script.InputController)
local ArmAnimator = require(script.ArmAnimator)
local BallAnimator = require(script.BallAnimator)
local StaminaController = require(script.StaminaController)
local ShotPowerController = require(script.ShotPowerController)
local UI = require(script.UI)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local remotes: Folder
local armAnimator: any = nil
local staminaCtrl: any = nil
local shotPowerCtrl: any = nil
local isHolding = false

local function findBall(): Part?
	return Workspace:FindFirstChild("Basketball")
end

local function findNearestPlayer(): Player?
	local character = player.Character
	if not character then return nil end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local lookDir = camera.CFrame.LookVector
	local bestPlayer: Player? = nil
	local bestDot = -1

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer == player then continue end

		local otherChar = otherPlayer.Character
		if not otherChar then continue end

		local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
		if not otherHRP then continue end

		local toOther = (otherHRP.Position - hrp.Position)
		local distance = toOther.Magnitude

		if distance > Constants.PASS_RANGE then continue end

		local dot = toOther.Unit:Dot(lookDir)
		if dot > 0.3 and dot > bestDot then
			bestDot = dot
			bestPlayer = otherPlayer
		end
	end

	return bestPlayer
end

local function onPickupDrop()
	if isHolding then
		-- Drop
		remotes[RemoteNames.RequestDrop]:FireServer()
	else
		-- Try pickup
		local ball = findBall()
		if not ball then return end

		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local distance = (ball.Position - hrp.Position).Magnitude
		if distance <= Constants.PICKUP_RANGE then
			remotes[RemoteNames.RequestPickup]:FireServer()
			armAnimator:PlayPickup()
		end
	end
end

local function onShootStart()
	if not isHolding then return end
	shotPowerCtrl:StartCharge()
	armAnimator:PlayShootWindup()
end

local function onShootRelease()
	if not shotPowerCtrl:IsCharging() then return end

	local accuracy = shotPowerCtrl:ReleaseCharge()

	-- Jump on shoot
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local state = humanoid:GetState()
			if state ~= Enum.HumanoidStateType.Freefall
				and state ~= Enum.HumanoidStateType.Jumping then
				humanoid.Jump = true
			end
		end
	end

	remotes[RemoteNames.RequestShoot]:FireServer(accuracy)
	armAnimator:PlayShootRelease()
end

local function onPass()
	if not isHolding then return end

	local target = findNearestPlayer()
	if not target then return end

	remotes[RemoteNames.RequestPass]:FireServer(target)
	armAnimator:PlayPass()
end

local function onSprintStart()
	staminaCtrl:StartSprint()
end

local function onSprintEnd()
	staminaCtrl:StopSprint()
end

local function onBallOwnerChanged(owner: Player?, state: string)
	local localIsHolding = (owner == player) and (state == BallState.Held)

	if localIsHolding ~= isHolding then
		isHolding = localIsHolding
		BallAnimator.SetHolding(isHolding)
		staminaCtrl:SetDribbling(isHolding)

		if isHolding then
			BallAnimator.SetBall(findBall())
		end
	end
end

local function onScoreNotify(scorer: Player, totalScore: number)
	UI.UpdateScore(scorer, totalScore)
end

local function initCharacter(character: Model)
	-- Wait for humanoid to load
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = Constants.WALK_SPEED

	-- Wait for right arm (R15)
	character:WaitForChild("RightUpperArm")

	-- Create arm animator
	armAnimator = ArmAnimator.new(character)

	-- Init ball animator
	BallAnimator.Init(armAnimator)
	BallAnimator.SetBall(findBall())

	-- Attach stamina ring BillboardGui to this character
	UI.AttachStaminaToCharacter(character)

	-- Reset state
	isHolding = false
end

-- Wait for remotes
remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Wait for all remote events
for _, name in RemoteNames do
	remotes:WaitForChild(name)
end

-- Create controllers
staminaCtrl = StaminaController.new()
shotPowerCtrl = ShotPowerController.new()

-- Init UI
UI.Init(staminaCtrl, shotPowerCtrl)

-- Init input
InputController.Init({
	onPickupDrop = onPickupDrop,
	onShootStart = onShootStart,
	onShootRelease = onShootRelease,
	onPass = onPass,
	onSprintStart = onSprintStart,
	onSprintEnd = onSprintEnd,
})

-- Listen to ball state changes
remotes[RemoteNames.BallOwnerChanged].OnClientEvent:Connect(onBallOwnerChanged)
remotes[RemoteNames.ScoreNotify].OnClientEvent:Connect(onScoreNotify)

-- Handle character
if player.Character then
	initCharacter(player.Character)
end
player.CharacterAdded:Connect(initCharacter)

print("[Client] Basketball client initialized!")
