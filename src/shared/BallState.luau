local BallState = {
	Free = "Free",
	Held = "Held",
	Shot = "Shot",
	Passed = "Passed",
}

table.freeze(BallState)
return BallState
