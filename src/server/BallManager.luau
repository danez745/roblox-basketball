local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local RemoteNames = require(Shared.RemoteNames)
local BallState = require(Shared.BallState)

local BallManager = {}

local ball: Part = nil
local currentHolder: Player? = nil
local currentState: string = BallState.Free
local lastShooter: Player? = nil
local shotTime: number = 0

local remotes: Folder

local function getBall(): Part
	return ball
end

local function getState(): string
	return currentState
end

local function getHolder(): Player?
	return currentHolder
end

local function getLastShooter(): Player?
	return lastShooter
end

local function fireBallOwnerChanged()
	remotes[RemoteNames.BallOwnerChanged]:FireAllClients(
		currentHolder,
		currentState
	)
end

local function attachBallToPlayer(player: Player)
	local character = player.Character
	if not character then return end

	local rightHand = character:FindFirstChild("RightHand")
	if not rightHand then
		-- R6 fallback
		rightHand = character:FindFirstChild("Right Arm")
	end
	if not rightHand then return end

	ball.CanCollide = false
	ball.CFrame = rightHand.CFrame * CFrame.new(0, -0.5, -0.5)

	-- Create attachment on ball if not exists
	local ballAttach = ball:FindFirstChild("BallAttachment")
	if not ballAttach then
		ballAttach = Instance.new("Attachment")
		ballAttach.Name = "BallAttachment"
		ballAttach.Parent = ball
	end
	ballAttach.Position = Vector3.zero

	-- Create attachment on hand if not exists
	local handAttach = rightHand:FindFirstChild("BallHandAttachment")
	if not handAttach then
		handAttach = Instance.new("Attachment")
		handAttach.Name = "BallHandAttachment"
		handAttach.Position = Vector3.new(0, -0.5, -0.5)
		handAttach.Parent = rightHand
	end

	-- AlignPosition for smooth following
	local align = ball:FindFirstChild("BallAlignPosition")
	if not align then
		align = Instance.new("AlignPosition")
		align.Name = "BallAlignPosition"
		align.MaxForce = 100000
		align.MaxVelocity = math.huge
		align.Responsiveness = 200
		align.Parent = ball
	end
	align.Attachment0 = ballAttach
	align.Attachment1 = handAttach

	-- AlignOrientation
	local alignOri = ball:FindFirstChild("BallAlignOrientation")
	if not alignOri then
		alignOri = Instance.new("AlignOrientation")
		alignOri.Name = "BallAlignOrientation"
		alignOri.MaxTorque = 100000
		alignOri.Responsiveness = 200
		alignOri.Parent = ball
	end
	alignOri.Attachment0 = ballAttach
	alignOri.Attachment1 = handAttach

	ball:SetNetworkOwner(player)
end

local function detachBall()
	local align = ball:FindFirstChild("BallAlignPosition")
	if align then
		align.Attachment1 = nil
	end

	local alignOri = ball:FindFirstChild("BallAlignOrientation")
	if alignOri then
		alignOri.Attachment1 = nil
	end

	ball.CanCollide = true
	ball:SetNetworkOwner(nil) -- Server takes ownership
end

local function resetBall()
	detachBall()
	currentHolder = nil
	currentState = BallState.Free
	lastShooter = nil
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	ball.CFrame = CFrame.new(0, 5, 0)
	fireBallOwnerChanged()
end

local function onRequestPickup(player: Player)
	if currentState ~= BallState.Free then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local distance = (ball.Position - hrp.Position).Magnitude
	if distance > Constants.PICKUP_RANGE then return end

	currentHolder = player
	currentState = BallState.Held
	attachBallToPlayer(player)
	fireBallOwnerChanged()
end

local function onRequestDrop(player: Player)
	if currentHolder ~= player then return end

	detachBall()

	-- Give ball a small velocity from player movement
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			ball.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity
		end
	end

	currentHolder = nil
	currentState = BallState.Free
	fireBallOwnerChanged()
end

-- Default Roblox workspace gravity
local GRAVITY = 196.2

-- Calculate initial velocity to arc ball from startPos to targetPos.
-- arcHeight is studs above startPos that the peak reaches.
local function calculateArcVelocity(startPos: Vector3, targetPos: Vector3, arcHeight: number): Vector3
	local delta = targetPos - startPos

	-- vy0 to reach arcHeight above startPos
	local vy0 = math.sqrt(2 * GRAVITY * arcHeight)
	local timeToPeak = vy0 / GRAVITY

	-- Time to fall from peak to targetPos.Y
	local peakY = startPos.Y + arcHeight
	local fallDist = math.max(0, peakY - targetPos.Y)
	local timeFall = math.sqrt(2 * fallDist / GRAVITY)

	local totalTime = timeToPeak + timeFall
	if totalTime < 0.05 then totalTime = 0.05 end

	return Vector3.new(delta.X / totalTime, vy0, delta.Z / totalTime)
