class_name BoardView
extends Control
## Projection layer for BoardLogic: replays MoveResult events as tweened
## animations and translates touch input (swipe or tap-tap) into moves.
## Owns no game state beyond the visual tile map.

signal move_resolved(result: MoveResult)
signal move_rejected(result: MoveResult) # bounced swap; carries the attack penalty

const SWAP_TIME := 0.16
const CLEAR_TIME := 0.18
const FALL_TIME_PER_CELL := 0.06
const POP_TIME := 0.15
const SPAWN_STAGGER := 0.05 # raindrop delay between gems of one column
const BOUNCE_TIME := 0.09
const OVERSHOOT_FACTOR := 0.18 # how far past the target a gem falls before bouncing back

@export var catalog: TileCatalog
@export var rng_seed: int = 0 # 0 = random each run
@export var hint_delay: float = 5.0 # idle seconds before suggesting a move

var logic: BoardLogic
var input_enabled: bool = true: set = _set_input_enabled # disabled during the enemy turn

var _tiles: Dictionary = {} # Vector2i -> TileView
var _cell_px: float = 64.0
var _origin := Vector2.ZERO
var _busy: bool = false
var _selected := Vector2i(-1, -1)
var _touch_cell := Vector2i(-1, -1)
var _touch_start := Vector2.ZERO
var _dragging: bool = false
var _speed: float = 1.0 # effect-speed multiplier from Settings
var _hint_timer: Timer
var _hint_cells: Array[Vector2i] = []
var _hint_tween: Tween


func _ready() -> void:
	logic = BoardLogic.new()
	var seed_value := rng_seed if rng_seed != 0 else int(randi())
	logic.setup(Vector2i(8, 8), seed_value)
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	add_child(_hint_timer)
	_hint_timer.timeout.connect(_show_hint)
	_apply_settings()
	EventBus.settings_changed.connect(_apply_settings)
	resized.connect(_relayout)
	_relayout()
	_kick_idle()


## Scales an animation duration by the player's effect-speed setting.
func _dur(seconds: float) -> float:
	return seconds / _speed


func _apply_settings() -> void:
	hint_delay = Settings.hint_delay
	_speed = maxf(0.25, Settings.effect_speed)
	_kick_idle()


## Plays a move programmatically (enemy AI) through the same pipeline
## as player input, so animations and signals behave identically.
func play_move(a: Vector2i, b: Vector2i) -> void:
	_attempt_move(a, b)


func _gui_input(event: InputEvent) -> void:
	if _busy or not input_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var cell := _pos_to_cell(touch.position)
		if touch.pressed:
			_kick_idle() # any interaction resets the hint countdown
			if not logic.grid.has(cell):
				_set_selection(Vector2i(-1, -1))
				return
			_touch_cell = cell
			_touch_start = touch.position
			_dragging = true
		elif _dragging:
			_dragging = false
			_handle_tap(cell)
	elif event is InputEventScreenDrag and _dragging:
		var drag := event as InputEventScreenDrag
		var delta := drag.position - _touch_start
		if delta.length() >= _cell_px * 0.35:
			_dragging = false
			_set_selection(Vector2i(-1, -1))
			_attempt_move(_touch_cell, _touch_cell + _dominant_dir(delta))


func _handle_tap(cell: Vector2i) -> void:
	if cell != _touch_cell or not logic.grid.has(cell):
		_set_selection(Vector2i(-1, -1))
		return
	if _selected == Vector2i(-1, -1):
		_set_selection(cell)
	elif _selected == cell:
		_set_selection(Vector2i(-1, -1))
	elif (cell - _selected).abs().x + (cell - _selected).abs().y == 1:
		var from := _selected
		_set_selection(Vector2i(-1, -1))
		_attempt_move(from, cell)
	else:
		_set_selection(cell)


func _attempt_move(a: Vector2i, b: Vector2i) -> void:
	if _busy or not logic.grid.has(a) or not logic.grid.has(b):
		return
	var result := logic.try_move(a, b)
	if result.events.is_empty():
		return
	_busy = true
	_clear_hint()
	await _play_events(result.events)
	_busy = false
	if result.valid:
		move_resolved.emit(result)
	else:
		move_rejected.emit(result)
	_kick_idle()


# --- Idle hint system ---------------------------------------------------

