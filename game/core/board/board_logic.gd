class_name BoardLogic
extends RefCounted
## The whole match-3 board as pure logic: grid state, move validation,
## match resolution, special-tile combos, gravity and refill.
## No nodes, no assets — testable headless and simulatable by the AI.

const MAX_CASCADES := 50
# SPEC: a rejected swap counts as an enemy attack worth this many attack tiles.
const INVALID_SWAP_PENALTY_ATTACK_TILES := 2

var size: Vector2i = Vector2i(8, 8)
var valid_cells: Array[Vector2i] = [] # board shape (holes excluded), ordered y then x
var grid: Dictionary = {} # Vector2i -> TileState
var rng := RandomNumberGenerator.new()
var refill_enabled: bool = true # tests disable to keep boards deterministic

var _pending_bombs: Array[TileState] = [] # primed bombs awaiting their second blast
var _pending_blasts: Array[Dictionary] = [] # delayed area blasts: {center, radius}


func init_shape(board_size: Vector2i, blocked: Array[Vector2i] = []) -> void:
	size = board_size
	valid_cells.clear()
	grid.clear()
	for y in range(size.y):
		for x in range(size.x):
			var cell := Vector2i(x, y)
			if not blocked.has(cell):
				valid_cells.append(cell)


func setup(board_size: Vector2i = Vector2i(8, 8), seed_value: int = 0, blocked: Array[Vector2i] = []) -> void:
	init_shape(board_size, blocked)
	rng.seed = seed_value
	_fill_no_match()
	var guard := 0
	while not MoveGenerator.has_move(grid) and guard < 100:
		_fill_no_match()
		guard += 1


func try_move(a: Vector2i, b: Vector2i) -> MoveResult:
	var result := MoveResult.new()
	if not grid.has(a) or not grid.has(b) or not _adjacent(a, b):
		return result

	var tile_a: TileState = grid[a]
	var tile_b: TileState = grid[b]
	if MoveGenerator.is_special_combo(tile_a, tile_b):
		result.valid = true
		result.add(BoardEvent.Kind.SWAP, {"a": a, "b": b})
		_execute_combo(a, b, result)
		_settle(result)
		_ensure_moves(result)
		return result

	_swap_tiles(a, b)
	var preferred: Array[Vector2i] = [b, a]
	var groups := MatchFinder.find_groups(grid, preferred)
	if groups.is_empty():
		_swap_tiles(a, b)
		result.add(BoardEvent.Kind.SWAP, {"a": a, "b": b})
		result.add(BoardEvent.Kind.SWAP_REJECTED, {"a": a, "b": b})
		result.penalty_attack_tiles = INVALID_SWAP_PENALTY_ATTACK_TILES
		return result

	result.valid = true
	result.add(BoardEvent.Kind.SWAP, {"a": a, "b": b})
	_clear_groups(groups, result)
	_settle(result)
	_ensure_moves(result)
	return result


## Gravity, delayed bomb blasts and cascade matches, until the board is stable.
func _settle(result: MoveResult) -> void:
	apply_gravity(result)
	var guard := 0
	while guard < MAX_CASCADES:
		guard += 1
		if not _pending_bombs.is_empty() or not _pending_blasts.is_empty():
			_detonate_pending(result)
			apply_gravity(result)
			continue
		var groups := MatchFinder.find_groups(grid)
		if groups.is_empty():
			break
		_clear_groups(groups, result)
		apply_gravity(result)


func apply_gravity(result: MoveResult) -> void:
	var falls: Array[Dictionary] = []
	var spawns: Array[Dictionary] = []
	for x in range(size.x):
		var column: Array[Vector2i] = []
		for cell in valid_cells:
			if cell.x == x:
				column.append(cell)
		column.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.y > q.y) # bottom first
		var write := 0
		for read in range(column.size()):
			var cell := column[read]
			if grid.has(cell):
				var target := column[write]
				if target != cell:
					grid[target] = grid[cell]
					grid.erase(cell)
					falls.append({"from": cell, "to": target})
				write += 1
		if refill_enabled:
			for i in range(write, column.size()):
				var cell := column[i]
				var tile := TileState.make(rng.randi_range(0, TileTypes.TYPE_COUNT - 1))
				grid[cell] = tile
				spawns.append({"cell": cell, "type": tile.type, "special": tile.special})
	if not falls.is_empty() or not spawns.is_empty():
		result.add(BoardEvent.Kind.GRAVITY, {"falls": falls, "spawns": spawns})


## Destroys arbitrary cells (skill blasts). Specials caught in the blast
## chain as usual; the board settles and reshuffles if needed. The caller
## decides what (if anything) the cleared counts are worth.
func blast_cells(cells: Array[Vector2i]) -> MoveResult:
	var result := MoveResult.new()
	var present: Array[Vector2i] = []
	for cell in cells:
		if grid.has(cell):
			present.append(cell)
	if present.is_empty():
		return result
	result.valid = true
	_clear_cells(present, result)
	_settle(result)
	_ensure_moves(result)
	return result


