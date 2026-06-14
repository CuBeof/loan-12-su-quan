extends Control
## Skill tree screen: nodes laid out by ratio, prerequisite lines drawn,
## tap a node for a detail popup with an Unlock button. Spending skill
## points goes through SkillTreeService and autosaves.

const NODE_RADIUS := 36.0
const EDGE_COLOR := Color(0.4, 0.38, 0.5, 1)
const COLOR_UNLOCKED := Color(0.3, 0.72, 0.36)
const COLOR_AVAILABLE := Color(0.95, 0.76, 0.2)
const COLOR_LOCKED := Color(0.35, 0.33, 0.4)

@onready var _graph: Control = %Graph
@onready var _back_button: Button = %BackButton
@onready var _title: Label = %Title
@onready var _points_label: Label = %PointsLabel
@onready var _popup: ColorRect = %PopupOverlay
@onready var _popup_name: Label = %PopupName
@onready var _popup_desc: Label = %PopupDesc
@onready var _popup_info: Label = %PopupInfo
@onready var _popup_action: Button = %PopupAction
@onready var _popup_close: Button = %PopupClose

var _tree: SkillTree
var _buttons: Array[Button] = []
var _selected: SkillTreeNode


func _ready() -> void:
	_title.text = tr(&"SKILLTREE_TITLE")
	_back_button.text = tr(&"UI_BACK")
	_popup_close.text = tr(&"UI_CLOSE")
	_popup_action.text = tr(&"UI_UNLOCK")
	_tree = GameState.skill_tree
	_back_button.pressed.connect(func() -> void: SceneManager.back())
	_popup_close.pressed.connect(func() -> void: _popup.visible = false)
	_popup_action.pressed.connect(_on_unlock_pressed)
	_graph.draw.connect(_draw_edges)
	_graph.resized.connect(_layout_nodes)
	if _tree != null:
		for i in range(_tree.nodes.size()):
			var button := Button.new()
			button.custom_minimum_size = Vector2(NODE_RADIUS * 2.0, NODE_RADIUS * 2.0)
			button.text = tr(_tree.nodes[i].display_name_key)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override(&"font_size", 13)
			button.pressed.connect(_on_node_pressed.bind(i))
			_graph.add_child(button)
			_buttons.append(button)
	_refresh()
	_layout_nodes()


func _node_pos(index: int) -> Vector2:
	return _tree.nodes[index].pos * _graph.size


func _state(node: SkillTreeNode) -> int:
	if SkillTreeService.is_unlocked(GameState.profile, node.id):
		return 0 # unlocked
	if SkillTreeService.prereqs_met(GameState.profile, node.prerequisites):
		return 1 # available
	return 2 # locked


func _refresh() -> void:
	var points := GameState.profile.skill_points if GameState.profile != null else 0
	_points_label.text = tr(&"SKILLTREE_POINTS") % points
	for i in range(_buttons.size()):
		match _state(_tree.nodes[i]):
			0:
				_buttons[i].modulate = COLOR_UNLOCKED
			1:
				_buttons[i].modulate = COLOR_AVAILABLE
			_:
				_buttons[i].modulate = COLOR_LOCKED
	_graph.queue_redraw()


func _layout_nodes() -> void:
	for i in range(_buttons.size()):
		_buttons[i].position = _node_pos(i) - _buttons[i].custom_minimum_size * 0.5
	_graph.queue_redraw()


func _draw_edges() -> void:
	if _tree == null:
		return
	for i in range(_tree.nodes.size()):
		for prereq in _tree.nodes[i].prerequisites:
			var from_index := _index_of(prereq)
			if from_index >= 0:
				_graph.draw_line(_node_pos(from_index), _node_pos(i), EDGE_COLOR, 4.0)


func _index_of(node_id: StringName) -> int:
	for i in range(_tree.nodes.size()):
		if _tree.nodes[i].id == node_id:
			return i
	return -1


func _on_node_pressed(index: int) -> void:
	_selected = _tree.nodes[index]
	_popup_name.text = tr(_selected.display_name_key)
	_popup_desc.text = tr(_selected.description_key)
	_update_popup()
	_popup.visible = true


func _update_popup() -> void:
	if _selected == null:
		return
	match _state(_selected):
		0:
			_popup_info.text = tr(&"SKILLTREE_UNLOCKED")
			_popup_action.visible = false
		1:
			_popup_info.text = tr(&"SKILLTREE_COST") % _selected.cost
			_popup_action.visible = true
			_popup_action.disabled = not SkillTreeService.can_unlock(
					GameState.profile, _selected.id, _selected.cost, _selected.prerequisites)
		_:
			_popup_info.text = tr(&"SKILLTREE_LOCKED")
			_popup_action.visible = false


func _on_unlock_pressed() -> void:
	if _selected == null:
		return
	if SkillTreeService.unlock(GameState.profile, _selected.id, _selected.cost,
			_selected.prerequisites, _selected.stat_mods):
		AudioManager.play_sfx(&"skill_unlock")
		SaveManager.save_profile(GameState.profile)
	_refresh()
	_update_popup()
