local RemoteSetup = require(script.RemoteSetup)
local HoopBuilder = require(script.HoopBuilder)
local BallManager = require(script.BallManager)
local ScoreDetector = require(script.ScoreDetector)

-- 1. Create remote events first
RemoteSetup.Setup()

-- 2. Build the hoop
local hoop = HoopBuilder.Build()

-- 3. Initialize ball manager
BallManager.Init()

-- 4. Wire up score detection
ScoreDetector.Init(hoop, BallManager)

print("[Server] Basketball server initialized!")
