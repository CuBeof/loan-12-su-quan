extends Control
## Info screen: game title, version and a short description. Content is
## placeholder until the design is finalized.

@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_title.text = tr(&"GAME_TITLE")
	_body.text = tr(&"INFO_BODY")
	_back_button.text = tr(&"UI_BACK")
	_back_button.pressed.connect(func() -> void: SceneManager.back())
