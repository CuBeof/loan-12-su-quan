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
	_check_outcome()
	if outcome == Outcome.ONGOING and not result.extra_turn:
		pass_turn()
	return effects


## Rejected swap: the mover takes the counterattack and KEEPS the turn
## (confirmed rule — the penalty is damage only, not a lost turn).
func apply_rejected(result: MoveResult) -> Array[Dictionary]:
	if outcome != Outcome.ONGOING:
		return []
	var effects := EffectResolver.apply_penalty(result, mover(), opponent())
	_check_outcome()
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
	turn_owner = Owner.ENEMY if turn_owner == Owner.PLAYER else Owner.PLAYER
	if turn_owner == Owner.PLAYER:
		turn_number += 1


func _check_outcome() -> void:
	if not enemy.is_alive():
		outcome = Outcome.PLAYER_WON
	elif not player.is_alive():
		outcome = Outcome.ENEMY_WON
