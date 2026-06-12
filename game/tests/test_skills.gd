extends BoardTestBase
## Unit tests for the skill system: casting costs, the four example
## skills (fire bomb, freeze, poison, stone skin), status durations and
## the stat_mod effect kind.

const TY := TileTypes.Type
const SK := StatusEffect.Kind

const FIRE_BOMB: Array[Dictionary] = [
	{"kind": "damage", "attack_tiles": 4, "target": "enemy"},
	{"kind": "board_blast", "width": 2, "height": 2},
]
const FREEZE: Array[Dictionary] = [
	{"kind": "status", "status": "freeze", "turns": 4, "target": "enemy"},
]
const POISON: Array[Dictionary] = [
	{"kind": "status", "status": "poison_on_swap", "turns": 5, "attack_tiles": 2, "target": "enemy"},
]
const STONE_SKIN: Array[Dictionary] = [
	{"kind": "status", "status": "source_immunity", "source": "attack_tiles", "turns": 3, "target": "self"},
	{"kind": "status", "status": "damage_taken_percent", "percent": 50, "exclude_source": "attack_tiles", "turns": 3, "target": "self"},
]


func _battle(player_energy: int = 100) -> TurnManager:
	var turns := TurnManager.new()
	turns.setup(CombatantState.make(100, 5, 4, 5, 100), CombatantState.make(80, 4, 3, 5, 50), 7)
	turns.player.energy = player_energy
	return turns


func _attack_move(tiles: int = 3) -> MoveResult:
	var result := MoveResult.new()
	result.valid = true
	result.cleared_counts = {TY.ATTACK: tiles}
	return result


func test_cast_validates_cost_before_spending() -> void:
	var turns := _battle(10)
	check(not turns.can_cast(20), "10 energy cannot pay a 20 cost")
	var cast_outcome := turns.cast_skill(20, FIRE_BOMB, null)
	check(cast_outcome.is_empty(), "an unaffordable cast must do nothing")
	check_eq(turns.player.energy, 10, "energy must not be spent on a failed cast")
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "the turn must not pass on a failed cast")


func test_fire_bomb_damages_and_blasts_the_board() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 11)
	var turns := _battle()
	var cast_outcome := turns.cast_skill(20, FIRE_BOMB, board)
	check_eq(turns.player.energy, 80, "20 energy must be spent")
	check_eq(turns.enemy.hp, 60, "4 attack tiles x 5 attack = 20 damage")
	check_eq(turns.turn_owner, TurnManager.Owner.ENEMY, "casting ends the turn by default")
	var board_result: MoveResult = cast_outcome.get("board_result")
	check(board_result != null and board_result.valid, "the blast must produce board events")
	check_eq(board.grid.size(), 64, "the board must refill after the blast")
	check(MatchFinder.find_groups(board.grid).is_empty(), "the board must settle with no leftover matches")


func test_freeze_skips_enemy_turns() -> void:
	var turns := _battle()
	turns.cast_skill(40, FREEZE, null)
	check_eq(turns.turn_owner, TurnManager.Owner.ENEMY, "turn passes to the frozen enemy")
	for i in range(4):
		var skipped := turns.try_skip_frozen_turn()
		check(not skipped.is_empty(), "frozen turn %d must be skipped" % (i + 1))
		check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "skip returns the turn to the player")
		turns.apply_move(_attack_move(0)) # player passes with an empty move
	check(turns.try_skip_frozen_turn().is_empty(), "freeze must expire after 4 skipped turns")
	check(not turns.enemy.has_status(SK.FREEZE), "the freeze status must be gone")


func test_poison_procs_on_each_enemy_swap() -> void:
	var turns := _battle()
	turns.cast_skill(60, POISON, null) # poison damage snapshot: 2 x 5 = 10
	check_eq(turns.turn_owner, TurnManager.Owner.ENEMY, "turn passes to the enemy")
	turns.apply_move(_attack_move(0)) # enemy swaps -> poison procs
	check_eq(turns.enemy.hp, 70, "first swap must deal 10 poison damage")
	turns.apply_move(_attack_move(0)) # player turn passes
	turns.apply_move(_attack_move(0)) # enemy swaps again
	check_eq(turns.enemy.hp, 60, "second swap must deal 10 more")


func test_poison_expires_after_its_duration() -> void:
	var turns := _battle()
	turns.cast_skill(60, POISON, null)
	for i in range(5): # five enemy turns tick the status down to 0
		turns.apply_move(_attack_move(0)) # enemy acts
		if turns.turn_owner == TurnManager.Owner.PLAYER:
			turns.apply_move(_attack_move(0)) # player passes back
	check(not turns.enemy.has_status(SK.POISON_ON_SWAP), "poison must expire after 5 enemy turns")


func test_stone_skin_blocks_attack_tiles_but_amplifies_skills() -> void:
	var turns := _battle()
	turns.pass_turn() # enemy's turn
	turns.enemy.energy = 50
	var cast_outcome := turns.cast_skill(20, STONE_SKIN, null) # enemy buffs itself
	check(not cast_outcome.is_empty(), "the enemy cast must succeed")
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "turn returns to the player")
	# Attack tiles are blocked entirely.
	var effects := turns.apply_move(_attack_move(3))
	check_eq(turns.enemy.hp, 80, "attack-tile damage must be fully blocked")
	check(bool(effects[0].get("immune", false)), "the effect must be flagged immune")
	# Skill damage is amplified by 50%: 4 tiles x 5 = 20 -> 30.
	turns.apply_move(_attack_move(0)) # enemy passes back to player
	turns.player.energy = 100
	turns.cast_skill(20, FIRE_BOMB, null)
	check_eq(turns.enemy.hp, 50, "skill damage must be amplified to 30")


func test_stat_mod_effect_kind_buffs_any_stat() -> void:
	var turns := _battle()
	var armor_buff: Array[Dictionary] = [{
		"kind": "stat_mod", "stat": "armor", "amount": 4,
		"lifetime": "battle", "source": "skill_iron_wall", "target": "self",
	}]
	turns.cast_skill(20, armor_buff, null)
	check_eq(turns.player.armor, 4, "the stat_mod effect must raise armor")
	turns.player.stats.clear_lifetime(StatTypes.Lifetime.BATTLE)
	check_eq(turns.player.armor, 0, "battle-lifetime buffs must clear at battle end")


func test_keeps_turn_flag() -> void:
	var turns := _battle()
	var armor_buff: Array[Dictionary] = [{
		"kind": "stat_mod", "stat": "armor", "amount": 1,
		"lifetime": "battle", "source": "skill_quick", "target": "self",
	}]
	turns.cast_skill(10, armor_buff, null, false)
	check_eq(turns.turn_owner, TurnManager.Owner.PLAYER, "ends_turn=false must keep the caster's turn")


func test_skill_kill_wins_the_battle() -> void:
	var turns := _battle()
	turns.enemy.hp = 15
	turns.cast_skill(20, FIRE_BOMB, null)
	check_eq(turns.outcome, TurnManager.Outcome.PLAYER_WON, "a lethal skill must win the battle")
