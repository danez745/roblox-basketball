local UserInputService = game:GetService("UserInputService")

local InputController = {}

-- Callbacks
local callbacks = {
	onPickupDrop = nil :: (() -> ())?,
	onShootStart = nil :: (() -> ())?,
	onShootRelease = nil :: (() -> ())?,
	onPass = nil :: (() -> ())?,
	onSprintStart = nil :: (() -> ())?,
	onSprintEnd = nil :: (() -> ())?,
}

function InputController.Init(cbs: {
	onPickupDrop: () -> (),
	onShootStart: () -> (),
	onShootRelease: () -> (),
	onPass: () -> (),
	onSprintStart: () -> (),
	onSprintEnd: () -> (),
})
	callbacks = cbs

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.E then
			if callbacks.onPickupDrop then
				callbacks.onPickupDrop()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if callbacks.onShootStart then
				callbacks.onShootStart()
			end
		elseif input.KeyCode == Enum.KeyCode.F then
			if callbacks.onPass then
				callbacks.onPass()
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			if callbacks.onSprintStart then
				callbacks.onSprintStart()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, _gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if callbacks.onShootRelease then
				callbacks.onShootRelease()
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			if callbacks.onSprintEnd then
				callbacks.onSprintEnd()
			end
		end
	end)
end

return InputController
