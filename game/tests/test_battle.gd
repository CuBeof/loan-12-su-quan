extends BoardTestBase
## Unit tests for the battle layer: CombatantState, EffectResolver
## and TurnManager.

const TY := TileTypes.Type


func _hero() -> CombatantState:
	return CombatantState.make(100, 5, 4, 5, 50)


func _bandit() -> CombatantState:
	return CombatantState.make(80, 4, 3, 5, 50)


func _battle() -> TurnManager:
	var turns := TurnManager.new()
	turns.setup(_hero(), _bandit(), 7)
	return turns


func _move_with(counts: Dictionary, extra_turn := false) -> MoveResult:
	var result := MoveResult.new()
	result.valid = true
	result.cleared_counts = counts
	result.extra_turn = extra_turn
	return result


func _rejected_move() -> MoveResult:
	var result := MoveResult.new()
	result.penalty_attack_tiles = BoardLogic.INVALID_SWAP_PENALTY_ATTACK_TILES
	return result


func test_attack_tiles_damage_opponent() -> void:
	var turns := _battle()
	var effects := turns.apply_move(_move_with({TY.ATTACK: 3}))
	check_eq(turns.enemy.hp, 65, "3 attack tiles x 5 must deal 15 damage")
	check_eq(effects.size(), 1, "exactly one effect expected")
	check_eq(int(effects[0].amount), 15, "damage effect must report 15")


func test_heal_is_clamped_at_max_hp() -> void:
	var turns := _battle()
	turns.player.hp = 95
	turns.apply_move(_move_with({TY.HEALTH: 3}))
	check_eq(turns.player.hp, 100, "heal must clamp at max HP")


func test_energy_gold_xp_accumulate() -> void:
	var turns := _battle()
	turns.apply_move(_move_with({TY.ENERGY: 2, TY.GOLD: 4, TY.EXP: 3}))
	check_eq(turns.player.energy, 10, "2 energy tiles x 5 must grant 10 energy")
	check_eq(turns.player.gold, 4, "gold tiles accumulate 1:1")
	check_eq(turns.player.xp, 3, "xp tiles accumulate 1:1")


func test_turn_switches_and_round_counts() -> void:
	var turns := _battle()
	turns.apply_move(_move_with({TY.GOLD: 3}))
	check_eq(turns.turn_owner, TurnManager.Owner.ENEMY, "turn must pass to the enemy")
	check_eq(turns.turn_number, 1, "round number must not change mid-round")
	turns.apply_move(_move_with({TY.GOLD: 3}))
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "turn must return to the player")
	check_eq(turns.turn_number, 2, "round number must increase when back to the player")


func test_extra_turn_keeps_owner() -> void:
	var turns := _battle()
	turns.apply_move(_move_with({TY.GOLD: 4}, true))
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "extra turn must keep the mover's turn")


func test_enemy_move_applies_effects_to_enemy() -> void:
	var turns := _battle()
	turns.pass_turn()
	turns.apply_move(_move_with({TY.ATTACK: 2, TY.HEALTH: 1}))
	check_eq(turns.player.hp, 92, "enemy attack 2 x 4 must deal 8 to the player")
	check_eq(turns.enemy.hp, 80, "enemy heal clamps at its max HP")


func test_rejected_swap_damages_mover_and_keeps_turn() -> void:
	var turns := _battle()
	var effects := turns.apply_rejected(_rejected_move())
	check_eq(turns.player.hp, 92, "penalty must be 2 x enemy attack (4) = 8 damage")
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "confirmed rule: penalty does not consume the turn")
	check_eq(effects.size(), 1, "exactly one penalty effect expected")
	check_eq(int(effects[0].kind), EffectResolver.EffectKind.PENALTY_DAMAGE, "effect must be PENALTY_DAMAGE")


func test_player_wins_when_enemy_hp_reaches_zero() -> void:
	var turns := _battle()
	turns.enemy.hp = 10
	turns.apply_move(_move_with({TY.ATTACK: 3}))
	check_eq(turns.outcome, TurnManager.Outcome.PLAYER_WON, "player must win when enemy HP hits 0")
	check_eq(turns.enemy.hp, 0, "HP must not go below 0")
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "turn must not pass after the battle ended")
	var after := turns.apply_move(_move_with({TY.ATTACK: 3}))
	check(after.is_empty(), "moves after the battle ended must do nothing")


func test_penalty_can_kill_the_mover() -> void:
	var turns := _battle()
	turns.player.hp = 5
	turns.apply_rejected(_rejected_move())
	check_eq(turns.outcome, TurnManager.Outcome.ENEMY_WON, "player dying to the penalty loses the battle")


func test_forfeit_loses_the_battle() -> void:
	var turns := _battle()
	turns.forfeit()
	check_eq(turns.outcome, TurnManager.Outcome.ENEMY_WON, "retreating counts as a loss")


func test_enemy_move_choice_is_legal_and_seeded() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 42)
	var turns := _battle()
	var move := turns.choose_enemy_move(board.grid)
	check(not move.is_empty(), "enemy must find a move on a fresh board")
	var legal_moves := MoveGenerator.find_moves(board.grid)
	check(move in legal_moves, "enemy move must be one of the legal moves")
	var turns_b := TurnManager.new()
	turns_b.setup(_hero(), _bandit(), 7)
	check_eq(turns_b.choose_enemy_move(board.grid), move, "same seed must pick the same move")
