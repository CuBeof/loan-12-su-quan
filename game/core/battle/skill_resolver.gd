class_name SkillResolver
extends RefCounted
## Executes a skill's data-driven effect list. Each entry is a Dictionary
## with a "kind" plus parameters; adding a new effect kind = one branch
## here (and possibly a StatusEffect.Kind). Current kinds:
##   damage      {attack_tiles | amount, target} — direct hit, source &"skill"
##   board_blast {width, height}                 — destroys a random board region
##   status      {status, turns, ...}            — applies a StatusEffect
##   stat_mod    {stat, amount, kind, lifetime, source, target} — StatModifier
## Returns {"effects": Array[Dictionary], "board_result": MoveResult|null}.


static func cast(effect_data: Array, caster: CombatantState, enemy: CombatantState,
		board: BoardLogic, rng: RandomNumberGenerator) -> Dictionary:
	var effects: Array[Dictionary] = []
	var board_result: MoveResult = null
	for raw in effect_data:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		var target := enemy if str(data.get("target", "enemy")) == "enemy" else caster
		match str(data.get("kind", "")):
			"damage":
				var tiles := int(data.get("attack_tiles", 0))
				var amount := int(data.get("amount", tiles * caster.attack_per_tile))
				var hit := target.take_damage(amount, caster.armor_pen, &"skill")
				effects.append({
					"kind": EffectResolver.EffectKind.DAMAGE,
					"amount": int(hit.dealt),
					"blocked": int(hit.blocked),
					"immune": bool(hit.get("immune", false)),
					"target": target,
				})
			"board_blast":
				if board != null:
					var blast := _blast_random_region(board,
							int(data.get("width", 2)), int(data.get("height", 2)), rng)
					if board_result == null:
						board_result = blast
					else:
						board_result.events.append_array(blast.events)
			"status":
				var status := StatusEffect.from_dict(data, caster)
				if status == null:
					push_warning("Unknown status in skill effect: %s" % str(data.get("status", "")))
					continue
				target.add_status(status)
				effects.append({
					"kind": EffectResolver.EffectKind.STATUS_APPLIED,
					"status": status.kind,
					"target": target,
				})
			"stat_mod":
				var mod := StatModifier.from_dict(data)
				if mod == null:
					push_warning("Invalid stat_mod in skill effect")
					continue
				target.stats.add_modifier(mod)
				effects.append({
					"kind": EffectResolver.EffectKind.STAT_CHANGED,
					"target": target,
				})
			_:
				push_warning("Unknown skill effect kind: %s" % str(data.get("kind", "")))
	return {"effects": effects, "board_result": board_result}


## Picks a random fully-on-board region and destroys it. The blast credits
## no one — it is board disruption, not a match (initial balance rule).
static func _blast_random_region(board: BoardLogic, width: int, height: int,
		rng: RandomNumberGenerator) -> MoveResult:
	var origin := Vector2i(
		rng.randi_range(0, maxi(board.size.x - width, 0)),
		rng.randi_range(0, maxi(board.size.y - height, 0)))
	var cells: Array[Vector2i] = []
	for dy in range(height):
		for dx in range(width):
			var cell := origin + Vector2i(dx, dy)
			if board.grid.has(cell):
				cells.append(cell)
	return board.blast_cells(cells)
