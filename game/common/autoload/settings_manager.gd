extends Node
## Persistent player settings: audio (master/music/sfx volume + on-off),
## hint delay, effect speed, and locale. Applied to the AudioServer buses
## and TranslationServer; saved to user://settings.cfg. Other systems
## react through EventBus.settings_changed.

const SAVE_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var master_enabled: bool = true
var music_enabled: bool = true
var sfx_enabled: bool = true
var hint_delay: float = 5.0 # idle seconds before the board suggests a move
var effect_speed: float = 1.0 # animation speed multiplier
var locale: String = "en"


func _ready() -> void:
	_load()
	apply()


## Pushes the current values to the engine without persisting.
func apply() -> void:
	_apply_bus(&"Master", master_volume, master_enabled)
	_apply_bus(&"Music", music_volume, music_enabled)
	_apply_bus(&"SFX", sfx_volume, sfx_enabled)
	if not locale.is_empty():
		TranslationServer.set_locale(locale)


## Applies, persists and notifies listeners. Call after the UI changes a value.
func apply_and_save() -> void:
	apply()
	_save()
	EventBus.settings_changed.emit()


func _apply_bus(bus_name: StringName, volume: float, enabled: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, not enabled)
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(volume, 0.001, 1.0)))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "master_enabled", master_enabled)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("ux", "hint_delay", hint_delay)
	cfg.set_value("ux", "effect_speed", effect_speed)
	cfg.set_value("general", "locale", locale)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # first run: keep defaults
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	master_enabled = cfg.get_value("audio", "master_enabled", master_enabled)
	music_enabled = cfg.get_value("audio", "music_enabled", music_enabled)
	sfx_enabled = cfg.get_value("audio", "sfx_enabled", sfx_enabled)
	hint_delay = cfg.get_value("ux", "hint_delay", hint_delay)
	effect_speed = cfg.get_value("ux", "effect_speed", effect_speed)
	locale = cfg.get_value("general", "locale", locale)
