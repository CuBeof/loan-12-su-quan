class_name BoardEvent
extends RefCounted
## One step of a move resolution, in playback order. The view replays
## these sequentially to animate; tests assert on them directly.

enum Kind {
	SWAP, # data: a, b (Vector2i)
	SWAP_REJECTED, # data: a, b — view swaps back
	BOMB_PRIMED, # data: cells — bombs that blasted once and await their second blast
	CLEARED, # data: cells (Array[Vector2i]), counts (type -> int)
	SPECIAL_CREATED, # data: cell, type, special
	TRANSFORMED, # data: changes (Array of {cell, special})
	GRAVITY, # data: falls (Array of {from, to}), spawns (Array of {cell, type, special})
	SHUFFLED, # data: layout (cell -> {type, special})
}

var kind: int
var data: Dictionary


static func make(kind_: int, data_: Dictionary = {}) -> BoardEvent:
	var event := BoardEvent.new()
	event.kind = kind_
	event.data = data_
	return event
