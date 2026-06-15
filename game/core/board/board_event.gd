class_name BoardEvent
extends RefCounted
## One step of a move resolution, in playback order. The view replays
## these sequentially to animate; tests assert on them directly.

enum Kind {
	SWAP, # data: a, b (Vector2i)
	SWAP_REJECTED, # data: a, b — view swaps back
	CLEARED, # data: cells, counts, combo, lightning (Array[Vector2i]), extra_turn (bool)
	GRAVITY, # data: falls (Array of {from, to}), spawns (Array of {cell, type, enhanced})
	SHUFFLED, # data: layout (cell -> {type, enhanced})
}

var kind: int
var data: Dictionary


static func make(kind_: int, data_: Dictionary = {}) -> BoardEvent:
	var event := BoardEvent.new()
	event.kind = kind_
	event.data = data_
	return event
