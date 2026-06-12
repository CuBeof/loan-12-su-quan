extends Control
## Bag screen (SPEC layout): player avatar + stats on top, owned items
## in a grid, tap an item for a detail popup with Use / Equip / Unequip.
## All mutations go through ItemService and autosave.

@export var catalog: ItemCatalog

@onready var _avatar: ColorRect = %Avatar
@onready var _stats_label: Label = %StatsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _back_button: Button = %BackButton
@onready var _grid: GridContainer = %Grid
@onready var _empty_label: Label = %EmptyLabel
@onready var _popup: ColorRect = %PopupOverlay
@onready var _popup_name: Label = %PopupName
@onready var _popup_desc: Label = %PopupDesc
@onready var _popup_info: Label = %PopupInfo
@onready var _popup_action: Button = %PopupAction
@onready var _popup_close: Button = %PopupClose

var _selected: ItemDefinition


func _ready() -> void:
	_back_button.text = tr(&"UI_BACK")
	_popup_close.text = tr(&"UI_CLOSE")
	_empty_label.text = tr(&"INVENTORY_EMPTY")
	if GameState.player_def != null:
		_avatar.color = GameState.player_def.color
	_back_button.pressed.connect(func() -> void: SceneManager.back())
	_popup_close.pressed.connect(func() -> void: _popup.visible = false)
	_popup_action.pressed.connect(_on_action_pressed)
	_refresh()


func _refresh() -> void:
	var profile := GameState.profile
	if profile == null:
		_stats_label.text = ""
		_gold_label.text = tr(&"UI_GOLD_AMOUNT") % 0
		_empty_label.visible = true
		return
	var hp := profile.max_hp() if profile.current_hp < 0 else profile.current_hp
	_stats_label.text = tr(&"UI_STATS_LINE") % [
		hp, profile.max_hp(),
		profile.stats.get_value(StatTypes.Stat.ATTACK_PER_TILE),
		profile.stats.get_value(StatTypes.Stat.ARMOR),
	]
	_gold_label.text = tr(&"UI_GOLD_AMOUNT") % profile.gold
	for child in _grid.get_children():
		child.queue_free()
	var has_items := false
	if catalog != null:
		for item in catalog.items:
			var owned := ItemService.count(profile, item.id)
			if owned <= 0:
				continue
			has_items = true
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(0, 72)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_font_size_override(&"font_size", 16)
			var equipped_tag := " [%s]" % tr(&"UI_EQUIPPED") if ItemService.is_equipped(profile, item.id) else ""
			cell.text = "%s x%d%s" % [tr(item.display_name_key), owned, equipped_tag]
			cell.pressed.connect(_on_item_pressed.bind(item))
			_grid.add_child(cell)
	_empty_label.visible = not has_items


func _on_item_pressed(item: ItemDefinition) -> void:
	_selected = item
	_popup_name.text = tr(item.display_name_key)
	_popup_desc.text = tr(item.description_key)
	_update_popup()
	_popup.visible = true


func _update_popup() -> void:
	if _selected == null:
		return
	var profile := GameState.profile
	var owned := ItemService.count(profile, _selected.id)
	_popup_info.text = tr(&"UI_OWNED") % owned
	if _selected.kind == ItemDefinition.Kind.EQUIPMENT:
		if ItemService.is_equipped(profile, _selected.id):
			_popup_action.text = tr(&"UI_UNEQUIP")
			_popup_action.disabled = false
		else:
			_popup_action.text = tr(&"UI_EQUIP")
			_popup_action.disabled = owned <= 0
	else:
		_popup_action.text = tr(&"UI_USE")
		_popup_action.disabled = owned <= 0 or not ItemService.can_use(profile, _selected.effects)


func _on_action_pressed() -> void:
	if _selected == null:
		return
	var profile := GameState.profile
	var changed := false
	if _selected.kind == ItemDefinition.Kind.EQUIPMENT:
		if ItemService.is_equipped(profile, _selected.id):
			changed = ItemService.unequip(profile, _selected.id)
		else:
			changed = ItemService.equip(profile, _selected.id, _selected.effects)
	else:
		changed = ItemService.use(profile, _selected.id, _selected.effects)
	if changed:
		AudioManager.play_sfx(&"item_use")
		SaveManager.save_profile(profile)
	_refresh()
	_update_popup()
