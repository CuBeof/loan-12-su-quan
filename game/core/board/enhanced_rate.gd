class_name EnhancedRate
extends RefCounted
## Pure helper for enhanced-gem chances. Spawn chance is zero until a
## warm-up number of total moves has passed, then grows with the move
## count and the mover's luck (capped). A separate, smaller chance upgrades
## one matched tile to enhanced right before it clears. All constants are
## balance knobs; the battle layer feeds in (total_moves, luck).

const WARMUP_MOVES := 4 # no enhanced gems before this many total moves
const SPAWN_BASE := 0.04 # spawn chance right after warm-up
const SPAWN_PER_MOVE := 0.004 # +per move beyond the warm-up
const SPAWN_PER_LUCK := 0.005 # +per luck point
const SPAWN_MAX := 0.30

const MATCH_BASE := 0.03 # chance to upgrade one matched tile
const MATCH_PER_LUCK := 0.004
const MATCH_MAX := 0.20


static func spawn_chance(total_moves: int, luck: int) -> float:
	if total_moves < WARMUP_MOVES:
		return 0.0
	var chance := SPAWN_BASE + SPAWN_PER_MOVE * (total_moves - WARMUP_MOVES) + SPAWN_PER_LUCK * luck
	return clampf(chance, 0.0, SPAWN_MAX)


static func match_chance(luck: int) -> float:
	return clampf(MATCH_BASE + MATCH_PER_LUCK * luck, 0.0, MATCH_MAX)
