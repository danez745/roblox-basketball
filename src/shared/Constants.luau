local Constants = {
	-- Ball physics
	BALL_SIZE = 1.8,
	BALL_DENSITY = 0.7,
	BALL_FRICTION = 0.3,
	BALL_ELASTICITY = 0.83,
	BALL_RESET_Y = -20,

	-- Pickup
	PICKUP_RANGE = 8,

	-- Shot power bar (timing / accuracy system)
	SHOT_OSCILLATION_SPEED = 0.8,  -- oscillations per second (marker bounces up/down)
	SWEET_SPOT_CENTER = 0.70,      -- sweet spot at 70% from bottom of bar
	SWEET_SPOT_WIDTH = 0.16,       -- green zone spans CENTER ± WIDTH/2  (62%–78%)

	-- Arc trajectory to ring
	RIM_FORWARD_OFFSET = 5.3,  -- studs forward from HOOP_POSITION.Z to rim center
	ARC_HEIGHT_BONUS = 6,      -- studs above the highest point on the arc
	MAX_ACCURACY_OFFSET = 6,   -- max random miss offset in studs at 0% accuracy

	-- Movement
	SPRINT_SPEED = 28,
	WALK_SPEED = 16,

	-- Stamina
	MAX_STAMINA = 100,
	STAMINA_DRAIN_RATE = 20,
	DRIBBLE_STAMINA_DRAIN = 5,
	STAMINA_REGEN_RATE = 15,

	-- Dribble animation
	DRIBBLE_SPEED = 6,
	DRIBBLE_HEIGHT = 2.5,

	-- Hoop
	HOOP_POSITION = Vector3.new(0, 0, -50),
	RIM_HEIGHT = 10,
	RIM_RADIUS = 1.8,

	-- Scoring
	SCORE_ZONE_TIMEOUT = 1.5,

	-- Pass
	PASS_POWER = 50,
	PASS_RANGE = 60,
}

table.freeze(Constants)
return Constants
