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
	_update_labels()


func _on_move_resolved(result: MoveResult) -> void:
	for type: int in result.cleared_counts:
		_totals[type] = int(_totals.get(type, 0)) + int(result.cleared_counts[type])
	if result.extra_turn:
		_info_label.text = "Thêm lượt!"
	else:
		_info_label.text = ""
		_turn += 1
	_update_labels()


func _update_labels() -> void:
	_turn_label.text = "Lượt %d" % _turn
	_counts_label.text = "Công: %d   Máu: %d   Vàng: %d   NL: %d   KN: %d" % [
		int(_totals.get(TileTypes.Type.ATTACK, 0)),
		int(_totals.get(TileTypes.Type.HEALTH, 0)),
		int(_totals.get(TileTypes.Type.GOLD, 0)),
		int(_totals.get(TileTypes.Type.ENERGY, 0)),
		int(_totals.get(TileTypes.Type.EXP, 0)),
	]