## Returns a hint {a, b, cells} highlighting just the two tiles to swap,
## or {} only in the impossible case of a dead board (the board is always
## kept solvable by reshuffling). It returns the FIRST available move, not
## the best one — the hint exists to unstick the player, not to play for
## them — which also keeps it cheap.
func find_hint() -> Dictionary:
	var move := MoveGenerator.find_first_move(grid)
	if move.is_empty():
		return {}
	var cells: Array[Vector2i] = [move.a, move.b]
	return {"a": move.a, "b": move.b, "cells": cells}


func snapshot() -> Dictionary:
	var layout := {}
	for cell: Vector2i in grid.keys():
		var tile: TileState = grid[cell]
		layout[cell] = {"type": tile.type, "special": tile.special}
	return layout


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return d.x + d.y == 1


func _swap_tiles(a: Vector2i, b: Vector2i) -> void:
	var tmp: TileState = grid[a]
	grid[a] = grid[b]
	grid[b] = tmp


## Second blasts of primed bombs (at their post-fall positions) and any
## queued delayed area blasts (bomb + bomb combo).
func _detonate_pending(result: MoveResult) -> void:
	var initial: Array[Vector2i] = []
	for tile in _pending_bombs:
		var cell := _find_tile_cell(tile)
		if cell.x >= 0:
			initial.append(cell)
	_pending_bombs.clear()
	for blast in _pending_blasts:
		var center: Vector2i = blast.center
		var radius: int = blast.radius
		for cell: Vector2i in grid.keys():
			if absi(cell.x - center.x) <= radius and absi(cell.y - center.y) <= radius:
				initial.append(cell)
	_pending_blasts.clear()
	if not initial.is_empty():
		_clear_cells(initial, result)


func _find_tile_cell(tile: TileState) -> Vector2i:
	for cell: Vector2i in grid.keys():
		if grid[cell] == tile:
			return cell
	return Vector2i(-1, -1)


func _clear_groups(groups: Array, result: MoveResult) -> void:
	var initial: Array[Vector2i] = []
	var specials: Array[Dictionary] = []
	for group: MatchFinder.MatchGroup in groups:
		if group.max_run > 3:
			result.extra_turn = true
		if group.special != TileTypes.Special.NONE:
			specials.append({
				"cell": group.special_cell,
				"type": group.type,
				"special": group.special,
				"cells": group.cells,
			})
		initial.append_array(group.cells)
	_clear_cells(initial, result)
	for entry in specials:
		var cell: Vector2i = entry.cell
		if grid.has(cell):
			# Occupied by a primed bomb that survived the clear: fall back
			# to another cell of the match that did get cleared.
			cell = Vector2i(-1, -1)
			for alt: Vector2i in entry.cells:
				if not grid.has(alt):
					cell = alt
					break
			if cell.x < 0:
				continue
		grid[cell] = TileState.make(entry.type, entry.special)
		result.add(BoardEvent.Kind.SPECIAL_CREATED, {"cell": cell, "type": entry.type, "special": entry.special})


func _clear_cells(initial: Array[Vector2i], result: MoveResult) -> void:
	var outcome := SpecialResolver.expand_clears(grid, initial, rng)
	var primed: Array[Vector2i] = outcome.primed
	if not primed.is_empty():
		for cell in primed:
			_pending_bombs.append(grid[cell])
		result.add(BoardEvent.Kind.BOMB_PRIMED, {"cells": primed})
	var cleared: Array[Vector2i] = outcome.cleared
	var counts := {}
	for cell in cleared:
		var tile: TileState = grid[cell]
		result.tally(tile.type)
		counts[tile.type] = int(counts.get(tile.type, 0)) + 1
		grid.erase(cell)
	result.add(BoardEvent.Kind.CLEARED, {"cells": cleared, "counts": counts})


