local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(Shared.RemoteNames)

local RemoteSetup = {}

function RemoteSetup.Setup()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	for _, name in RemoteNames do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
end

return RemoteSetup
