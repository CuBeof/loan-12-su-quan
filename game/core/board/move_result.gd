class_name MoveResult
extends RefCounted
## Outcome of one attempted move: ordered events for the view plus
## aggregated numbers for the battle layer.

const MAX_EXTRA_TURNS := 2 # SPEC: at most +2 extra turns from one move

var valid: bool = false
var events: Array[BoardEvent] = []
var cleared_counts: Dictionary = {} # TileTypes.Type -> int (already x enhanced x combo)
var extra_turns: int = 0
var max_combo: int = 1
# SPEC rule: a rejected swap counts as the opponent attacking with damage
# equivalent to this many attack tiles. The battle layer converts it.
var penalty_attack_tiles: int = 0


func add(kind: int, data: Dictionary = {}) -> void:
	events.append(BoardEvent.make(kind, data))


func tally(type: int, amount: int = 1) -> void:
	cleared_counts[type] = int(cleared_counts.get(type, 0)) + amount


## A match-4 or match-5 grants one extra turn, capped per move.
func grant_extra_turn() -> void:
	extra_turns = mini(extra_turns + 1, MAX_EXTRA_TURNS)


func total_cleared() -> int:
	var total := 0
	for type: int in cleared_counts:
		total += int(cleared_counts[type])
	return total
