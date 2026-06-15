class_name MatchFinder
extends RefCounted
## Scans a grid (Dictionary[Vector2i, TileState]) for matches. Reports each
## match group's cells, its longest run length and whether it forms an L/T
## (an intersection of a horizontal and a vertical run). Every tile matches
## by type — there are no non-matchable special tiles.


class Run:
	extends RefCounted
	var cells: Array[Vector2i] = []
	var horizontal: bool = false


class MatchGroup:
	extends RefCounted
	var cells: Array[Vector2i] = []
	var type: int = 0
	var max_run: int = 0
	var has_intersection: bool = false
	var center: Vector2i = Vector2i.ZERO # the L/T junction, or the longest run's middle


static func find_groups(grid: Dictionary, _preferred: Array[Vector2i] = []) -> Array:
	var runs := _find_runs(grid)
	var merged := _merge_runs(runs)
	var result: Array = []
	for raw: Dictionary in merged:
		result.append(_build_group(grid, raw))
	return result


static func _find_runs(grid: Dictionary) -> Array:
	var runs: Array = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for cell: Vector2i in grid.keys():
		var tile: TileState = grid[cell]
		for dir in directions:
			var prev: TileState = grid.get(cell - dir)
			if prev != null and prev.type == tile.type:
				continue # not the start of a run
			var run_cells: Array[Vector2i] = [cell]
			var next := cell + dir
			while true:
				var next_tile: TileState = grid.get(next)
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


static func _build_group(grid: Dictionary, raw: Dictionary) -> MatchGroup:
	var group := MatchGroup.new()
	for cell: Vector2i in raw.cell_set.keys():
		group.cells.append(cell)
	var first_run: Run = raw.runs[0]
	group.type = grid[first_run.cells[0]].type

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
	group.center = _pick_center(raw, longest)
	return group


static func _pick_center(raw: Dictionary, longest: Run) -> Vector2i:
	# For L/T shapes the intersection cell (shared by two runs) is the center.
	if raw.runs.size() > 1:
		var seen := {}
		for run: Run in raw.runs:
			for cell in run.cells:
				if seen.has(cell):
					return cell
				seen[cell] = true
	return longest.cells[longest.cells.size() / 2]
