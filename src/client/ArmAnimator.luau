local TweenService = game:GetService("TweenService")

local ArmAnimator = {}
ArmAnimator.__index = ArmAnimator

export type ArmAnimator = typeof(setmetatable({} :: {
	character: Model,
	origC0: { [string]: CFrame },
	motors: { [string]: Motor6D },
	currentTweens: { Tween },
}, ArmAnimator))

local TWEEN_INFO_FAST   = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TWEEN_INFO_MEDIUM = TweenInfo.new(0.32, Enum.EasingStyle.Quad,  Enum.EasingDirection.InOut)
local TWEEN_INFO_SNAP   = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--[[
	Pose offsets are multiplied onto each motor's original C0.
	Only motors listed in a pose are touched; others are left alone.
]]
local Poses = {

	Idle = {
		RightShoulder = CFrame.new(),
		RightElbow    = CFrame.new(),
		Waist         = CFrame.new(),
		LeftShoulder  = CFrame.new(),
	},

	-- ── Dribble ────────────────────────────────────────────────────────────
	DribbleDown = {
		RightShoulder = CFrame.Angles(math.rad(45), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-90), 0, 0),
	},
	DribbleUp = {
		RightShoulder = CFrame.Angles(math.rad(20), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-45), 0, 0),
	},

	-- ── Shoot: ball held high above head, slight back lean ─────────────────
	ShootWindup = {
		RightShoulder = CFrame.Angles(math.rad(-150), math.rad(12), 0),
		RightElbow    = CFrame.Angles(math.rad(-95),  0, 0),
		Waist         = CFrame.Angles(math.rad(8),    0, 0),   -- lean back slightly
		LeftShoulder  = CFrame.Angles(math.rad(-30),  0, math.rad(-12)),
	},

	-- ── Shoot: snap forward on release (the actual throw) ──────────────────
	-- Arm whips up-forward, waist lunges forward, wrist follows through
	ShootRelease = {
		RightShoulder = CFrame.Angles(math.rad(-55), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-8),  0, 0),   -- nearly straight
		Waist         = CFrame.Angles(math.rad(-12), 0, 0),   -- lunge forward
		LeftShoulder  = CFrame.Angles(math.rad(-20), 0, 0),
	},

	-- ── Shoot: follow-through hang (arm stays extended for a moment) ────────
	ShootFollowThrough = {
		RightShoulder = CFrame.Angles(math.rad(-40), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-12), 0, 0),
		Waist         = CFrame.Angles(math.rad(-8),  0, 0),
		LeftShoulder  = CFrame.Angles(math.rad(-10), 0, 0),
	},

	-- ── Pickup ────────────────────────────────────────────────────────────
	PickupReach = {
		RightShoulder = CFrame.Angles(math.rad(70), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-20), 0, 0),
		Waist         = CFrame.Angles(math.rad(12), 0, 0),
	},

	-- ── Pass ─────────────────────────────────────────────────────────────
	PassExtend = {
		RightShoulder = CFrame.Angles(math.rad(-90), 0, 0),
		RightElbow    = CFrame.Angles(math.rad(-10), 0, 0),
		Waist         = CFrame.Angles(math.rad(-8),  0, 0),
	},
}

-- Motor names to track (R15)
local MOTOR_NAMES = { "RightShoulder", "RightElbow", "Waist", "LeftShoulder" }

local function findMotor(character: Model, name: string): Motor6D?
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Name == name then
			return d
		end
	end
	return nil
end

-- ── Constructor ────────────────────────────────────────────────────────────

function ArmAnimator.new(character: Model): ArmAnimator
	local self = setmetatable({}, ArmAnimator)
	self.character    = character
	self.origC0       = {}
	self.motors       = {}
	self.currentTweens = {}

	for _, name in MOTOR_NAMES do
		local motor = findMotor(character, name)
		if motor then
			self.motors[name]  = motor
			self.origC0[name]  = motor.C0
		end
	end

	return self
end

-- ── Internal helpers ───────────────────────────────────────────────────────

function ArmAnimator.CancelTweens(self: ArmAnimator)
	for _, t in self.currentTweens do t:Cancel() end
	table.clear(self.currentTweens)
end

-- Apply only the motors listed in the pose; leave others untouched.
function ArmAnimator.ApplyPose(self: ArmAnimator, poseName: string, tweenInfo: TweenInfo?)
	local pose = Poses[poseName]
	if not pose then return end

	self:CancelTweens()

	local info = tweenInfo or TWEEN_INFO_FAST

	for motorName, offset in pose do
		local motor  = self.motors[motorName]
		local origC0 = self.origC0[motorName]
		if motor and origC0 then
			local tween = TweenService:Create(motor, info, { C0 = origC0 * offset })
			tween:Play()
			table.insert(self.currentTweens, tween)
		end
	end
end

-- ── Public animation methods ───────────────────────────────────────────────

function ArmAnimator.PlayPickup(self: ArmAnimator)
	self:ApplyPose("PickupReach", TWEEN_INFO_MEDIUM)
	task.delay(0.4, function() self:ApplyPose("Idle", TWEEN_INFO_FAST) end)
end

--[[ Called while LMB is held — keeps the pose until release. ]]
function ArmAnimator.PlayShootWindup(self: ArmAnimator)
	self:ApplyPose("ShootWindup", TWEEN_INFO_MEDIUM)
end

--[[
	Called on LMB release.
	Sequence:
	  0.00 s — snap to ShootRelease    (throw snap)
	  0.30 s — ease to FollowThrough   (hang in air)
	  0.75 s — return to Idle
]]
function ArmAnimator.PlayShootRelease(self: ArmAnimator)
	self:ApplyPose("ShootRelease", TWEEN_INFO_SNAP)

	task.delay(0.28, function()
		self:ApplyPose("ShootFollowThrough", TWEEN_INFO_FAST)
	end)

	task.delay(0.75, function()
		self:ApplyPose("Idle", TWEEN_INFO_MEDIUM)
	end)
end

function ArmAnimator.PlayPass(self: ArmAnimator)
	self:ApplyPose("PassExtend", TWEEN_INFO_FAST)
	task.delay(0.3, function() self:ApplyPose("Idle", TWEEN_INFO_FAST) end)
end

function ArmAnimator.ResetToIdle(self: ArmAnimator)
	self:ApplyPose("Idle", TWEEN_INFO_FAST)
end

-- Exposed for BallAnimator dribble cycle
ArmAnimator.Poses         = Poses
ArmAnimator.TWEEN_INFO_FAST = TWEEN_INFO_FAST

return ArmAnimator
