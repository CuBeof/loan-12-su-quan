class_name BoardLogic
extends RefCounted
## The whole match-3 board as pure logic: grid state, move validation,
## match resolution, gravity and refill. No nodes, no assets — testable
## headless and simulatable by the AI.
##
## Match rules (per design):
##   match-4        -> +1 extra turn
##   match-5+       -> +1 extra turn + destroy 3 random tiles anywhere
##   L/T shape      -> destroy 3 random tiles around the match center
## Enhanced tiles (random spawn) count double when cleared. Each cascade
## wave after a refill raises the combo, and a wave's cleared value is
## multiplied by its combo. Extra turns are capped per move (MoveResult).

const MAX_CASCADES := 50
const INVALID_SWAP_PENALTY_ATTACK_TILES := 2 # rejected swap = enemy attack
const DESTROY_COUNT := 3 # tiles destroyed by match-5 / L-T
const AROUND_RADIUS := 2 # L/T destroys within this Chebyshev radius of center

var size: Vector2i = Vector2i(8, 8)
var valid_cells: Array[Vector2i] = [] # board shape (holes excluded), ordered y then x
var grid: Dictionary = {} # Vector2i -> TileState
var rng := RandomNumberGenerator.new()
var refill_enabled: bool = true # tests disable to keep boards deterministic
# Set by the battle layer each turn (EnhancedRate); 0 = no enhanced gems.
var enhanced_chance: float = 0.0 # per-spawn chance a refilled gem is enhanced
var match_enhance_chance: float = 0.0 # chance to upgrade one matched tile


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

	_swap_tiles(a, b)
	var groups := MatchFinder.find_groups(grid)
	if groups.is_empty():
		_swap_tiles(a, b)
		result.add(BoardEvent.Kind.SWAP, {"a": a, "b": b})
		result.add(BoardEvent.Kind.SWAP_REJECTED, {"a": a, "b": b})
		result.penalty_attack_tiles = INVALID_SWAP_PENALTY_ATTACK_TILES
		return result

	result.valid = true
	result.add(BoardEvent.Kind.SWAP, {"a": a, "b": b})
	_resolve(result, groups)
	_ensure_moves(result)
	return result


## Resolves the first match and every cascade, raising the combo each wave.
func _resolve(result: MoveResult, first_groups: Array) -> void:
	var combo := 0
	var groups := first_groups
	var guard := 0
	while not groups.is_empty() and guard < MAX_CASCADES:
		guard += 1
		combo += 1
		result.max_combo = maxi(result.max_combo, combo)
		_resolve_wave(groups, combo, result)
		apply_gravity(result)
		groups = MatchFinder.find_groups(grid)


## Clears one wave of matches, applies the per-match effects (extra turn,
## random destruction) and tallies cleared value (enhanced x2, x combo).
func _resolve_wave(groups: Array, combo: int, result: MoveResult) -> void:
	var to_clear := {} # Vector2i -> true
	var lightning: Array[Vector2i] = []
	var upgraded: Array[Vector2i] = []
	var grants_extra := false

	for group: MatchFinder.MatchGroup in groups:
		# Small chance to upgrade one matched tile to enhanced right before it
		# clears, so that match counts double for it.
		if match_enhance_chance > 0.0 and rng.randf() < match_enhance_chance:
			var cell: Vector2i = group.cells[rng.randi_range(0, group.cells.size() - 1)]
			grid[cell].enhanced = true
			upgraded.append(cell)
		for cell in group.cells:
			to_clear[cell] = true
		if group.has_intersection:
			# L/T: destroy 3 random tiles around the junction.
			for cell in _random_cells_around(group.center, DESTROY_COUNT, to_clear):
				to_clear[cell] = true
				lightning.append(cell)
		elif group.max_run >= 5:
			# Match-5+: extra turn AND destroy 3 random tiles anywhere.
			grants_extra = true
			for cell in _random_cells_anywhere(DESTROY_COUNT, to_clear):
				to_clear[cell] = true
				lightning.append(cell)
		elif group.max_run == 4:
			grants_extra = true

	if grants_extra:
		result.grant_extra_turn()

	var counts := {}
	var cleared: Array[Vector2i] = []
	for cell: Vector2i in to_clear.keys():
		var tile: TileState = grid[cell]
		var amount := tile.value() * combo
		result.tally(tile.type, amount)
		counts[tile.type] = int(counts.get(tile.type, 0)) + amount
		cleared.append(cell)
		grid.erase(cell)
	result.add(BoardEvent.Kind.CLEARED, {
		"cells": cleared,
		"counts": counts,
		"combo": combo,
		"lightning": lightning,
		"upgraded": upgraded,
		"extra_turn": grants_extra,
	})


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
				var enhanced := rng.randf() < enhanced_chance
				var tile := TileState.make(rng.randi_range(0, TileTypes.TYPE_COUNT - 1), enhanced)
				grid[cell] = tile
				spawns.append({"cell": cell, "type": tile.type, "enhanced": tile.enhanced})
	if not falls.is_empty() or not spawns.is_empty():
		result.add(BoardEvent.Kind.GRAVITY, {"falls": falls, "spawns": spawns})


