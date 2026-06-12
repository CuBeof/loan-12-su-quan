class_name MatchFinder
extends RefCounted
## Scans a grid (Dictionary[Vector2i, TileState]) for matches and decides
## which special tile each match group should produce.
## TRANSFORM tiles never take part in normal matches.


class Run:
	extends RefCounted
	var cells: Array[Vector2i] = []
	var horizontal: bool = false


class MatchGroup:
	extends RefCounted
	var cells: Array[Vector2i] = []
	var type: int = 0
	var special: int = TileTypes.Special.NONE
	var special_cell: Vector2i = Vector2i(-1, -1)
	var max_run: int = 0
	var has_intersection: bool = false


static func find_groups(grid: Dictionary, preferred: Array[Vector2i] = []) -> Array:
	var runs := _find_runs(grid)
	var groups := _merge_runs(runs)
	var result: Array = []
	for raw: Dictionary in groups:
		result.append(_build_group(grid, raw, preferred))
	return result


static func _matchable(grid: Dictionary, cell: Vector2i) -> TileState:
	var tile: TileState = grid.get(cell)
	if tile == null or tile.special == TileTypes.Special.TRANSFORM:
		return null
	return tile


static func _find_runs(grid: Dictionary) -> Array:
	var runs: Array = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		var tile := _matchable(grid, cell)
		if tile == null:
			continue
		for dir in directions:
			var prev := _matchable(grid, cell - dir)
			if prev != null and prev.type == tile.type:
				continue # not the start of a run
			var run_cells: Array[Vector2i] = [cell]
			var next := cell + dir
			while true:
				var next_tile := _matchable(grid, next)
				if next_tile == null or next_tile.type != tile.type:
					break
				run_cells.append(next)
				next += dir
			if run_cells.size() >= 3:
				var run := Run.new()
				run.cells = run_cells
				run.horizontal = dir == Vector2i.RIGHT
				runs.append(run)
	return runs


## Merges runs that share at least one cell into groups (L/T shapes).
static func _merge_runs(runs: Array) -> Array:
	var groups: Array = [] # each: {cell_set: Dictionary, runs: Array}
	for run: Run in runs:
		var touching: Array = []
		for group: Dictionary in groups:
			for cell in run.cells:
				if group.cell_set.has(cell):
					touching.append(group)
					break
		var merged := {"cell_set": {}, "runs": []}
		for cell in run.cells:
			merged.cell_set[cell] = true
		merged.runs.append(run)
		for group: Dictionary in touching:
			groups.erase(group)
			merged.cell_set.merge(group.cell_set)
			merged.runs.append_array(group.runs)
		groups.append(merged)
	return groups


static func _build_group(grid: Dictionary, raw: Dictionary, preferred: Array[Vector2i]) -> MatchGroup:
	var group := MatchGroup.new()
	for cell: Vector2i in raw.cell_set.keys():
		group.cells.append(cell)
	var first_run: Run = raw.runs[0]
	var first_tile: TileState = grid[first_run.cells[0]]
	group.type = first_tile.type

	var has_h := false
	var has_v := false
	var longest: Run = first_run
	for run: Run in raw.runs:
		group.max_run = maxi(group.max_run, run.cells.size())
		if run.cells.size() > longest.cells.size():
			longest = run
		if run.horizontal:
			has_h = true
		else:
			has_v = true
	group.has_intersection = has_h and has_v

	if group.max_run >= 5:
		group.special = TileTypes.Special.TRANSFORM
	elif group.has_intersection:
		group.special = TileTypes.Special.BOMB
	elif group.max_run == 4:
		# Candy-Crush convention: horizontal match-4 sweeps the column, vertical sweeps the row.
		group.special = TileTypes.Special.SWEEP_V if longest.horizontal else TileTypes.Special.SWEEP_H

	if group.special != TileTypes.Special.NONE:
		group.special_cell = _pick_special_cell(raw, longest, preferred)
	return group


static func _pick_special_cell(raw: Dictionary, longest: Run, preferred: Array[Vector2i]) -> Vector2i:
	for cell in preferred:
		if raw.cell_set.has(cell):
			return cell
	# For L/T shapes prefer the intersection cell.
	if raw.runs.size() > 1:
		var seen := {}
		for run: Run in raw.runs:
			for cell in run.cells:
				if seen.has(cell):
					return cell
				seen[cell] = true
	return longest.cells[longest.cells.size() / 2]
