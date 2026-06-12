class_name SpecialResolver
extends RefCounted
## Expands a set of cells to clear by chain-activating special tiles,
## following Candy Crush rules:
## - Sweepers clear their whole row/column.
## - Bombs blast 3x3 but SURVIVE the first activation (primed): they fall
##   with gravity and detonate again where they land. A bomb that is
##   already detonating gets cleared together with its second 3x3 blast.
## - A transform tile caught in a blast activates passively, consuming
##   every tile of one random type.
## Returns {"cleared": Array[Vector2i], "primed": Array[Vector2i]}.


static func expand_clears(grid: Dictionary, initial: Array[Vector2i], rng: RandomNumberGenerator) -> Dictionary:
	var cleared := {}
	var primed := {}
	var queue: Array[Vector2i] = initial.duplicate()
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if cleared.has(cell) or primed.has(cell) or not grid.has(cell):
			continue
		var tile: TileState = grid[cell]
		match tile.special:
			TileTypes.Special.SWEEP_H:
				cleared[cell] = true
				for other: Vector2i in grid.keys():
					if other.y == cell.y:
						queue.append(other)
			TileTypes.Special.SWEEP_V:
				cleared[cell] = true
				for other: Vector2i in grid.keys():
					if other.x == cell.x:
						queue.append(other)
			TileTypes.Special.BOMB:
				if tile.detonating:
					cleared[cell] = true
				else:
					tile.detonating = true
					primed[cell] = true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx != 0 or dy != 0:
							queue.append(cell + Vector2i(dx, dy))
			TileTypes.Special.TRANSFORM:
				cleared[cell] = true
				var target_type := rng.randi_range(0, TileTypes.TYPE_COUNT - 1)
				for other: Vector2i in grid.keys():
					var other_tile: TileState = grid[other]
					if other_tile.type == target_type and other_tile.special != TileTypes.Special.TRANSFORM:
						queue.append(other)
			_:
				cleared[cell] = true

	var cleared_list: Array[Vector2i] = []
	for cell: Vector2i in cleared.keys():
		cleared_list.append(cell)
	var primed_list: Array[Vector2i] = []
	for cell: Vector2i in primed.keys():
		primed_list.append(cell)
	return {"cleared": cleared_list, "primed": primed_list}
