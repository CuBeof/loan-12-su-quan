class_name AIController
extends RefCounted
## Decides the AI's action each turn from a data-driven AIProfile. Pure
## logic: it simulates try_move() on a clone of the board (never the real
## one) and scores the outcome by the profile's tile weights. Skills are
## passed in as lightweight dicts {cost, effects} so this layer stays free
## of the data/ resources.
##
## Returns one of:
##   {"type": "skill", "index": i}     cast skills[i]
##   {"type": "move",  "a": .., "b": ..}
##   {"type": "pass"}                  no legal move (shouldn't happen)


static func choose_action(board: BoardLogic, mover: CombatantState, opponent: CombatantState,
		skills: Array, profile: AIProfile, rng: RandomNumberGenerator) -> Dictionary:
	# 1) Maybe cast an affordable, still-useful skill.
	var castable: Array[int] = []
	for i in range(skills.size()):
		var skill: Dictionary = skills[i]
		if mover.energy >= int(skill.get("cost", 0)) \
				and skill_worth_casting(skill.get("effects", []), mover, opponent):
			castable.append(i)
	if not castable.is_empty() and rng.randf() < profile.skill_chance:
		return {"type": "skill", "index": castable[rng.randi_range(0, castable.size() - 1)]}

	# 2) Otherwise pick a board move.
	var moves := MoveGenerator.find_moves(board.grid)
	if moves.is_empty():
		return {"type": "pass"}
	# Weaker AIs (lower difficulty) sometimes pick a random move instead.
	if rng.randf() > profile.difficulty:
		var random: Dictionary = moves[rng.randi_range(0, moves.size() - 1)]
		return {"type": "move", "a": random.a, "b": random.b}

	var values_energy := not skills.is_empty()
	var best: Dictionary = moves[0]
	var best_score := -INF
	for move in moves:
		var sim := board.clone()
		var result := sim.try_move(move.a, move.b)
		var score := score_move(result, mover, profile, values_energy)
		if score > best_score:
			best_score = score
			best = move
	return {"type": "move", "a": best.a, "b": best.b}


## Value of a resolved move to `mover`: sum of cleared tiles times their
## profile weight, plus bonuses for extra turns and created specials.
static func score_move(result: MoveResult, mover: CombatantState, profile: AIProfile,
		values_energy: bool) -> float:
	var score := 0.0
	for type: int in result.cleared_counts:
		score += int(result.cleared_counts[type]) * _tile_weight(type, mover, profile, values_energy)
	if result.extra_turn:
		score += profile.extra_turn_bonus
	for event in result.events:
		if event.kind == BoardEvent.Kind.SPECIAL_CREATED:
			score += profile.special_bonus
	return score


static func _tile_weight(type: int, mover: CombatantState, profile: AIProfile,
		values_energy: bool) -> float:
	match type:
		TileTypes.Type.ATTACK:
			return profile.weight_attack
		TileTypes.Type.HEALTH:
			# Worthless at full HP, scales up as HP drops.
			var cap := maxi(mover.max_hp, 1)
			var missing := clampf(1.0 - float(mover.hp) / float(cap), 0.0, 1.0)
			return profile.weight_health * missing * profile.low_hp_heal_scale
		TileTypes.Type.GOLD:
			return profile.weight_gold
		TileTypes.Type.ENERGY:
			if not values_energy or mover.max_energy <= 0 or mover.energy >= mover.max_energy:
				return 0.0
			return profile.weight_energy
		TileTypes.Type.EXP:
			return profile.weight_exp
	return 0.0


## A skill is worth casting unless every effect is a status its target
## already has (avoids wasting energy re-applying active buffs/debuffs).
static func skill_worth_casting(effects: Array, mover: CombatantState, opponent: CombatantState) -> bool:
	for raw in effects:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		if str(data.get("kind", "")) != "status":
			return true
		var status_kind := StatusEffect.kind_from_name(StringName(str(data.get("status", ""))))
		var target := opponent if str(data.get("target", "enemy")) == "enemy" else mover
		if status_kind >= 0 and not target.has_status(status_kind):
			return true
	return false
