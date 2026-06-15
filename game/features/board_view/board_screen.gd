extends Control
## Free-play board screen: hosts the board and shows turn count plus
## cleared-tile tallies. The battle layer will replace this HUD later.

@onready var _board: BoardView = %BoardView
@onready var _turn_label: Label = %TurnLabel
@onready var _info_label: Label = %InfoLabel
@onready var _counts_label: Label = %CountsLabel

var _turn: int = 1
var _totals: Dictionary = {}


func _ready() -> void:
	_board.move_resolved.connect(_on_move_resolved)
	_board.move_rejected.connect(_on_move_rejected)
	_update_labels()


func _on_move_resolved(result: MoveResult) -> void:
	for type: int in result.cleared_counts:
		_totals[type] = int(_totals.get(type, 0)) + int(result.cleared_counts[type])
	if result.extra_turns > 0:
		_info_label.text = tr(&"UI_EXTRA_TURN")
	else:
		_info_label.text = ""
		_turn += 1
	_update_labels()


func _on_move_rejected(result: MoveResult) -> void:
	if result.penalty_attack_tiles > 0:
		_info_label.text = tr(&"UI_INVALID_MOVE_PENALTY") % result.penalty_attack_tiles


func _update_labels() -> void:
	_turn_label.text = tr(&"UI_TURN") % _turn
	_counts_label.text = tr(&"UI_COUNTS") % [
		int(_totals.get(TileTypes.Type.ATTACK, 0)),
		int(_totals.get(TileTypes.Type.HEALTH, 0)),
		int(_totals.get(TileTypes.Type.GOLD, 0)),
		int(_totals.get(TileTypes.Type.ENERGY, 0)),
		int(_totals.get(TileTypes.Type.EXP, 0)),
	]
