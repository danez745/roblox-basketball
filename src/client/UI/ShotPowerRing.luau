--[[
	ShotPowerBar - Vertical shot meter with oscillating marker and green sweet spot.

	- A white marker line bounces up/down inside the bar.
	- A green band shows where to release for an accurate shot.
	- markerPos 0 = bottom of bar, 1 = top of bar.
	- SWEET_SPOT_CENTER (0.70) = 70% from bottom (inside green zone).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local ShotPowerBar = {}

local BAR_W  = 22   -- pixels wide
local BAR_H  = 200  -- pixels tall

local SWEET_CENTER = Constants.SWEET_SPOT_CENTER    -- 0.70
local SWEET_HALF   = Constants.SWEET_SPOT_WIDTH / 2 -- 0.08

local container: Frame = nil
local markerLine: Frame = nil

local function pctToYOffset(pct: number): number
	-- pct 0 = bottom, 1 = top.  YOffset is distance from top of the bar background.
	return math.floor((1 - pct) * BAR_H)
end

function ShotPowerBar.Create(parent: GuiObject)
	-- Outer wrapper (padding + dark bg)
	container = Instance.new("Frame")
	container.Name = "ShotPowerBar"
	container.Size = UDim2.fromOffset(BAR_W + 8, BAR_H + 20)
	container.Position = UDim2.new(0.64, 0, 0.5, -(BAR_H / 2 + 10))
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	container.BackgroundTransparency = 0.35
	container.BorderSizePixel = 0
	container.Visible = false
	container.Parent = parent

	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(0, 6)
	outerCorner.Parent = container

	-- Inner bar background
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromOffset(BAR_W, BAR_H)
	bg.Position = UDim2.fromOffset(4, 4)
	bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	bg.BorderSizePixel = 0
	bg.ZIndex = 2
	bg.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = bg

	-- Green sweet-spot band (always visible when bar is open)
	local sweetBottomFrac = math.max(0, SWEET_CENTER - SWEET_HALF)
	local sweetTopFrac    = math.min(1, SWEET_CENTER + SWEET_HALF)
	local sweetH          = math.floor((sweetTopFrac - sweetBottomFrac) * BAR_H)
	local sweetY          = math.floor((1 - sweetTopFrac) * BAR_H)

	local sweetBand = Instance.new("Frame")
	sweetBand.Name = "SweetBand"
	sweetBand.Size = UDim2.fromOffset(BAR_W, sweetH)
	sweetBand.Position = UDim2.fromOffset(4, 4 + sweetY)
	sweetBand.BackgroundColor3 = Color3.fromRGB(50, 220, 80)
	sweetBand.BackgroundTransparency = 0.4
	sweetBand.BorderSizePixel = 0
	sweetBand.ZIndex = 3
	sweetBand.Parent = container

	local sweetCorner = Instance.new("UICorner")
	sweetCorner.CornerRadius = UDim.new(0, 3)
	sweetCorner.Parent = sweetBand

	-- Bright center line of sweet spot
	local centerY = math.floor((1 - SWEET_CENTER) * BAR_H)
	local centerLine = Instance.new("Frame")
	centerLine.Name = "CenterLine"
	centerLine.Size = UDim2.fromOffset(BAR_W, 2)
	centerLine.Position = UDim2.fromOffset(4, 4 + centerY - 1)
	centerLine.BackgroundColor3 = Color3.fromRGB(0, 255, 70)
	centerLine.BackgroundTransparency = 0
	centerLine.BorderSizePixel = 0
	centerLine.ZIndex = 4
	centerLine.Parent = container

	-- Oscillating marker (white line with side triangles for visibility)
	markerLine = Instance.new("Frame")
	markerLine.Name = "Marker"
	markerLine.Size = UDim2.fromOffset(BAR_W + 8, 4)  -- slightly wider than bar
	markerLine.Position = UDim2.fromOffset(0, 4 + BAR_H - 2)  -- start at bottom
	markerLine.AnchorPoint = Vector2.new(0, 0.5)
	markerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	markerLine.BorderSizePixel = 0
	markerLine.ZIndex = 5
	markerLine.Parent = container

	-- "SHOOT" label at top
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(BAR_W + 8, 12)
	label.Position = UDim2.fromOffset(0, BAR_H + 7)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextSize = 10
	label.Font = Enum.Font.GothamBold
	label.Text = "SHOOT"
	label.ZIndex = 4
	label.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.5
	stroke.Parent = label
end

-- markerPos: 0 (bottom) → 1 (top).  visible: whether bar shows.
function ShotPowerBar.Update(markerPos: number, visible: boolean)
	if not container then return end
	container.Visible = visible
	if not visible or not markerLine then return end

	markerPos = math.clamp(markerPos, 0, 1)
	local yOffset = pctToYOffset(markerPos)
	markerLine.Position = UDim2.fromOffset(0, 4 + yOffset)

	-- Color marker based on whether it's inside the sweet spot
	local dist = math.abs(markerPos - SWEET_CENTER)
	if dist <= SWEET_HALF then
		markerLine.BackgroundColor3 = Color3.fromRGB(50, 255, 80)   -- green = good!
	else
		markerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- white = off
	end
end

return ShotPowerBar
