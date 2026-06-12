class_name TurnManager
extends RefCounted
## Turn-based battle orchestrator: tracks whose turn it is, applies move
## results through EffectResolver, detects victory/defeat. Pure logic —
## the battle screen drives it and waits for board animations between steps.

enum Owner { PLAYER, ENEMY }
enum Outcome { ONGOING, PLAYER_WON, ENEMY_WON }

var player: CombatantState
var enemy: CombatantState
var turn_owner: int = Owner.PLAYER
var turn_number: int = 1
var outcome: int = Outcome.ONGOING
var rng := RandomNumberGenerator.new()


func setup(player_: CombatantState, enemy_: CombatantState, seed_value: int = 0) -> void:
	player = player_
	enemy = enemy_
	rng.seed = seed_value
	turn_owner = Owner.PLAYER
	turn_number = 1
	outcome = Outcome.ONGOING


func mover() -> CombatantState:
	return player if turn_owner == Owner.PLAYER else enemy


func opponent() -> CombatantState:
	return enemy if turn_owner == Owner.PLAYER else player


## Applies a valid resolved move for the current owner, then passes the
## turn unless an extra turn was earned or the battle ended.
func apply_move(result: MoveResult) -> Array[Dictionary]:
	if outcome != Outcome.ONGOING:
		return []
	var effects := EffectResolver.apply_move(result, mover(), opponent())
	effects.append_array(_proc_swap_statuses(mover()))
	_check_outcome()
	if outcome == Outcome.ONGOING and not result.extra_turn:
		pass_turn()
	return effects


## Rejected swap: the mover takes the counterattack and KEEPS the turn
## (confirmed rule — the penalty is damage only, not a lost turn).
## Poison procs here too: a rejected swap is still a swap.
func apply_rejected(result: MoveResult) -> Array[Dictionary]:
	if outcome != Outcome.ONGOING:
		return []
	var effects := EffectResolver.apply_penalty(result, mover(), opponent())
	effects.append_array(_proc_swap_statuses(mover()))
	_check_outcome()
	return effects


func can_cast(cost: int) -> bool:
	return outcome == Outcome.ONGOING and mover().energy >= cost


## Casts a skill for the current mover. Cost is validated BEFORE being
## spent. Returns {} when the cast is illegal, otherwise
## {"effects": Array[Dictionary], "board_result": MoveResult|null}.
func cast_skill(cost: int, effect_data: Array, board: BoardLogic, ends_turn: bool = true) -> Dictionary:
	if not can_cast(cost):
		return {}
	var caster := mover()
	caster.energy -= cost
	var cast_outcome := SkillResolver.cast(effect_data, caster, opponent(), board, rng)
	_check_outcome()
	if outcome == Outcome.ONGOING and ends_turn:
		pass_turn()
	return cast_outcome


## If the current mover is frozen, consumes one frozen turn and passes
## play to the other side. Returns the info effects, or [] if not frozen.
func try_skip_frozen_turn() -> Array[Dictionary]:
	if outcome != Outcome.ONGOING:
		return []
	var frozen := mover().first_status(StatusEffect.Kind.FREEZE)
	if frozen == null:
		return []
	var effects: Array[Dictionary] = [{"kind": EffectResolver.EffectKind.TURN_FROZEN, "target": mover()}]
	frozen.turns_left -= 1
	if frozen.turns_left <= 0:
		mover().statuses.erase(frozen)
	pass_turn()
	return effects


## POISON_ON_SWAP: the afflicted takes damage every swap they make.
func _proc_swap_statuses(who: CombatantState) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for status in who.statuses:
		if status.kind == StatusEffect.Kind.POISON_ON_SWAP:
			var hit := who.take_damage(int(status.params.get("damage", 0)), 0, &"poison")
			effects.append({
				"kind": EffectResolver.EffectKind.DAMAGE,
				"amount": int(hit.dealt),
				"blocked": int(hit.blocked),
				"immune": bool(hit.get("immune", false)),
				"target": who,
			})
	return effects


## Retreat button: instant loss for the player (SPEC: counts as defeat).
func forfeit() -> void:
	outcome = Outcome.ENEMY_WON


## Placeholder enemy AI (Phase 3 replaces this with a move scorer):
## picks a uniformly random legal move. Returns {} if none exist.
func choose_enemy_move(grid: Dictionary) -> Dictionary:
	var moves := MoveGenerator.find_moves(grid)
	if moves.is_empty():
		return {}
	return moves[rng.randi_range(0, moves.size() - 1)]


func pass_turn() -> void:
	_tick_statuses(mover())
	turn_owner = Owner.ENEMY if turn_owner == Owner.PLAYER else Owner.PLAYER
	if turn_owner == Owner.PLAYER:
		turn_number += 1


## Status durations tick when their owner's turn ends. FREEZE ticks in
## try_skip_frozen_turn instead (one tick per skipped turn).
func _tick_statuses(who: CombatantState) -> void:
	for i in range(who.statuses.size() - 1, -1, -1):
		var status := who.statuses[i]
		if status.kind == StatusEffect.Kind.FREEZE:
			continue
		status.turns_left -= 1
		if status.turns_left <= 0:
			who.statuses.remove_at(i)


func _check_outcome() -> void:
	if not enemy.is_alive():
		outcome = Outcome.PLAYER_WON
	elif not player.is_alive():
		outcome = Outcome.ENEMY_WON
