extends BoardTestBase
## Unit tests for the behavior-profile AI (AIController + AIProfile):
## move scoring per personality, board-clone lookahead, skill decisions
## and determinism.

const TY := TileTypes.Type


func _aggressive() -> AIProfile:
	var profile := AIProfile.new()
	profile.difficulty = 1.0
	profile.skill_chance = 0.0
	profile.weight_attack = 5.0
	profile.weight_health = 1.0
	profile.low_hp_heal_scale = 2.0
	return profile


func _healer() -> AIProfile:
	var profile := AIProfile.new()
	profile.difficulty = 1.0
	profile.skill_chance = 0.0
	profile.weight_attack = 1.5
	profile.weight_health = 5.0
	profile.low_hp_heal_scale = 4.0
	return profile


func _result(counts: Dictionary) -> MoveResult:
	var result := MoveResult.new()
	result.valid = true
	result.cleared_counts = counts
	return result


func test_clone_does_not_touch_the_real_board() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 5)
	var before := board.snapshot()
	var copy := board.clone()
	copy.try_move(Vector2i(0, 0), Vector2i(1, 0)) # mutate the clone heavily
	check_eq(board.snapshot(), before, "simulating on a clone must leave the real board untouched")


func test_aggressive_prefers_attack_over_heal() -> void:
	var profile := _aggressive()
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	mover.hp = 50 # even when hurt, the aggressor values attack more
	var attack_score := AIController.score_move(_result({TY.ATTACK: 3}), mover, profile, false)
	var heal_score := AIController.score_move(_result({TY.HEALTH: 3}), mover, profile, false)
	check(attack_score > heal_score, "aggressive profile must rank an attack match above a heal match")


func test_healer_prefers_heal_when_hurt() -> void:
	var profile := _healer()
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	mover.hp = 40
	var attack_score := AIController.score_move(_result({TY.ATTACK: 3}), mover, profile, false)
	var heal_score := AIController.score_move(_result({TY.HEALTH: 3}), mover, profile, false)
	check(heal_score > attack_score, "a hurt healer must rank a heal match above an attack match")


func test_heal_is_worthless_at_full_hp() -> void:
	var profile := _healer()
	var mover := CombatantState.make(100, 5, 4, 5, 50) # full HP
	var heal_score := AIController.score_move(_result({TY.HEALTH: 5}), mover, profile, false)
	check_eq(heal_score, 0.0, "healing tiles must score 0 at full HP")
	var attack_score := AIController.score_move(_result({TY.ATTACK: 3}), mover, profile, false)
	check(attack_score > heal_score, "at full HP even a healer takes the attack")


func test_extra_turn_and_combo_bonuses_count() -> void:
	var profile := _aggressive()
	profile.extra_turn_bonus = 6.0
	profile.special_bonus = 4.0
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	var plain := _result({TY.GOLD: 3})
	var fancy := _result({TY.GOLD: 3})
	fancy.extra_turns = 1 # +6
	fancy.max_combo = 2 # (2-1) * 4 = +4
	var gain := AIController.score_move(fancy, mover, profile, false) \
			- AIController.score_move(plain, mover, profile, false)
	check_eq(gain, 10.0, "extra turn (6) + combo bonus (4) must add 10 to the score")


func test_energy_only_valued_when_skills_and_room() -> void:
	var profile := _aggressive()
	profile.weight_energy = 2.0
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	check_eq(AIController.score_move(_result({TY.ENERGY: 2}), mover, profile, false), 0.0,
			"no skills means energy is worthless")
	check(AIController.score_move(_result({TY.ENERGY: 2}), mover, profile, true) > 0.0,
			"with skills, energy has value when there is room")
	mover.energy = mover.max_energy
	check_eq(AIController.score_move(_result({TY.ENERGY: 2}), mover, profile, true), 0.0,
			"full energy is worthless even with skills")


func test_choose_action_picks_the_scored_argmax() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 21)
	var profile := _aggressive()
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	var opponent := CombatantState.make(100, 5, 4, 5, 50)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var action := AIController.choose_action(board, mover, opponent, [], profile, rng)
	check_eq(str(action.type), "move", "with no skills the AI must move")
	# Independently compute the expected best move.
	var best: Dictionary = {}
	var best_score := -INF
	for move in MoveGenerator.find_moves(board.grid):
		var sim := board.clone()
		var score := AIController.score_move(sim.try_move(move.a, move.b), mover, profile, false)
		if score > best_score:
			best_score = score
			best = move
	check_eq(action.a, best.a, "chosen move must be the scored argmax (a)")
	check_eq(action.b, best.b, "chosen move must be the scored argmax (b)")


func test_choose_action_is_deterministic_per_seed() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 33)
	var profile := _healer()
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	var opponent := CombatantState.make(100, 5, 4, 5, 50)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 7
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 7
	var a := AIController.choose_action(board, mover, opponent, [], profile, rng_a)
	var b := AIController.choose_action(board, mover, opponent, [], profile, rng_b)
	check_eq(a, b, "same board and seed must yield the same action")


func test_low_difficulty_still_returns_a_legal_move() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 4)
	var profile := _aggressive()
	profile.difficulty = 0.0 # always random
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var action := AIController.choose_action(board, mover, CombatantState.make(100, 5, 4, 5, 50), [], profile, rng)
	var legal := MoveGenerator.find_moves(board.grid)
	var found := false
	for move in legal:
		if move.a == action.a and move.b == action.b:
			found = true
	check(found, "even a random low-difficulty AI must return a legal move")


func test_ai_casts_affordable_useful_skill() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 8)
	var profile := _aggressive()
	profile.skill_chance = 1.0 # always cast when possible
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	mover.energy = 50
	var opponent := CombatantState.make(100, 5, 4, 5, 50)
	var skills: Array = [{"cost": 20, "effects": [
		{"kind": "status", "status": "source_immunity", "source": "attack_tiles", "turns": 3, "target": "self"},
	]}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var action := AIController.choose_action(board, mover, opponent, skills, profile, rng)
	check_eq(str(action.type), "skill", "an affordable useful skill must be cast")
	check_eq(int(action.index), 0, "the castable skill index must be returned")


func test_ai_skips_skill_it_cannot_afford() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 8)
	var profile := _aggressive()
	profile.skill_chance = 1.0
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	mover.energy = 10 # cannot pay 20
	var skills: Array = [{"cost": 20, "effects": [{"kind": "damage", "attack_tiles": 4}]}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var action := AIController.choose_action(board, mover, CombatantState.make(100, 5, 4, 5, 50), skills, profile, rng)
	check_eq(str(action.type), "move", "an unaffordable skill must be skipped for a move")


func test_ai_does_not_recast_active_status() -> void:
	var profile := _aggressive()
	var mover := CombatantState.make(100, 5, 4, 5, 50)
	var opponent := CombatantState.make(100, 5, 4, 5, 50)
	var effects: Array = [{"kind": "status", "status": "freeze", "turns": 4, "target": "enemy"}]
	check(AIController.skill_worth_casting(effects, mover, opponent), "freeze is worth casting on a non-frozen enemy")
	opponent.add_status(StatusEffect.make(StatusEffect.Kind.FREEZE, 4))
	check(not AIController.skill_worth_casting(effects, mover, opponent),
			"re-freezing an already-frozen enemy is not worth it")
