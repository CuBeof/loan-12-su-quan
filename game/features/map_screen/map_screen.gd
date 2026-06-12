extends Control
## Campaign map: location nodes connected by paths. A battle node is
## reachable when a neighbor is cleared (the home node counts as cleared).
## Tapping a reachable battle node launches its fight. Progress lives in
## GameState; the map rebuilds from it each time it is shown.

const NODE_RADIUS := 34.0
const EDGE_COLOR := Color(0.45, 0.4, 0.55, 1)
const COLOR_CLEARED := Color(0.3, 0.72, 0.36, 1)
const COLOR_REACHABLE := Color(0.95, 0.76, 0.2, 1)
const COLOR_LOCKED := Color(0.35, 0.33, 0.4, 1)

# Node positions are screen ratios so the map scales to any device.
const NODES: Array[Dictionary] = [
	{"id": &"home", "name_key": &"MAP_HOME", "pos": Vector2(0.5, 0.86), "enemy": ""},
	{"id": &"bandit_camp", "name_key": &"MAP_BANDIT_CAMP", "pos": Vector2(0.28, 0.58),
		"enemy": "res://data/combatants/bandit.tres"},
	# "enemy_mods": region passives, raw StatModifier dicts applied to the
	# enemy for that battle only (lifetime "battle").
	{"id": &"warlord_keep", "name_key": &"MAP_WARLORD_KEEP", "pos": Vector2(0.68, 0.3),
		"enemy": "res://data/combatants/warlord.tres",
		"enemy_mods": [{"stat": "armor", "amount": 1, "kind": "flat",
			"source": "region_warlord_keep", "lifetime": "battle"}]},
]
const EDGES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2)]

@onready var _graph: Control = %Graph
@onready var _back_button: Button = %BackButton
@onready var _title: Label = %Title

var _buttons: Array[Button] = []


func _ready() -> void:
	_title.text = tr(&"MAP_TITLE")
	_back_button.text = tr(&"UI_BACK")
	_back_button.pressed.connect(func() -> void: SceneManager.goto(SceneManager.MAIN_MENU, false))
	_graph.draw.connect(_draw_edges)
	_graph.resized.connect(_layout_nodes)
	for i in range(NODES.size()):
		var button := Button.new()
		button.toggle_mode = false
		button.custom_minimum_size = Vector2(NODE_RADIUS * 2.0, NODE_RADIUS * 2.0)
		button.text = tr(NODES[i].name_key)
		button.pressed.connect(_on_node_pressed.bind(i))
		_graph.add_child(button)
		_buttons.append(button)
	_refresh_states()
	_layout_nodes()


func _node_pos(index: int) -> Vector2:
	return NODES[index].pos * _graph.size


func _is_cleared(index: int) -> bool:
	# The home node has no enemy and always counts as secured.
	return NODES[index].enemy == "" or GameState.is_node_cleared(NODES[index].id)


func _is_reachable(index: int) -> bool:
	if _is_cleared(index):
		return true
	for edge in EDGES:
		if edge.x == index and _is_cleared(edge.y):
			return true
		if edge.y == index and _is_cleared(edge.x):
			return true
	return false


func _refresh_states() -> void:
	for i in range(NODES.size()):
		var button := _buttons[i]
		var has_enemy: bool = NODES[i].enemy != ""
		var reachable := _is_reachable(i)
		button.disabled = not reachable or not has_enemy
		if not has_enemy:
			button.modulate = COLOR_CLEARED
		elif GameState.is_node_cleared(NODES[i].id):
			button.modulate = COLOR_CLEARED
		elif reachable:
			button.modulate = COLOR_REACHABLE
		else:
			button.modulate = COLOR_LOCKED


func _layout_nodes() -> void:
	for i in range(_buttons.size()):
		var center := _node_pos(i)
		_buttons[i].position = center - _buttons[i].custom_minimum_size * 0.5
	_graph.queue_redraw()


func _draw_edges() -> void:
	for edge in EDGES:
		_graph.draw_line(_node_pos(edge.x), _node_pos(edge.y), EDGE_COLOR, 4.0)


func _on_node_pressed(index: int) -> void:
	if NODES[index].enemy == "" or not _is_reachable(index):
		return
	GameState.current_enemy = load(NODES[index].enemy) as CombatantDefinition
	GameState.current_node = NODES[index].id
	GameState.battle_modifiers = NODES[index].get("enemy_mods", [])
	SceneManager.goto(SceneManager.BATTLE)
