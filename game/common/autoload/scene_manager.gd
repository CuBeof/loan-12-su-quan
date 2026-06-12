extends Node
## Screen navigation with a fade transition and a back stack for the
## Android hardware Back button. Screens call goto() to move forward and
## back() to return; the Back button maps to back(), which quits at the root.

const MAIN_MENU := "res://features/main_menu/main_menu.tscn"
const MAP := "res://features/map_screen/map_screen.tscn"
const SETTINGS := "res://features/settings/settings.tscn"
const INFO := "res://features/info_screen/info_screen.tscn"
const BATTLE := "res://features/battle_screen/battle_screen.tscn"

const FADE_TIME := 0.2

var _stack: Array[String] = []
var _current: String = MAIN_MENU
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_quit_on_go_back(false)
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	await get_tree().process_frame
	if get_tree().current_scene != null:
		_current = get_tree().current_scene.scene_file_path


## Navigates forward, remembering the current screen so back() can return.
func goto(path: String, push: bool = true) -> void:
	if _busy or path == _current:
		return
	if push:
		_stack.append(_current)
	await _change(path)


## Returns to the previous screen, or quits when at the root.
func back() -> void:
	if _busy:
		return
	if _stack.is_empty():
		get_tree().quit()
		return
	await _change(_stack.pop_back())


func _change(path: String) -> void:
	_busy = true
	await _fade_to(1.0)
	get_tree().change_scene_to_file(path)
	_current = path
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