end

local function onRequestShoot(player: Player, accuracy: number)
	if currentHolder ~= player then return end
	if typeof(accuracy) ~= "number" then return end

	accuracy = math.clamp(accuracy, 0, 1)

	lastShooter = player
	shotTime = tick()

	-- Rim center in world space (matches HoopBuilder geometry)
	local hoopPos = Constants.HOOP_POSITION
	local rimCenter = Vector3.new(
		hoopPos.X,
		Constants.RIM_HEIGHT,
		hoopPos.Z + Constants.RIM_FORWARD_OFFSET
	)

	-- Add random offset based on inaccuracy
	local inaccuracy = 1 - accuracy
	local maxOff = Constants.MAX_ACCURACY_OFFSET
	local rng = Random.new()
	local offsetX = (rng:NextNumber() * 2 - 1) * inaccuracy * maxOff
	local offsetZ = (rng:NextNumber() * 2 - 1) * inaccuracy * maxOff
	local targetPos = rimCenter + Vector3.new(offsetX, 0, offsetZ)

	-- Arc height scales with distance so short and long shots look natural
	local startPos = ball.Position
	local hDist = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z).Magnitude
	local arcHeight = math.clamp(hDist * 0.28 + Constants.ARC_HEIGHT_BONUS, 5, 18)

	local velocity = calculateArcVelocity(startPos, targetPos, arcHeight)

	detachBall()
	ball.AssemblyLinearVelocity = velocity

	currentHolder = nil
	currentState = BallState.Shot
	fireBallOwnerChanged()

	-- Return to Free state after timeout
	task.delay(5, function()
		if currentState == BallState.Shot and tick() - shotTime >= 4.5 then
			currentState = BallState.Free
			fireBallOwnerChanged()
		end
	end)
end

local function onRequestPass(player: Player, targetPlayer: Player)
	if currentHolder ~= player then return end
	if not targetPlayer or not targetPlayer.Character then return end

	local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return end

	local direction = (targetHRP.Position - ball.Position).Unit

	lastShooter = player
	shotTime = tick()

	detachBall()

	ball.AssemblyLinearVelocity = direction * Constants.PASS_POWER + Vector3.new(0, 10, 0)

	currentHolder = nil
	currentState = BallState.Passed
	fireBallOwnerChanged()

	task.delay(3, function()
		if currentState == BallState.Passed then
			currentState = BallState.Free
			fireBallOwnerChanged()
		end
	end)
end

function BallManager.Init()
	remotes = ReplicatedStorage:WaitForChild("Remotes")

	-- Create ball
	ball = Instance.new("Part")
	ball.Name = "Basketball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(Constants.BALL_SIZE, Constants.BALL_SIZE, Constants.BALL_SIZE)
	ball.Color = Color3.fromRGB(220, 120, 30)
	ball.Material = Enum.Material.SmoothPlastic
	ball.CustomPhysicalProperties = PhysicalProperties.new(
		Constants.BALL_DENSITY,
		Constants.BALL_FRICTION,
		Constants.BALL_ELASTICITY,
		1, 1
	)
	ball.CFrame = CFrame.new(0, 5, 0)
	ball.Parent = workspace

	-- Create ball attachment
	local attach = Instance.new("Attachment")
	attach.Name = "BallAttachment"
	attach.Parent = ball

	-- Connect remotes
	remotes[RemoteNames.RequestPickup].OnServerEvent:Connect(onRequestPickup)
	remotes[RemoteNames.RequestDrop].OnServerEvent:Connect(onRequestDrop)
	remotes[RemoteNames.RequestShoot].OnServerEvent:Connect(onRequestShoot)
	remotes[RemoteNames.RequestPass].OnServerEvent:Connect(onRequestPass)

	-- Ball reset check
	task.spawn(function()
		while true do
			task.wait(1)
			if ball and ball.Position.Y < Constants.BALL_RESET_Y then
				resetBall()
			end
		end
	end)

	-- Clean up when holder leaves
	Players.PlayerRemoving:Connect(function(player)
		if currentHolder == player then
			resetBall()
		end
	end)
end

BallManager.GetBall = getBall
BallManager.GetState = getState
BallManager.GetHolder = getHolder
BallManager.GetLastShooter = getLastShooter

return BallManager
