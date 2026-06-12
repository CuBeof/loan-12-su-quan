class_name EffectResolver
extends RefCounted
## Maps a resolved board move onto battle effects: the mover gains
## heal/energy/gold/xp from their matched tiles, the opponent takes
## attack damage. Returns an ordered effect list for the view to present.

enum EffectKind { DAMAGE, HEAL, ENERGY, GOLD, XP, PENALTY_DAMAGE }


static func apply_move(result: MoveResult, mover: CombatantState, opponent: CombatantState) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var counts := result.cleared_counts

	var attack_tiles := int(counts.get(TileTypes.Type.ATTACK, 0))
	if attack_tiles > 0:
		var dealt := opponent.take_damage(attack_tiles * mover.attack_per_tile)
		effects.append({"kind": EffectKind.DAMAGE, "amount": dealt, "target": opponent})

	var health_tiles := int(counts.get(TileTypes.Type.HEALTH, 0))
	if health_tiles > 0:
		var restored := mover.heal(health_tiles * mover.heal_per_tile)
		effects.append({"kind": EffectKind.HEAL, "amount": restored, "target": mover})

	var energy_tiles := int(counts.get(TileTypes.Type.ENERGY, 0))
	if energy_tiles > 0:
		var gained := mover.gain_energy(energy_tiles * mover.energy_per_tile)
		effects.append({"kind": EffectKind.ENERGY, "amount": gained, "target": mover})

	var gold_tiles := int(counts.get(TileTypes.Type.GOLD, 0))
	if gold_tiles > 0:
		mover.gold += gold_tiles
		effects.append({"kind": EffectKind.GOLD, "amount": gold_tiles, "target": mover})

	var xp_tiles := int(counts.get(TileTypes.Type.EXP, 0))
	if xp_tiles > 0:
		mover.xp += xp_tiles
		effects.append({"kind": EffectKind.XP, "amount": xp_tiles, "target": mover})

	return effects


## SPEC rule: a rejected swap counts as the opponent attacking the mover
## with damage equivalent to `penalty_attack_tiles` attack tiles.
static func apply_penalty(result: MoveResult, mover: CombatantState, opponent: CombatantState) -> Array[Dictionary]:
	if result.penalty_attack_tiles <= 0:
		return []
	var dealt := mover.take_damage(result.penalty_attack_tiles * opponent.attack_per_tile)
	return [{"kind": EffectKind.PENALTY_DAMAGE, "amount": dealt, "target": mover}]
