class_name MoveGenerator
extends RefCounted
## Enumerates every legal move on a grid. Used to detect dead boards
## (reshuffle) and later by the AI to evaluate candidate moves.


static func find_moves(grid: Dictionary) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		for dir in directions:
			var other := cell + dir
			if not grid.has(other):
				continue
			var tile_a: TileState = grid[cell]
			var tile_b: TileState = grid[other]
			if is_special_combo(tile_a, tile_b):
				moves.append({"a": cell, "b": other})
				continue
			grid[cell] = tile_b
			grid[other] = tile_a
			var found := not MatchFinder.find_groups(grid).is_empty()
			grid[cell] = tile_a
			grid[other] = tile_b
			if found:
				moves.append({"a": cell, "b": other})
	return moves


## Returns the first legal move found, or {} if the board is dead. Stops
## at the first hit, so it is far cheaper than find_moves() — used for the
## idle hint and for dead-board checks where only existence matters.
static func find_first_move(grid: Dictionary) -> Dictionary:
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		for dir in directions:
			var other := cell + dir
			if not grid.has(other):
				continue
			var tile_a: TileState = grid[cell]
			var tile_b: TileState = grid[other]
			if is_special_combo(tile_a, tile_b):
				return {"a": cell, "b": other}
			grid[cell] = tile_b
			grid[other] = tile_a
			var found := not MatchFinder.find_groups(grid).is_empty()
			grid[cell] = tile_a
			grid[other] = tile_b
			if found:
				return {"a": cell, "b": other}
	return {}


static func has_move(grid: Dictionary) -> bool:
	return not find_first_move(grid).is_empty()


static func is_special_combo(tile_a: TileState, tile_b: TileState) -> bool:
	if tile_a.special == TileTypes.Special.TRANSFORM or tile_b.special == TileTypes.Special.TRANSFORM:
		return true
	return tile_a.special != TileTypes.Special.NONE and tile_b.special != TileTypes.Special.NONE
