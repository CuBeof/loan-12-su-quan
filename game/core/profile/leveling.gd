class_name Leveling
extends RefCounted
## XP curve and level-up processing. profile.xp is progress toward the
## NEXT level; crossing the threshold spends it, raises the level and
## grants skill points. Curve follows base * growth^(level-1) per the
## RPG-stats guidance.

const BASE_XP := 50
const GROWTH := 1.4
const SKILL_POINTS_PER_LEVEL := 1


## XP needed to advance from `level` to the next one.
static func xp_to_next(level: int) -> int:
	return int(round(BASE_XP * pow(GROWTH, maxi(level - 1, 0))))


## Consumes banked XP into levels + skill points. Returns levels gained.
static func apply_xp(profile: PlayerProfile) -> int:
	var gained := 0
	while profile.xp >= xp_to_next(profile.level) and gained < 100:
		profile.xp -= xp_to_next(profile.level)
		profile.level += 1
		profile.skill_points += SKILL_POINTS_PER_LEVEL
		gained += 1
	return gained