func _set_input_enabled(value: bool) -> void:
	input_enabled = value
	if value:
		_kick_idle()
	else:
		_stop_idle()


## Restarts the idle countdown after clearing any visible hint.
func _kick_idle() -> void:
	_clear_hint()
	if _hint_timer != null and input_enabled and not _busy and logic != null:
		_hint_timer.start(maxf(1.0, hint_delay))


func _stop_idle() -> void:
	_clear_hint()
	if _hint_timer != null:
		_hint_timer.stop()


func _clear_hint() -> void:
	if _hint_tween != null:
		_hint_tween.kill()
		_hint_tween = null
	for cell in _hint_cells:
		var view: TileView = _tiles.get(cell)
		if view != null:
			view.scale = Vector2.ONE
	_hint_cells.clear()


func _show_hint() -> void:
	if _busy or not input_enabled or logic == null:
		return
	var hint := logic.find_hint()
	if hint.is_empty():
		return
	_hint_cells.clear()
	for cell: Vector2i in hint.cells:
		if _tiles.has(cell):
			_hint_cells.append(cell)
	if _hint_cells.is_empty():
		return
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_method(_apply_hint_scale, 1.0, 1.18, 0.45).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_method(_apply_hint_scale, 1.18, 1.0, 0.45).set_trans(Tween.TRANS_SINE)


func _apply_hint_scale(value: float) -> void:
	for cell in _hint_cells:
		var view: TileView = _tiles.get(cell)
		if view != null:
			view.scale = Vector2.ONE * value


func _play_events(events: Array[BoardEvent]) -> void:
	for event in events:
		match event.kind:
			BoardEvent.Kind.SWAP:
				AudioManager.play_sfx(&"tile_swap")
				await _anim_swap(event.data.a, event.data.b)
			BoardEvent.Kind.SWAP_REJECTED:
				AudioManager.play_sfx(&"tile_reject")
				await _anim_swap(event.data.a, event.data.b)
			BoardEvent.Kind.BOMB_PRIMED:
				AudioManager.play_sfx(&"bomb_primed")
				await _anim_bomb_primed(event.data.cells)
			BoardEvent.Kind.CLEARED:
				AudioManager.play_sfx(&"tile_match")
				await _anim_clear(event.data.cells)
			BoardEvent.Kind.SPECIAL_CREATED:
				await _anim_special_created(event.data.cell, event.data.type, event.data.special)
			BoardEvent.Kind.TRANSFORMED:
				await _anim_transformed(event.data.changes)
			BoardEvent.Kind.GRAVITY:
				await _anim_gravity(event.data.falls, event.data.spawns)
				AudioManager.play_sfx(&"tile_land")
			BoardEvent.Kind.SHUFFLED:
				await _anim_shuffle(event.data.layout)


func _anim_swap(a: Vector2i, b: Vector2i) -> void:
	var view_a: TileView = _tiles.get(a)
	var view_b: TileView = _tiles.get(b)
	if view_a == null or view_b == null:
		return
	_tiles[a] = view_b
	_tiles[b] = view_a
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(view_a, "position", _cell_to_pos(b), _dur(SWAP_TIME))
	tween.tween_property(view_b, "position", _cell_to_pos(a), _dur(SWAP_TIME))
	await tween.finished


func _anim_clear(cells: Array[Vector2i]) -> void:
	var views: Array[TileView] = []
	for cell in cells:
		var view: TileView = _tiles.get(cell)
		if view != null:
			views.append(view)
			_tiles.erase(cell)
	if views.is_empty():
		return
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	for view in views:
		tween.tween_property(view, "scale", Vector2.ZERO, _dur(CLEAR_TIME))
	await tween.finished
	for view in views:
		view.queue_free()


func _anim_bomb_primed(cells: Array[Vector2i]) -> void:
	var views: Array[TileView] = []
	for cell in cells:
		var view: TileView = _tiles.get(cell)
		if view != null:
			views.append(view)
	if views.is_empty():
		return
	var grow := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for view in views:
		grow.tween_property(view, "scale", Vector2.ONE * 1.25, _dur(0.09))
	await grow.finished
	var shrink := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for view in views:
		shrink.tween_property(view, "scale", Vector2.ONE, _dur(0.09))
	await shrink.finished


func _anim_special_created(cell: Vector2i, type: int, special: int) -> void:
	var view := _create_tile_view(cell, type, special)
	view.scale = Vector2.ZERO
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2.ONE, _dur(POP_TIME))
	await tween.finished


