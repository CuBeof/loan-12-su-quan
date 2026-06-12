extends Control
## Settings screen. The audio tab matches SPEC (game/music/sfx on-off +
## volume); the experience tab exposes hint delay and effect speed. All
## controls write straight to the Settings autoload, which applies and
## persists. The UI is built in code to keep the layout maintainable.

const MIN_HINT_DELAY := 1.0
const MAX_HINT_DELAY := 15.0
const MIN_EFFECT_SPEED := 0.5
const MAX_EFFECT_SPEED := 2.0

@onready var _tabs: TabContainer = %Tabs
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.text = tr(&"UI_BACK")
	_back_button.pressed.connect(func() -> void: SceneManager.back())
	_build_audio_tab()
	_build_experience_tab()


func _build_audio_tab() -> void:
	var tab := _make_tab(&"SETTINGS_TAB_AUDIO")
	_add_audio_row(tab, &"SETTINGS_MASTER",
		Settings.master_enabled, Settings.master_volume,
		func(on: bool) -> void: Settings.master_enabled = on,
		func(v: float) -> void: Settings.master_volume = v)
	_add_audio_row(tab, &"SETTINGS_MUSIC",
		Settings.music_enabled, Settings.music_volume,
		func(on: bool) -> void: Settings.music_enabled = on,
		func(v: float) -> void: Settings.music_volume = v)
	_add_audio_row(tab, &"SETTINGS_SFX",
		Settings.sfx_enabled, Settings.sfx_volume,
		func(on: bool) -> void: Settings.sfx_enabled = on,
		func(v: float) -> void: Settings.sfx_volume = v)


func _build_experience_tab() -> void:
	var tab := _make_tab(&"SETTINGS_TAB_EXPERIENCE")
	_add_slider_row(tab, &"SETTINGS_HINT_DELAY", MIN_HINT_DELAY, MAX_HINT_DELAY, 0.5,
		Settings.hint_delay, func(v: float) -> void: Settings.hint_delay = v)
	_add_slider_row(tab, &"SETTINGS_EFFECT_SPEED", MIN_EFFECT_SPEED, MAX_EFFECT_SPEED, 0.1,
		Settings.effect_speed, func(v: float) -> void: Settings.effect_speed = v)


func _make_tab(title_key: StringName) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tr(title_key)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 18)
	scroll.add_child(column)
	_tabs.add_child(scroll)
	return column


func _add_audio_row(parent: VBoxContainer, label_key: StringName, enabled: bool,
		volume: float, on_toggle: Callable, on_volume: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var toggle := CheckButton.new()
	toggle.text = tr(label_key)
	toggle.button_pressed = enabled
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = volume
	slider.custom_minimum_size = Vector2(0, 36)
	slider.editable = enabled
	toggle.toggled.connect(func(pressed: bool) -> void:
		slider.editable = pressed
		on_toggle.call(pressed)
		Settings.apply_and_save())
	slider.value_changed.connect(func(value: float) -> void:
		on_volume.call(value)
		Settings.apply_and_save())
	row.add_child(toggle)
	row.add_child(slider)
	parent.add_child(row)


func _add_slider_row(parent: VBoxContainer, label_key: StringName, min_value: float,
		max_value: float, step: float, value: float, on_change: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var label := Label.new()
	var value_label := Label.new()
	value_label.text = "%.1f" % value
	var header := HBoxContainer.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 36)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%.1f" % v
		on_change.call(v)
		Settings.apply_and_save())
	row.add_child(header)
	row.add_child(slider)
	parent.add_child(row)
