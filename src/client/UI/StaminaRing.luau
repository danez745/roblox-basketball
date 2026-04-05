--[[
	StaminaBar — horizontal world-space bar at character feet.
	No ring. Just a clean pill-shaped bar in a BillboardGui.

	Layout:
	  ┌──────────────────────────────┐
	  │ ████████████████░░░░░░░░░░░ │   <- fill shrinks right as stamina drains
	  └──────────────────────────────┘
	         (floats at feet level)

	Colour: green (full) → yellow (half) → red (empty).
	Fill has a vertical UIGradient for a slight shine.
]]

local StaminaRing = {}

-- Layout (px)
local BAR_W   = 170
local BAR_H   = 14
local PAD     = 3       -- padding inside outer frame
local GUI_W   = BAR_W + PAD * 2
local GUI_H   = BAR_H + PAD * 2

local billboardGui: BillboardGui? = nil
local barFill: Frame? = nil

local function lerpColor(pct: number): Color3
	if pct > 0.5 then
		-- green → yellow
		local t = (1 - pct) / 0.5
		return Color3.fromRGB(
			math.floor(t * 255),
			210,
			0
		)
	else
		-- yellow → red
		local t = pct / 0.5
		return Color3.fromRGB(
			255,
			math.floor(t * 210),
			0
		)
	end
end

function StaminaRing.AttachToCharacter(character: Model)
	if billboardGui then
		billboardGui:Destroy()
		billboardGui = nil
		barFill = nil
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then return end

	-- BillboardGui at feet level (HRP is ~3 studs above floor in R15)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StaminaBillboard"
	gui.Size = UDim2.fromOffset(GUI_W, GUI_H)
	gui.StudsOffset = Vector3.new(0, -3.2, 0)
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Parent = rootPart
	billboardGui = gui

	-- ── Outer frame (background track) ─────────────────────────────────────
	local bg = Instance.new("Frame")
	bg.Name = "BarBg"
	bg.Size = UDim2.fromScale(1, 1)
	bg.Position = UDim2.fromScale(0, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = gui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.5, 0)
	bgCorner.Parent = bg

	-- Subtle white border
	local bgStroke = Instance.new("UIStroke")
	bgStroke.Thickness = 1
	bgStroke.Color = Color3.fromRGB(255, 255, 255)
	bgStroke.Transparency = 0.75
	bgStroke.Parent = bg

	-- ── Fill (shrinks from right as stamina drains) ─────────────────────────
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, -PAD * 2, 1, -PAD * 2)
	fill.Position = UDim2.fromOffset(PAD, PAD)
	fill.BackgroundColor3 = Color3.fromRGB(0, 210, 0)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill

	-- Vertical gradient for a subtle shine on the fill
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.46, Color3.fromRGB(0,   0,   0)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,   0,   0)),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.65),
		NumberSequenceKeypoint.new(0.45, 0.82),
		NumberSequenceKeypoint.new(0.46, 0.90),
		NumberSequenceKeypoint.new(1,   0.80),
	})
	gradient.Parent = fill

	barFill = fill
end

-- pct is 0 to 1
function StaminaRing.Update(pct: number)
	if not barFill then return end

	pct = math.clamp(pct, 0, 1)
	barFill.Size = UDim2.new(pct, -PAD * 2, 1, -PAD * 2)
	barFill.BackgroundColor3 = lerpColor(pct)
end

function StaminaRing.Detach()
	if billboardGui then
		billboardGui:Destroy()
		billboardGui = nil
		barFill = nil
	end
end

return StaminaRing
