class_name TileState
extends RefCounted
## Logical state of a single tile on the board. No visuals, no node.

static var _next_id: int = 1

var id: int
var type: int
var special: int = TileTypes.Special.NONE


static func make(type_: int, special_: int = TileTypes.Special.NONE) -> TileState:
	var tile := TileState.new()
	tile.id = _next_id
	_next_id += 1
	tile.type = type_
	tile.special = special_
	return tile
