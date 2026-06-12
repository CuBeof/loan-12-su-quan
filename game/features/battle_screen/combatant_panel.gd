class_name CombatantPanel
extends PanelContainer
## HUD panel for one combatant: avatar placeholder, name, HP and energy
## bars with current values. A pure projection — owns no battle state.

@onready var _avatar: ColorRect = %Avatar
@onready var _avatar_texture: TextureRect = %AvatarTexture
@onready var _name_label: Label = %NameLabel
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_text: Label = %HPText
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _energy_text: Label = %EnergyText


func setup(def: CombatantDefinition) -> void:
	_name_label.text = tr(def.display_name_key)
	_avatar.color = def.color
	if def.portrait != null:
		_avatar_texture.texture = def.portrait


func refresh(state: CombatantState) -> void:
	_hp_bar.max_value = state.max_hp
	_energy_bar.max_value = state.max_energy
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hp_bar, "value", state.hp, 0.25)
	tween.tween_property(_energy_bar, "value", state.energy, 0.25)
	_hp_text.text = "%d/%d" % [state.hp, state.max_hp]
	_energy_text.text = "%d/%d" % [state.energy, state.max_energy]


## Brief tint to signal damage (red) or heal (green).
func flash(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", color, 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
