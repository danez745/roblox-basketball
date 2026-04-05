local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local RemoteNames = require(Shared.RemoteNames)

local ScoreDetector = {}

local topZoneTouched: { [Part]: number } = {}
local scores: { [Player]: number } = {}
local BallManager: any = nil

function ScoreDetector.Init(hoop: Model, ballManager: any)
	BallManager = ballManager

	local topZone = hoop:FindFirstChild("TopZone")
	local bottomZone = hoop:FindFirstChild("BottomZone")

	if not topZone or not bottomZone then
		warn("[ScoreDetector] Missing scoring zones on hoop!")
		return
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	topZone.Touched:Connect(function(hit: BasePart)
		if hit.Name == "Basketball" then
			topZoneTouched[hit] = tick()
		end
	end)

	bottomZone.Touched:Connect(function(hit: BasePart)
		if hit.Name ~= "Basketball" then return end

		local topTime = topZoneTouched[hit]
		if not topTime then return end
		if tick() - topTime > Constants.SCORE_ZONE_TIMEOUT then
			topZoneTouched[hit] = nil
			return
		end

		-- Valid score!
		topZoneTouched[hit] = nil

		local scorer = BallManager.GetLastShooter()
		if scorer then
			scores[scorer] = (scores[scorer] or 0) + 1
			remotes[RemoteNames.ScoreNotify]:FireAllClients(scorer, scores[scorer])
		end
	end)
end

function ScoreDetector.GetScore(player: Player): number
	return scores[player] or 0
end

return ScoreDetector