## Swap combos between special tiles (and TRANSFORM with anything).
## The grid is intentionally NOT swapped: every combo consumes both cells,
## so the visual swap the view plays stays consistent.
func _execute_combo(a: Vector2i, b: Vector2i, result: MoveResult) -> void:
	var tile_a: TileState = grid[a]
	var tile_b: TileState = grid[b]
	var sweeps: Array[int] = [TileTypes.Special.SWEEP_H, TileTypes.Special.SWEEP_V]

	if tile_a.special == TileTypes.Special.TRANSFORM or tile_b.special == TileTypes.Special.TRANSFORM:
		var t_cell := a if tile_a.special == TileTypes.Special.TRANSFORM else b
		var o_cell := b if t_cell == a else a
		var other: TileState = grid[o_cell]
		# The transform tile is consumed by the combo itself; neutralize it
		# so expand_clears doesn't trigger a passive random-type zap on top.
		var t_tile: TileState = grid[t_cell]
		t_tile.special = TileTypes.Special.NONE
		match other.special:
			TileTypes.Special.TRANSFORM:
				# Candy Crush: color bomb + color bomb clears the whole board.
				other.special = TileTypes.Special.NONE
				var all_cells: Array[Vector2i] = []
				for cell: Vector2i in grid.keys():
					all_cells.append(cell)
				_clear_cells(all_cells, result)
			TileTypes.Special.NONE:
				var cells: Array[Vector2i] = [t_cell]
				for cell: Vector2i in grid.keys():
					var tile: TileState = grid[cell]
					if tile.type == other.type and tile.special != TileTypes.Special.TRANSFORM:
						cells.append(cell)
				_clear_cells(cells, result)
			_:
				# TRANSFORM + BOMB/SWEEP: convert all tiles of that type, then detonate.
				var changes: Array[Dictionary] = []
				var detonate: Array[Vector2i] = [t_cell, o_cell]
				for cell: Vector2i in grid.keys():
					var tile: TileState = grid[cell]
					if cell != o_cell and tile.type == other.type and tile.special == TileTypes.Special.NONE:
						var new_special := other.special
						if other.special in sweeps:
							new_special = sweeps[rng.randi_range(0, 1)] # random orientation per SPEC
						tile.special = new_special
						changes.append({"cell": cell, "special": new_special})
						detonate.append(cell)
				if not changes.is_empty():
					result.add(BoardEvent.Kind.TRANSFORMED, {"changes": changes})
				_clear_cells(detonate, result)
		return

	var both_bomb := tile_a.special == TileTypes.Special.BOMB and tile_b.special == TileTypes.Special.BOMB
	var both_sweep := tile_a.special in sweeps and tile_b.special in sweeps
	# Consume the source specials so expand_clears applies the combo area
	# instead of each tile's default activation.
	tile_a.special = TileTypes.Special.NONE
	tile_b.special = TileTypes.Special.NONE

	var cells: Array[Vector2i] = []
	if both_bomb:
		# Candy Crush: two big blasts (5x5, second one after refill);
		# SPEC adds the extra turn.
		result.extra_turn = true
		_pending_blasts.append({"center": b, "radius": 2})
		for cell: Vector2i in grid.keys():
			if absi(cell.x - b.x) <= 2 and absi(cell.y - b.y) <= 2:
				cells.append(cell)
	elif both_sweep:
		# Candy Crush: cross clear, one row + one column.
		for cell: Vector2i in grid.keys():
			if cell.y == b.y or cell.x == b.x:
				cells.append(cell)
	else:
		# Candy Crush: bomb + sweeper = giant cross, 3 rows + 3 columns.
		for cell: Vector2i in grid.keys():
			if absi(cell.y - b.y) <= 1 or absi(cell.x - b.x) <= 1:
				cells.append(cell)
	_clear_cells(cells, result)


func _fill_no_match() -> void:
	grid.clear()
	for cell in valid_cells:
		var banned := {}
		var left1: TileState = grid.get(cell + Vector2i.LEFT)
		var left2: TileState = grid.get(cell + Vector2i.LEFT * 2)
		if left1 != null and left2 != null and left1.type == left2.type:
			banned[left1.type] = true
		var up1: TileState = grid.get(cell + Vector2i.UP)
		var up2: TileState = grid.get(cell + Vector2i.UP * 2)
		if up1 != null and up2 != null and up1.type == up2.type:
			banned[up1.type] = true
		grid[cell] = TileState.make(_random_type_excluding(banned))


func _random_type_excluding(banned: Dictionary) -> int:
	var candidates: Array[int] = []
	for type in range(TileTypes.TYPE_COUNT):
		if not banned.has(type):
			candidates.append(type)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Reshuffles normal tiles when no move is left, keeping specials in place.
func _ensure_moves(result: MoveResult) -> void:
	if MoveGenerator.has_move(grid):
		return
	for attempt in range(100):
		_shuffle_normals()
		if MatchFinder.find_groups(grid).is_empty() and MoveGenerator.has_move(grid):
			break
	result.add(BoardEvent.Kind.SHUFFLED, {"layout": snapshot()})


func _shuffle_normals() -> void:
	var cells: Array[Vector2i] = []
	var types: Array[int] = []
	for cell: Vector2i in grid.keys():
		var tile: TileState = grid[cell]
		if tile.special == TileTypes.Special.NONE:
			cells.append(cell)
			types.append(tile.type)
	for i in range(types.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := types[i]
		types[i] = types[j]
		types[j] = tmp
	for i in range(cells.size()):
		var tile: TileState = grid[cells[i]]
		tile.type = types[i]
