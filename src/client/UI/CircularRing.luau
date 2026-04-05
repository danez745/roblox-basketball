--[[
	CircularRing - Reusable circular progress ring widget
	Uses the two-half-circle clipping technique:
	  - Two clip frames (left/right halves)
	  - Each contains a full-circle fill that rotates to reveal progress
	  - An inner circle creates the donut hole
]]

local CircularRing = {}
CircularRing.__index = CircularRing

export type Config = {
	size: UDim2,
	position: UDim2,
	anchorPoint: Vector2?,
	fillColor: Color3,
	backgroundColor: Color3,
	innerColor: Color3,
	thickness: number, -- 0 to 1, fraction of radius
	parent: GuiObject,
}

export type CircularRing = typeof(setmetatable({} :: {
	container: Frame,
	leftFill: Frame,
	rightFill: Frame,
	innerCircle: Frame,
	label: TextLabel,
	fillColor: Color3,
	percentage: number,
}, CircularRing))

local function createCircle(name: string, size: UDim2, position: UDim2, color: Color3, parent: GuiObject): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame

	return frame
end

function CircularRing.new(config: Config): CircularRing
	local self = setmetatable({}, CircularRing)
	self.fillColor = config.fillColor
	self.percentage = 0

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "CircularRing"
	container.Size = config.size
	container.Position = config.position
	container.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = config.parent
	self.container = container

	-- Background circle (the track)
	createCircle(
		"Background",
		UDim2.fromScale(1, 1),
		UDim2.fromScale(0.5, 0.5),
		config.backgroundColor,
		container
	)

	-- Right clip (right half of container)
	local rightClip = Instance.new("Frame")
	rightClip.Name = "RightClip"
	rightClip.Size = UDim2.fromScale(0.5, 1)
	rightClip.Position = UDim2.fromScale(0.5, 0)
	rightClip.BackgroundTransparency = 1
	rightClip.BorderSizePixel = 0
	rightClip.ClipsDescendants = true
	rightClip.Parent = container

	-- Right fill (full circle, pivots from center of container)
	local rightFill = createCircle(
		"RightFill",
		UDim2.fromScale(2, 1), -- Full width of container (2x clip width)
		UDim2.new(0, 0, 0.5, 0), -- Center-left of clip = center of container
		config.fillColor,
		rightClip
	)
	rightFill.AnchorPoint = Vector2.new(0.5, 0.5)
	rightFill.Position = UDim2.fromScale(0, 0.5)
	rightFill.Rotation = 180 -- Hidden initially
	self.rightFill = rightFill

	-- Left clip (left half of container)
	local leftClip = Instance.new("Frame")
	leftClip.Name = "LeftClip"
	leftClip.Size = UDim2.fromScale(0.5, 1)
	leftClip.Position = UDim2.fromScale(0, 0)
	leftClip.BackgroundTransparency = 1
	leftClip.BorderSizePixel = 0
	leftClip.ClipsDescendants = true
	leftClip.Parent = container

	-- Left fill (full circle)
	local leftFill = createCircle(
		"LeftFill",
		UDim2.fromScale(2, 1),
		UDim2.new(1, 0, 0.5, 0),
		config.fillColor,
		leftClip
	)
	leftFill.AnchorPoint = Vector2.new(0.5, 0.5)
	leftFill.Position = UDim2.fromScale(1, 0.5)
	leftFill.Rotation = 180 -- Hidden initially
	self.leftFill = leftFill

	-- Inner circle (donut hole)
	local innerSize = 1 - config.thickness * 2
	local innerCircle = createCircle(
		"InnerCircle",
		UDim2.fromScale(innerSize, innerSize),
		UDim2.fromScale(0.5, 0.5),
		config.innerColor,
		container
	)
	innerCircle.ZIndex = 2
	self.innerCircle = innerCircle

	-- Label in center
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(0.6, 0.3)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "100%"
	label.ZIndex = 3
	label.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.5
	stroke.Parent = label

	self.label = label

	return self
end

function CircularRing.SetPercentage(self: CircularRing, pct: number)
	pct = math.clamp(pct, 0, 100)
	self.percentage = pct

	if pct <= 50 then
		-- Only right side fills (0 to 180 degrees)
		self.rightFill.Rotation = 180 + (pct / 50) * 180
		self.leftFill.Rotation = 180
	else
		-- Right side full, left side fills
		self.rightFill.Rotation = 360
		self.leftFill.Rotation = 180 + ((pct - 50) / 50) * 180
	end

	self.label.Text = math.floor(pct) .. "%"
end

function CircularRing.SetFillColor(self: CircularRing, color: Color3)
	self.fillColor = color
	self.rightFill.BackgroundColor3 = color
	self.leftFill.BackgroundColor3 = color
end

function CircularRing.SetVisible(self: CircularRing, visible: boolean)
	self.container.Visible = visible
end

function CircularRing.SetLabelText(self: CircularRing, text: string)
	self.label.Text = text
end

function CircularRing.Destroy(self: CircularRing)
	self.container:Destroy()
end

return CircularRing
