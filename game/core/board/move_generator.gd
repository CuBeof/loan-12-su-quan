class_name MoveGenerator
extends RefCounted
## Enumerates legal moves on a grid. Used to detect dead boards (reshuffle),
## the idle hint, and the AI. A move is legal if swapping two adjacent tiles
## creates at least one match.


static func find_moves(grid: Dictionary) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		for dir in directions:
			var other := cell + dir
			if not grid.has(other):
				continue
			if _swap_makes_match(grid, cell, other):
				moves.append({"a": cell, "b": other})
	return moves


## Returns the first legal move found, or {} if the board is dead. Cheaper
## than find_moves; used for dead-board checks and the idle hint.
static func find_first_move(grid: Dictionary) -> Dictionary:
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		for dir in directions:
			var other := cell + dir
			if grid.has(other) and _swap_makes_match(grid, cell, other):
				return {"a": cell, "b": other}
	return {}


static func has_move(grid: Dictionary) -> bool:
	return not find_first_move(grid).is_empty()


static func _swap_makes_match(grid: Dictionary, a: Vector2i, b: Vector2i) -> bool:
	var ta: TileState = grid[a]
	var tb: TileState = grid[b]
	grid[a] = tb
	grid[b] = ta
	var found := not MatchFinder.find_groups(grid).is_empty()
	grid[a] = ta
	grid[b] = tb
	return found