func _anim_transformed(changes: Array[Dictionary]) -> void:
	for change in changes:
		var view: TileView = _tiles.get(change.cell)
		if view != null:
			view.set_special(change.special)
	await get_tree().create_timer(_dur(POP_TIME)).timeout


func _anim_gravity(falls: Array[Dictionary], spawns: Array[Dictionary]) -> void:
	var total_time := 0.0
	# Two-phase map update so chained falls inside a column don't collide.
	var moved: Array = []
	for fall in falls:
		var view: TileView = _tiles.get(fall.from)
		if view != null:
			_tiles.erase(fall.from)
			moved.append([view, fall.to])
	for entry in moved:
		var view: TileView = entry[0]
		var to: Vector2i = entry[1]
		_tiles[to] = view
		total_time = maxf(total_time, _drop_tile(view, _cell_to_pos(to), 0.0))

	var spawn_index_per_column: Dictionary = {}
	for spawn in spawns:
		var cell: Vector2i = spawn.cell
		var index := int(spawn_index_per_column.get(cell.x, 0))
		spawn_index_per_column[cell.x] = index + 1
		var view := _create_tile_view(cell, spawn.type, spawn.special)
		# Spawn above the board: clip_contents keeps the gem invisible
		# until it enters the grid.
		view.position = _cell_to_pos(Vector2i(cell.x, -1 - index))
		# Raindrop stagger: lower gems of a column land first, one by one.
		total_time = maxf(total_time, _drop_tile(view, _cell_to_pos(cell), index * SPAWN_STAGGER))
	if total_time > 0.0:
		await get_tree().create_timer(total_time).timeout


## Drops a tile to its target, overshooting slightly past it and bouncing
## back up like a raindrop. Returns the total animation time.
func _drop_tile(view: TileView, target: Vector2, delay: float) -> float:
	var distance := view.position.distance_to(target) / _cell_px
	var fall_time := _dur(maxf(0.12, FALL_TIME_PER_CELL * distance))
	var bounce_time := _dur(BOUNCE_TIME)
	var staggered := _dur(delay)
	var overshoot := target + Vector2(0.0, _cell_px * OVERSHOOT_FACTOR)
	var tween := create_tween()
	if staggered > 0.0:
		tween.tween_interval(staggered)
	tween.tween_property(view, "position", overshoot, fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(view, "position", target, bounce_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return staggered + fall_time + bounce_time


func _anim_shuffle(layout: Dictionary) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, _dur(0.2))
	await tween.finished
	_rebuild_from_layout(layout)
	var tween_in := create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, _dur(0.2))
	await tween_in.finished


func _rebuild_all() -> void:
	_rebuild_from_layout(logic.snapshot())


func _rebuild_from_layout(layout: Dictionary) -> void:
	_clear_hint()
	for child in get_children():
		if child == _hint_timer:
			continue
		child.queue_free()
	_tiles.clear()
	for cell: Vector2i in layout.keys():
		var entry: Dictionary = layout[cell]
		_create_tile_view(cell, entry.type, entry.special)


func _create_tile_view(cell: Vector2i, type: int, special: int) -> TileView:
	var view := TileView.new()
	add_child(view)
	view.position = _cell_to_pos(cell)
	var def: TileDefinition = catalog.get_def(type) if catalog != null else null
	view.setup(type, special, def, _cell_px)
	_tiles[cell] = view
	return view


func _relayout() -> void:
	if logic == null:
		return
	_cell_px = minf(size.x / float(logic.size.x), size.y / float(logic.size.y))
	_origin = (size - Vector2(logic.size) * _cell_px) * 0.5
	_rebuild_all()


func _set_selection(cell: Vector2i) -> void:
	var previous: TileView = _tiles.get(_selected)
	if previous != null:
		previous.set_selected(false)
	_selected = cell
	var current: TileView = _tiles.get(_selected)
	if current != null:
		current.set_selected(true)


func _cell_to_pos(cell: Vector2i) -> Vector2:
	return _origin + (Vector2(cell) + Vector2(0.5, 0.5)) * _cell_px


func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(((pos - _origin) / _cell_px).floor())


static func _dominant_dir(delta: Vector2) -> Vector2i:
	if absf(delta.x) >= absf(delta.y):
		return Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP
