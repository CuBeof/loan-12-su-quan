class_name CombatantState
extends RefCounted
## Runtime battle state of one combatant. All stats are read through a
## StatBlock, so any system (gear, items, skills, NPC buffs, map-region
## passives) adjusts them by adding modifiers — never by writing values.

var stats := StatBlock.new()
var statuses: Array[StatusEffect] = [] # battle-only timed conditions
var hp: int
var energy: int = 0
var gold: int = 0 # earned this battle, awarded only on victory (SPEC)
var xp: int = 0 # earned this battle, awarded only on victory (SPEC)

var max_hp: int:
	get:
		return stats.get_value(StatTypes.Stat.MAX_HP)
var max_energy: int:
	get:
		return stats.get_value(StatTypes.Stat.MAX_ENERGY)
var attack_per_tile: int:
	get:
		return stats.get_value(StatTypes.Stat.ATTACK_PER_TILE)
var heal_per_tile: int:
	get:
		return stats.get_value(StatTypes.Stat.HEAL_PER_TILE)
var energy_per_tile: int:
	get:
		return stats.get_value(StatTypes.Stat.ENERGY_PER_TILE)
var armor: int:
	get:
		return stats.get_value(StatTypes.Stat.ARMOR)
var armor_pen: int:
	get:
		return stats.get_value(StatTypes.Stat.ARMOR_PEN)
var crit_chance: int:
	get:
		return stats.get_value(StatTypes.Stat.CRIT_CHANCE)
var crit_damage: int:
	get:
		return stats.get_value(StatTypes.Stat.CRIT_DAMAGE)
var luck: int:
	get:
		return stats.get_value(StatTypes.Stat.LUCK)


static func make(max_hp_: int, attack_per_tile_: int, heal_per_tile_: int,
		energy_per_tile_: int, max_energy_: int, armor_: int = 0, armor_pen_: int = 0,
		crit_chance_: int = 0, crit_damage_: int = 150, luck_: int = 0) -> CombatantState:
	var state := CombatantState.new()
	state.stats.set_base(StatTypes.Stat.MAX_HP, max_hp_)
	state.stats.set_base(StatTypes.Stat.ATTACK_PER_TILE, attack_per_tile_)
	state.stats.set_base(StatTypes.Stat.HEAL_PER_TILE, heal_per_tile_)
	state.stats.set_base(StatTypes.Stat.ENERGY_PER_TILE, energy_per_tile_)
	state.stats.set_base(StatTypes.Stat.MAX_ENERGY, max_energy_)
	state.stats.set_base(StatTypes.Stat.ARMOR, armor_)
	state.stats.set_base(StatTypes.Stat.ARMOR_PEN, armor_pen_)
	state.stats.set_base(StatTypes.Stat.CRIT_CHANCE, crit_chance_)
	state.stats.set_base(StatTypes.Stat.CRIT_DAMAGE, crit_damage_)
	state.stats.set_base(StatTypes.Stat.LUCK, luck_)
	state.hp = state.max_hp
	return state


## Wraps an existing StatBlock (the player profile's). Modifiers added
## during battle (skills) land on the shared block; the battle controller
## clears the BATTLE lifetime when the fight ends.
static func from_block(block: StatBlock, hp_override: int = -1) -> CombatantState:
	var state := CombatantState.new()
	state.stats = block
	var cap := state.max_hp
	state.hp = cap if hp_override < 0 else clampi(hp_override, 0, cap)
	return state


func is_alive() -> bool:
	return hp > 0


func add_status(status: StatusEffect) -> void:
	statuses.append(status)


func has_status(kind: int) -> bool:
	return first_status(kind) != null


func first_status(kind: int) -> StatusEffect:
	for status in statuses:
		if status.kind == kind:
			return status
	return null


## Applies damage through statuses then armor, in this order:
## 1. SOURCE_IMMUNITY for the damage's source tag -> 0 damage;
## 2. DAMAGE_TAKEN_PERCENT increases the raw amount;
## 3. armor (reduced by the attacker's pen) blocks, min 1 always passes.
## Source tags: &"attack_tiles" (board matches + invalid-swap penalty),
## &"skill", &"poison" — new mechanics add new tags freely.
func take_damage(amount: int, attacker_armor_pen: int = 0, source: StringName = &"generic") -> Dictionary:
	var blocked := 0
	var through := amount
	if amount > 0:
		for status in statuses:
			if status.kind == StatusEffect.Kind.SOURCE_IMMUNITY \
					and StringName(str(status.params.get("source", ""))) == source:
				return {"dealt": 0, "blocked": amount, "immune": true}
		var boosted := amount
		for status in statuses:
			if status.kind == StatusEffect.Kind.DAMAGE_TAKEN_PERCENT \
					and StringName(str(status.params.get("exclude_source", ""))) != source:
				boosted += int(amount * int(status.params.get("percent", 0)) / 100.0)
		var effective_armor := maxi(armor - attacker_armor_pen, 0)
		blocked = mini(effective_armor, boosted - 1)
		through = boosted - blocked
	var dealt := mini(through, hp)
	hp -= dealt
	return {"dealt": dealt, "blocked": blocked, "immune": false}


## Returns the HP actually restored (no overheal yet — character-specific
## overheal buffs come later per SPEC).
func heal(amount: int) -> int:
	var restored := mini(amount, max_hp - hp)
	hp += restored
	return restored


## Returns the energy actually gained.
func gain_energy(amount: int) -> int:
	var gained := mini(amount, max_energy - energy)
	energy += gained
	return gained
