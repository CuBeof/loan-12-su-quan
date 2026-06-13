extends Control
## Battle screen controller: mediates between the board view and the
## TurnManager. UI emits signals, this controller listens; logic waits
## for board animations because moves are applied via move_resolved.

const ENEMY_THINK_TIME := 0.35
const DAMAGE_FLASH := Color(1.0, 0.45, 0.45)
const HEAL_FLASH := Color(0.55, 1.0, 0.55)

@export var player_def: CombatantDefinition
@export var enemy_def: CombatantDefinition

@onready var _board: BoardView = %BoardView
@onready var _player_panel: CombatantPanel = %PlayerPanel
@onready var _enemy_panel: CombatantPanel = %EnemyPanel
@onready var _turn_label: Label = %TurnLabel
@onready var _info_label: Label = %InfoLabel
@onready var _retreat_button: Button = %RetreatButton
@onready var _result_overlay: ColorRect = %ResultOverlay
@onready var _result_label: Label = %ResultLabel
@onready var _rewards_label: Label = %RewardsLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _skill_bar: HBoxContainer = %SkillBar

var _turns: TurnManager
var _player_def_used: CombatantDefinition
var _enemy_def_used: CombatantDefinition
var _skill_buttons: Array[Button] = []
var _enemy_profile: AIProfile
var _enemy_skill_data: Array[Dictionary] = []


func _ready() -> void:
	# Prefer the matchup chosen on the map; fall back to the exported
	# defaults so the scene still runs standalone (F6).
	_player_def_used = GameState.player_def if GameState.player_def != null else player_def
	_enemy_def_used = GameState.current_enemy if GameState.current_enemy != null else enemy_def
	# The player's state wraps the profile StatBlock so gear/item/buff
	# modifiers apply automatically and lost HP carries over (SPEC).
	var player_state: CombatantState
	if GameState.profile != null:
		player_state = CombatantState.from_block(GameState.profile.stats, GameState.profile.current_hp)
	else:
		player_state = _make_state(_player_def_used)
	var enemy_state := _make_state(_enemy_def_used)
	for mod_data in GameState.battle_modifiers:
		if mod_data is Dictionary:
			var mod := StatModifier.from_dict(mod_data)
			if mod != null:
				enemy_state.stats.add_modifier(mod)
	_turns = TurnManager.new()
	_turns.setup(player_state, enemy_state, randi())
	_enemy_profile = _enemy_def_used.ai_profile if _enemy_def_used.ai_profile != null else AIProfile.new()
	for skill in _enemy_def_used.skills:
		_enemy_skill_data.append({"cost": skill.energy_cost, "effects": skill.effects, "ref": skill})
	_player_panel.setup(_player_def_used)
	_enemy_panel.setup(_enemy_def_used)
	_retreat_button.text = tr(&"UI_RETREAT")
	_play_again_button.text = tr(&"UI_CONTINUE")
	_build_skill_bar()
	_board.move_resolved.connect(_on_move_resolved)
	_board.move_rejected.connect(_on_move_rejected)
	_retreat_button.pressed.connect(_on_retreat_pressed)
	_play_again_button.pressed.connect(_on_play_again_pressed)
	EventBus.battle_started.emit()
	_refresh()


func _build_skill_bar() -> void:
	for skill in _player_def_used.skills:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s (%d)" % [tr(skill.display_name_key), skill.energy_cost]
		button.add_theme_font_size_override(&"font_size", 16)
		button.pressed.connect(_on_skill_pressed.bind(skill))
		_skill_bar.add_child(button)
		_skill_buttons.append(button)
	_skill_bar.visible = not _skill_buttons.is_empty()


func _update_skill_buttons() -> void:
	var castable := _turns.outcome == TurnManager.Outcome.ONGOING \
			and _turns.turn_owner == TurnManager.Owner.PLAYER
	for i in range(_skill_buttons.size()):
		var skill: SkillDefinition = _player_def_used.skills[i]
		_skill_buttons[i].disabled = not castable or not _turns.can_cast(skill.energy_cost)


func _on_skill_pressed(skill: SkillDefinition) -> void:
	if _turns.turn_owner != TurnManager.Owner.PLAYER:
		return
	_cast_skill(skill)


## Casting flow shared by the player and the AI. Async: awaits the board
## blast animation (if any) before the battle continues.
func _cast_skill(skill: SkillDefinition) -> void:
	var cast_outcome := _turns.cast_skill(skill.energy_cost, skill.effects, _board.logic, skill.ends_turn)
	if cast_outcome.is_empty():
		return
	AudioManager.play_sfx(&"skill_cast")
	_board.input_enabled = false
	_info_label.text = tr(skill.display_name_key)
	var effects: Array[Dictionary] = cast_outcome.effects
	_show_effects(effects)
	_refresh()
	var board_result: MoveResult = cast_outcome.get("board_result")
	if board_result != null:
		await _board.play_result(board_result)
	_continue_battle()


