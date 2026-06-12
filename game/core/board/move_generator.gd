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


static func is_special_combo(tile_a: TileState, tile_b: TileState) -> bool:
	if tile_a.special == TileTypes.Special.TRANSFORM or tile_b.special == TileTypes.Special.TRANSFORM:
		return true
	return tile_a.special != TileTypes.Special.NONE and tile_b.special != TileTypes.Special.NONE
