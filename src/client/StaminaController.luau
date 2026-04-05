local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local StaminaController = {}
StaminaController.__index = StaminaController

export type StaminaController = typeof(setmetatable({} :: {
	current: number,
	max: number,
	isSprinting: boolean,
	isDribbling: boolean,
	onChanged: ((pct: number) -> ())?,
	connection: RBXScriptConnection?,
}, StaminaController))

function StaminaController.new(): StaminaController
	local self = setmetatable({}, StaminaController)
	self.current = Constants.MAX_STAMINA
	self.max = Constants.MAX_STAMINA
	self.isSprinting = false
	self.isDribbling = false
	self.onChanged = nil
	self.connection = nil

	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:Update(dt)
	end)

	return self
end

function StaminaController.Update(self: StaminaController, dt: number)
	local drainRate = 0

	if self.isSprinting then
		drainRate += Constants.STAMINA_DRAIN_RATE
	end

	if self.isDribbling then
		drainRate += Constants.DRIBBLE_STAMINA_DRAIN
	end

	if drainRate > 0 then
		self.current = math.max(0, self.current - drainRate * dt)
	else
		self.current = math.min(self.max, self.current + Constants.STAMINA_REGEN_RATE * dt)
	end

	-- Force stop sprint when out of stamina
	if self.current <= 0 and self.isSprinting then
		self.isSprinting = false
		local player = Players.LocalPlayer
		if player and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Constants.WALK_SPEED
			end
		end
	end

	if self.onChanged then
		self.onChanged(self.current / self.max)
	end
end

function StaminaController.StartSprint(self: StaminaController)
	if self.current <= 0 then return end
	self.isSprinting = true

	local player = Players.LocalPlayer
	if player and player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.SPRINT_SPEED
		end
	end
end

function StaminaController.StopSprint(self: StaminaController)
	self.isSprinting = false

	local player = Players.LocalPlayer
	if player and player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.WALK_SPEED
		end
	end
end

function StaminaController.SetDribbling(self: StaminaController, dribbling: boolean)
	self.isDribbling = dribbling
end

function StaminaController.GetPercentage(self: StaminaController): number
	return self.current / self.max
end

function StaminaController.Destroy(self: StaminaController)
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

return StaminaController
