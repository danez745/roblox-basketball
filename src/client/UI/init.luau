local Players = game:GetService("Players")

local StaminaRing = require(script.StaminaRing)
local ShotPowerBar = require(script.ShotPowerRing) -- file kept as ShotPowerRing.luau
local ScoreDisplay = require(script.ScoreDisplay)

local UI = {}

local screenGui: ScreenGui = nil

function UI.Init(staminaCtrl: any, shotPowerCtrl: any)
	local player = Players.LocalPlayer

	-- ScreenGui for shot power bar and score (not stamina - that's BillboardGui)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BasketballUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	ShotPowerBar.Create(screenGui)
	ScoreDisplay.Create(screenGui)

	-- Wire shot power updates (markerPos 0-1, visible bool)
	shotPowerCtrl.onChanged = function(markerPos: number, visible: boolean)
		ShotPowerBar.Update(markerPos, visible)
	end

	-- Wire stamina: update ring color/pct (ring itself lives in BillboardGui on character)
	staminaCtrl.onChanged = function(pct: number)
		StaminaRing.Update(pct)
	end
end

-- Call this each time the character spawns to attach the stamina ring to the new character
function UI.AttachStaminaToCharacter(character: Model)
	StaminaRing.AttachToCharacter(character)
end

function UI.UpdateScore(player: Player, score: number)
	ScoreDisplay.UpdateScore(player, score)
end

return UI
