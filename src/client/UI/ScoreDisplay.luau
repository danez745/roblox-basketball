local ScoreDisplay = {}

local label: TextLabel = nil

function ScoreDisplay.Create(parent: GuiObject)
	label = Instance.new("TextLabel")
	label.Name = "ScoreDisplay"
	label.Size = UDim2.new(0.3, 0, 0.06, 0)
	label.Position = UDim2.new(0.5, 0, 0.03, 0)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "Score: 0"
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 200, 0)
	stroke.Parent = label

	return label
end

function ScoreDisplay.UpdateScore(player: Player, score: number)
	if not label then return end
	label.Text = player.Name .. ": " .. tostring(score)
end

return ScoreDisplay