## Destroys arbitrary cells (skill blasts) and settles the board. The
## caller decides what the cleared counts are worth.
func blast_cells(cells: Array[Vector2i]) -> MoveResult:
	var result := MoveResult.new()
	var present: Array[Vector2i] = []
	for cell in cells:
		if grid.has(cell):
			present.append(cell)
	if present.is_empty():
		return result
	result.valid = true
	var counts := {}
	for cell in present:
		var tile: TileState = grid[cell]
		result.tally(tile.type, tile.value())
		counts[tile.type] = int(counts.get(tile.type, 0)) + tile.value()
		grid.erase(cell)
	result.add(BoardEvent.Kind.CLEARED, {
		"cells": present, "counts": counts, "combo": 1, "lightning": [], "extra_turn": false})
	apply_gravity(result)
	var groups := MatchFinder.find_groups(grid)
	if not groups.is_empty():
		_resolve(result, groups)
	_ensure_moves(result)
	return result


## Returns a hint {a, b, cells} highlighting the two tiles to swap, or {}
## only on a dead board (kept solvable by reshuffling). Returns the FIRST
## legal move — the hint exists to unstick the player, not to play for them.
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
		layout[cell] = {"type": tile.type, "enhanced": tile.enhanced}
	return layout


## Deep copy for AI lookahead: the AI simulates try_move() on a clone so
## the real board (and its RNG) is untouched.
func clone() -> BoardLogic:
	var copy := BoardLogic.new()
	copy.size = size
	copy.valid_cells = valid_cells.duplicate()
	copy.refill_enabled = refill_enabled
	copy.enhanced_chance = enhanced_chance
	copy.match_enhance_chance = match_enhance_chance
	copy.rng = RandomNumberGenerator.new()
	copy.rng.seed = rng.seed
	copy.rng.state = rng.state
	for cell: Vector2i in grid:
		copy.grid[cell] = grid[cell].clone()
	return copy


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return d.x + d.y == 1


func _swap_tiles(a: Vector2i, b: Vector2i) -> void:
	var tmp: TileState = grid[a]
	grid[a] = grid[b]
	grid[b] = tmp


## Picks up to `count` random occupied cells within AROUND_RADIUS of center
## that are not already marked, for an L/T strike.
func _random_cells_around(center: Vector2i, count: int, exclude: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in grid.keys():
		if exclude.has(cell):
			continue
		if absi(cell.x - center.x) <= AROUND_RADIUS and absi(cell.y - center.y) <= AROUND_RADIUS:
			candidates.append(cell)
	return _pick_random(candidates, count)


## Picks up to `count` random occupied cells anywhere not already marked.
func _random_cells_anywhere(count: int, exclude: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in grid.keys():
		if not exclude.has(cell):
			candidates.append(cell)
	return _pick_random(candidates, count)


func _pick_random(candidates: Array[Vector2i], count: int) -> Array[Vector2i]:
	var picked: Array[Vector2i] = []
	var pool := candidates.duplicate()
	for i in range(mini(count, pool.size())):
		var index := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)
	return picked


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
		var enhanced := rng.randf() < enhanced_chance
		grid[cell] = TileState.make(_random_type_excluding(banned), enhanced)


func _random_type_excluding(banned: Dictionary) -> int:
	var candidates: Array[int] = []
	for type in range(TileTypes.TYPE_COUNT):
		if not banned.has(type):
			candidates.append(type)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Reshuffles tiles when no move is left.
func _ensure_moves(result: MoveResult) -> void:
	if MoveGenerator.has_move(grid):
		return
	for attempt in range(100):
		_shuffle_all()
		if MatchFinder.find_groups(grid).is_empty() and MoveGenerator.has_move(grid):
			break
	result.add(BoardEvent.Kind.SHUFFLED, {"layout": snapshot()})


func _shuffle_all() -> void:
	var cells: Array[Vector2i] = []
	var types: Array[int] = []
	for cell: Vector2i in grid.keys():
		cells.append(cell)
		types.append(grid[cell].type)
	for i in range(types.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := types[i]
		types[i] = types[j]
		types[j] = tmp
	for i in range(cells.size()):
		grid[cells[i]].type = types[i]
