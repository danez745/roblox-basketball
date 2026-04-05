local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local ShotPowerController = {}
ShotPowerController.__index = ShotPowerController

export type ShotPowerController = typeof(setmetatable({} :: {
	isCharging: boolean,
	chargeStart: number,
	markerPos: number,          -- 0 = top/empty, 1 = bottom/full (matches bar fill)
	onChanged: ((markerPos: number, visible: boolean) -> ())?,
	connection: RBXScriptConnection?,
}, ShotPowerController))

function ShotPowerController.new(): ShotPowerController
	local self = setmetatable({}, ShotPowerController)
	self.isCharging = false
	self.chargeStart = 0
	self.markerPos = 0
	self.onChanged = nil
	self.connection = nil

	self.connection = RunService.RenderStepped:Connect(function(_dt)
		if not self.isCharging then return end

		local elapsed = tick() - self.chargeStart
		-- Triangle wave: 0→1→0→1... at SHOT_OSCILLATION_SPEED cycles/sec
		-- Each cycle up+down takes 2 / SHOT_OSCILLATION_SPEED seconds
		local phase = (elapsed * Constants.SHOT_OSCILLATION_SPEED) % 1
		self.markerPos = math.abs(phase * 2 - 1)  -- 0→1→0 per cycle

		if self.onChanged then
			self.onChanged(self.markerPos, true)
		end
	end)

	return self
end

function ShotPowerController.StartCharge(self: ShotPowerController)
	self.isCharging = true
	self.chargeStart = tick()
	self.markerPos = 0
end

-- Returns accuracy 0-1 based on how close fill is to sweet spot center on release
function ShotPowerController.ReleaseCharge(self: ShotPowerController): number
	self.isCharging = false

	local sweetCenter = Constants.SWEET_SPOT_CENTER  -- 0.70 (from bottom)
	local sweetHalf = Constants.SWEET_SPOT_WIDTH / 2  -- 0.08

	local dist = math.abs(self.markerPos - sweetCenter)
	local accuracy: number

	if dist <= sweetHalf then
		-- Inside green zone: accuracy 0.7 → 1.0
		accuracy = 0.7 + 0.3 * (1 - dist / sweetHalf)
	else
		-- Outside: accuracy falls off 0.7 → 0.0
		local maxDist = math.max(sweetCenter, 1 - sweetCenter)
		local t = math.clamp((dist - sweetHalf) / (maxDist - sweetHalf), 0, 1)
		accuracy = 0.7 * (1 - t)
	end

	self.markerPos = 0
	if self.onChanged then
		self.onChanged(0, false)
	end

	return accuracy
end

function ShotPowerController.IsCharging(self: ShotPowerController): boolean
	return self.isCharging
end

function ShotPowerController.CancelCharge(self: ShotPowerController)
	self.isCharging = false
	self.markerPos = 0
	if self.onChanged then
		self.onChanged(0, false)
	end
end

function ShotPowerController.Destroy(self: ShotPowerController)
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

return ShotPowerController
