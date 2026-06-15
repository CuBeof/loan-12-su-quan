class_name TileState
extends RefCounted
## Logical state of a single tile. No visuals, no node. An "enhanced" tile
## is a random, more valuable gem (its match value counts double).

static var _next_id: int = 1

var id: int
var type: int
var enhanced: bool = false


static func make(type_: int, enhanced_: bool = false) -> TileState:
	var tile := TileState.new()
	tile.id = _next_id
	_next_id += 1
	tile.type = type_
	tile.enhanced = enhanced_
	return tile


## How many "tiles" this counts as when cleared (enhanced = double).
func value() -> int:
	return 2 if enhanced else 1


## Field-for-field copy (keeps id) for board cloning during AI simulation.
func clone() -> TileState:
	var tile := TileState.new()
	tile.id = id
	tile.type = type
	tile.enhanced = enhanced
	return tile
