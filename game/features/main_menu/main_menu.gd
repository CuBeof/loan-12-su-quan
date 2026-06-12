extends Control
## Title screen: Continue / New Game / Settings / Info. Buttons emit
## intent; navigation goes through SceneManager.

@onready var _title: Label = %Title
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _info_button: Button = %InfoButton


func _ready() -> void:
	_title.text = tr(&"GAME_TITLE")
	_continue_button.text = tr(&"MENU_CONTINUE")
	_new_game_button.text = tr(&"MENU_NEW_GAME")
	_settings_button.text = tr(&"MENU_SETTINGS")
	_info_button.text = tr(&"MENU_INFO")
	# No save system yet (Phase 6): Continue is available only after progress
	# has been made this session.
	_continue_button.disabled = GameState.cleared_nodes.is_empty()
	_continue_button.pressed.connect(_on_continue)
	_new_game_button.pressed.connect(_on_new_game)
	_settings_button.pressed.connect(func() -> void: SceneManager.goto(SceneManager.SETTINGS))
	_info_button.pressed.connect(func() -> void: SceneManager.goto(SceneManager.INFO))


func _on_continue() -> void:
	SceneManager.goto(SceneManager.MAP)


func _on_new_game() -> void:
	GameState.reset_progress()
	SceneManager.goto(SceneManager.MAP)
