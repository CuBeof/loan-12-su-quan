class_name SpecialResolver
extends RefCounted
## Expands a set of cells to clear by chain-activating any special tiles
## caught in the blast (sweepers clear lines, bombs clear 3x3...).


static func expand_clears(grid: Dictionary, initial: Array[Vector2i]) -> Array[Vector2i]:
	var cleared := {}
	var queue: Array[Vector2i] = initial.duplicate()
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if cleared.has(cell) or not grid.has(cell):
			continue
		cleared[cell] = true
		var tile: TileState = grid[cell]
		match tile.special:
			TileTypes.Special.SWEEP_H:
				for other: Vector2i in grid.keys():
					if other.y == cell.y:
						queue.append(other)
			TileTypes.Special.SWEEP_V:
				for other: Vector2i in grid.keys():
					if other.x == cell.x:
						queue.append(other)
			TileTypes.Special.BOMB:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						queue.append(cell + Vector2i(dx, dy))
			# TRANSFORM cleared passively just disappears.
	var out: Array[Vector2i] = []
	for cell: Vector2i in cleared.keys():
		out.append(cell)
	return out