static func _make_state(def: CombatantDefinition) -> CombatantState:
	return CombatantState.from_block(GameState.stat_block_from_def(def))


func _on_move_resolved(result: MoveResult) -> void:
	var effects := _turns.apply_move(result)
	_show_effects(effects)
	_info_label.text = tr(&"UI_EXTRA_TURN") if result.extra_turn else ""
	_refresh()
	_continue_battle()


func _on_move_rejected(result: MoveResult) -> void:
	var effects := _turns.apply_rejected(result)
	for effect in effects:
		if effect.kind == EffectResolver.EffectKind.PENALTY_DAMAGE:
			_info_label.text = tr(&"UI_PENALTY_DAMAGE") % int(effect.amount)
	_show_effects(effects)
	_refresh()
	_continue_battle()


func _continue_battle() -> void:
	if _turns.outcome != TurnManager.Outcome.ONGOING:
		_end_battle()
		return
	# Frozen combatants lose their turn; loop until someone can act
	# (freeze decrements each skip, so this always terminates).
	var frozen := _turns.try_skip_frozen_turn()
	if not frozen.is_empty():
		_info_label.text = tr(&"UI_FROZEN")
		_refresh()
		await get_tree().create_timer(0.8).timeout
		_continue_battle()
		return
	if _turns.turn_owner == TurnManager.Owner.ENEMY:
		_board.input_enabled = false
		_enemy_take_turn()
	else:
		_board.input_enabled = true
	_update_skill_buttons()


func _enemy_take_turn() -> void:
	await get_tree().create_timer(ENEMY_THINK_TIME).timeout
	if _turns.outcome != TurnManager.Outcome.ONGOING:
		return
	# Behavior-profile AI: scores moves by the enemy's AIProfile weights
	# and may cast a useful skill (see AIController).
	var action := AIController.choose_action(_board.logic, _turns.enemy, _turns.player,
			_enemy_skill_data, _enemy_profile, _turns.rng)
	match str(action.get("type", "pass")):
		"skill":
			_cast_skill(_enemy_skill_data[int(action.index)].ref)
		"move":
			_board.play_move(action.a, action.b)
		_:
			_turns.pass_turn()
			_refresh()
			_continue_battle()


func _show_effects(effects: Array[Dictionary]) -> void:
	for effect in effects:
		match effect.kind:
			EffectResolver.EffectKind.DAMAGE, EffectResolver.EffectKind.PENALTY_DAMAGE:
				if bool(effect.get("immune", false)):
					_info_label.text = tr(&"UI_IMMUNE")
				else:
					_panel_for(effect.target).flash(DAMAGE_FLASH)
			EffectResolver.EffectKind.HEAL:
				_panel_for(effect.target).flash(HEAL_FLASH)


func _panel_for(state: CombatantState) -> CombatantPanel:
	return _player_panel if state == _turns.player else _enemy_panel


func _refresh() -> void:
	_player_panel.refresh(_turns.player)
	_enemy_panel.refresh(_turns.enemy)
	var owner_key := &"UI_YOUR_TURN" if _turns.turn_owner == TurnManager.Owner.PLAYER else &"UI_ENEMY_TURN"
	_turn_label.text = "%s - %s" % [tr(&"UI_TURN") % _turns.turn_number, tr(owner_key)]
	_update_skill_buttons()


func _end_battle() -> void:
	_board.input_enabled = false
	var player_won := _turns.outcome == TurnManager.Outcome.PLAYER_WON
	GameState.last_battle_won = player_won
	if player_won:
		GameState.mark_node_cleared(GameState.current_node)
	var profile := GameState.profile
	if profile != null:
		# In-battle buffs (skills) expire; gear/item/NPC modifiers stay.
		profile.stats.clear_lifetime(StatTypes.Lifetime.BATTLE)
		if player_won:
			profile.gold += _turns.player.gold
			profile.xp += _turns.player.xp
			profile.current_hp = _turns.player.hp # SPEC: lost HP persists
		else:
			profile.current_hp = -1 # full restore on defeat until the lives system lands (TODO)
		SaveManager.save_profile(profile)
	_result_label.text = tr(&"UI_VICTORY") if player_won else tr(&"UI_DEFEAT")
	_rewards_label.visible = player_won
	if player_won:
		_rewards_label.text = tr(&"UI_REWARDS") % [_turns.player.gold, _turns.player.xp]
	_result_overlay.visible = true
	EventBus.battle_ended.emit(player_won)


func _on_retreat_pressed() -> void:
	# SPEC: retreating counts as a loss (life cost arrives with the meta layer).
	_turns.forfeit()
	_end_battle()


func _on_play_again_pressed() -> void:
	# Return to the map (or to the menu when launched standalone).
	SceneManager.back()
