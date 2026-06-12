class_name MoveResult
extends RefCounted
## Outcome of one attempted move: ordered events for the view plus
## aggregated numbers for the battle layer.

var valid: bool = false
var events: Array[BoardEvent] = []
var cleared_counts: Dictionary = {} # TileTypes.Type -> int
var extra_turn: bool = false
# SPEC rule: a rejected swap counts as the opponent attacking with damage
# equivalent to this many attack tiles. The battle layer converts it.
var penalty_attack_tiles: int = 0


func add(kind: int, data: Dictionary = {}) -> void:
	events.append(BoardEvent.make(kind, data))


func tally(type: int, amount: int = 1) -> void:
	cleared_counts[type] = int(cleared_counts.get(type, 0)) + amount


func total_cleared() -> int:
	var total := 0
	for type: int in cleared_counts:
		total += int(cleared_counts[type])
	return total
