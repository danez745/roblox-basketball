local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local BallState = require(Shared.BallState)

local BallAnimator = {}

local armAnimator: any = nil
local ball: Part? = nil
local isHolding = false
local isDribbling = false
local renderConnection: RBXScriptConnection? = nil

function BallAnimator.Init(armAnim: any)
	armAnimator = armAnim
end

function BallAnimator.SetBall(b: Part?)
	ball = b
end

function BallAnimator.StartDribble()
	if isDribbling then return end
	isDribbling = true

	if renderConnection then
		renderConnection:Disconnect()
	end

	local startTime = tick()

	renderConnection = RunService.RenderStepped:Connect(function(_dt)
		if not isDribbling or not ball then return end

		local ballAttach = ball:FindFirstChild("BallAttachment")
		if not ballAttach then return end

		-- Oscillate the ball attachment position for dribble effect
		local t = (tick() - startTime) * Constants.DRIBBLE_SPEED
		local yOffset = math.abs(math.sin(t)) * Constants.DRIBBLE_HEIGHT

		ballAttach.Position = Vector3.new(0, -yOffset, 0)

		-- Alternate arm poses between DribbleDown and DribbleUp
		local phase = math.sin(t)
		if phase > 0 then
			armAnimator:ApplyPose("DribbleDown", armAnimator.TWEEN_INFO_FAST)
		else
			armAnimator:ApplyPose("DribbleUp", armAnimator.TWEEN_INFO_FAST)
		end
	end)
end

function BallAnimator.StopDribble()
	isDribbling = false

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	-- Reset ball attachment position
	if ball then
		local ballAttach = ball:FindFirstChild("BallAttachment")
		if ballAttach then
			ballAttach.Position = Vector3.zero
		end
	end

	armAnimator:ResetToIdle()
end

function BallAnimator.SetHolding(holding: boolean)
	isHolding = holding
	if holding then
		BallAnimator.StartDribble()
	else
		BallAnimator.StopDribble()
	end
end

function BallAnimator.IsHolding(): boolean
	return isHolding
end

return BallAnimator
