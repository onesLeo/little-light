extends RefCounted
## Shared small conversation poses for the Chapter 2 camp scene.
## Kept as pure functions so Jonathan's rig and David's rigless model move with
## the same rhythm without making either character copy the other's geometry.


static func speaking_pulse(time: float) -> float:
	return 0.5 + 0.5 * sin(time * 2.15)


static func listening_nod(time: float) -> float:
	return maxf(sin(time * 2.35), 0.0)


static func breath(time: float) -> float:
	return sin(time * 1.45)
