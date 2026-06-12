extends Control
## Shop screen (SPEC layout): row 1 player avatar vs shopkeeper avatar,
## row 2 back button, then the product list. Tapping a product opens a
## detail popup with a buy button. Purchases go through ItemService and
## autosave.

@export var catalog: ItemCatalog

@onready var _player_avatar: ColorRect = %PlayerAvatar
@onready var _keeper_avatar: ColorRect = %KeeperAvatar
@onready var _gold_label: Label = %GoldLabel
@onready var _keeper_label: Label = %KeeperLabel
@onready var _back_button: Button = %BackButton
@onready var _item_list: VBoxContainer = %ItemList
@onready var _popup: ColorRect = %PopupOverlay
@onready var _popup_name: Label = %PopupName
@onready var _popup_desc: Label = %PopupDesc
@onready var _popup_info: Label = %PopupInfo
@onready var _popup_action: Button = %PopupAction
@onready var _popup_close: Button = %PopupClose

var _selected: ItemDefinition
var _rows: Array[Button] = []


func _ready() -> void:
	_back_button.text = tr(&"UI_BACK")
	_keeper_label.text = tr(&"SHOP_KEEPER")
	_popup_close.text = tr(&"UI_CLOSE")
	_popup_action.text = tr(&"UI_BUY")
	if GameState.player_def != null:
		_player_avatar.color = GameState.player_def.color
	_back_button.pressed.connect(func() -> void: SceneManager.back())
	_popup_close.pressed.connect(func() -> void: _popup.visible = false)
	_popup_action.pressed.connect(_on_buy_pressed)
	_build_rows()
	_refresh()


func _build_rows() -> void:
	if catalog == null:
		return
	for item in catalog.items:
		var row := Button.new()
		row.custom_minimum_size = Vector2(0, 56)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override(&"font_size", 20)
		row.pressed.connect(_on_item_pressed.bind(item))
		_item_list.add_child(row)
		_rows.append(row)


func _refresh() -> void:
	var profile := GameState.profile
	_gold_label.text = tr(&"UI_GOLD_AMOUNT") % (profile.gold if profile != null else 0)
	for i in range(_rows.size()):
		var item := catalog.items[i]
		var owned := ItemService.count(profile, item.id) if profile != null else 0
		var owned_text := "  [x%d]" % owned if owned > 0 else ""
		_rows[i].text = "%s - %s%s" % [tr(item.display_name_key), tr(&"UI_PRICE") % item.price, owned_text]


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
	var owned := ItemService.count(profile, _selected.id) if profile != null else 0
	_popup_info.text = "%s   %s" % [tr(&"UI_PRICE") % _selected.price, tr(&"UI_OWNED") % owned]
	_popup_action.disabled = profile == null or not ItemService.can_buy(profile, _selected.price)


func _on_buy_pressed() -> void:
	if _selected == null:
		return
	if ItemService.buy(GameState.profile, _selected.id, _selected.price):
		AudioManager.play_sfx(&"shop_buy")
		SaveManager.save_profile(GameState.profile)
	_refresh()
	_update_popup()
