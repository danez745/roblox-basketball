local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local HoopBuilder = {}

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, props: {[string]: any}?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if props then
		for k, v in props do
			(part :: any)[k] = v
		end
	end

	return part
end

function HoopBuilder.Build(): Model
	local hoopPos = Constants.HOOP_POSITION
	local rimHeight = Constants.RIM_HEIGHT
	local rimRadius = Constants.RIM_RADIUS

	local model = Instance.new("Model")
	model.Name = "Hoop"

	-- Pole
	local pole = makePart(
		"Pole",
		Vector3.new(0.5, rimHeight, 0.5),
		CFrame.new(hoopPos.X, rimHeight / 2, hoopPos.Z),
		Color3.fromRGB(120, 120, 120)
	)
	pole.Parent = model

	-- Horizontal arm extending forward from top of pole
	local arm = makePart(
		"Arm",
		Vector3.new(0.4, 0.4, 3),
		CFrame.new(hoopPos.X, rimHeight - 0.2, hoopPos.Z + 1.5),
		Color3.fromRGB(120, 120, 120)
	)
	arm.Parent = model

	-- Backboard
	local backboard = makePart(
		"Backboard",
		Vector3.new(6, 4, 0.3),
		CFrame.new(hoopPos.X, rimHeight + 0.5, hoopPos.Z + 3),
		Color3.fromRGB(255, 255, 255),
		{ Transparency = 0.3 }
	)
	backboard.Parent = model

	-- Rim ring (12 small parts arranged in circle)
	local rimCenter = Vector3.new(hoopPos.X, rimHeight, hoopPos.Z + 3 + rimRadius + 0.5)
	local segmentCount = 12

	for i = 1, segmentCount do
		local angle = (i / segmentCount) * math.pi * 2
		local nextAngle = ((i + 1) / segmentCount) * math.pi * 2
		local midAngle = (angle + nextAngle) / 2

		local x = rimCenter.X + math.cos(midAngle) * rimRadius
		local z = rimCenter.Z + math.sin(midAngle) * rimRadius

		local segLength = 2 * rimRadius * math.sin(math.pi / segmentCount)

		local rimSeg = makePart(
			"RimSeg" .. i,
			Vector3.new(segLength, 0.2, 0.2),
			CFrame.new(x, rimCenter.Y, z) * CFrame.Angles(0, -midAngle + math.pi / 2, 0),
			Color3.fromRGB(200, 80, 0)
		)
		rimSeg.Parent = model
	end

	-- Net (simplified as semi-transparent cylinder)
	local net = makePart(
		"Net",
		Vector3.new(rimRadius * 1.6, 2, rimRadius * 1.6),
		CFrame.new(rimCenter.X, rimHeight - 1.2, rimCenter.Z),
		Color3.fromRGB(255, 255, 255),
		{ Transparency = 0.6, Shape = Enum.PartType.Cylinder }
	)
	-- Rotate cylinder to stand upright
	net.CFrame = CFrame.new(rimCenter.X, rimHeight - 1.2, rimCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
	net.CanCollide = false
	net.Parent = model

	-- Scoring zones (invisible)
	local topZone = makePart(
		"TopZone",
		Vector3.new(rimRadius * 2, 0.3, rimRadius * 2),
		CFrame.new(rimCenter.X, rimHeight, rimCenter.Z),
		Color3.fromRGB(0, 255, 0),
		{ Transparency = 1, CanCollide = false }
	)
	topZone.Parent = model

	local bottomZone = makePart(
		"BottomZone",
		Vector3.new(rimRadius * 2, 0.3, rimRadius * 2),
		CFrame.new(rimCenter.X, rimHeight - 1.5, rimCenter.Z),
		Color3.fromRGB(255, 0, 0),
		{ Transparency = 1, CanCollide = false }
	)
	bottomZone.Parent = model

	model.PrimaryPart = pole
	model.Parent = workspace

	return model
end

return HoopBuilder
