class_name EffectResolver
extends RefCounted
## Maps a resolved board move onto battle effects: the mover gains
## heal/energy/gold/xp from their matched tiles, the opponent takes
## attack damage. Returns an ordered effect list for the view to present.

enum EffectKind { DAMAGE, HEAL, ENERGY, GOLD, XP, PENALTY_DAMAGE, STATUS_APPLIED, STAT_CHANGED, TURN_FROZEN }


## Support effects (heal/energy/gold/xp) for one CLEARED wave's tile
## counts, applied to the mover immediately. Attack damage is handled
## separately by TurnManager.apply_attack_wave. Applied per wave (not at
## move end) so resources collected in a winning move's cascade still bank.
static func apply_support(counts: Dictionary, mover: CombatantState) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []

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
## with damage equivalent to `penalty_attack_tiles` attack tiles. Armor
## and armor penetration apply exactly like a normal attack.
static func apply_penalty(result: MoveResult, mover: CombatantState, opponent: CombatantState) -> Array[Dictionary]:
	if result.penalty_attack_tiles <= 0:
		return []
	var hit := mover.take_damage(result.penalty_attack_tiles * opponent.attack_per_tile, opponent.armor_pen, &"attack_tiles")
	return [{
		"kind": EffectKind.PENALTY_DAMAGE,
		"amount": int(hit.dealt),
		"blocked": int(hit.blocked),
		"immune": bool(hit.get("immune", false)),
		"target": mover,
	}]
