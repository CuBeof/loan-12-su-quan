class_name StatTypes
## Stat catalog and serialization names. Adding a new stat = one enum
## entry + one name row; saves stay compatible because they store names,
## not enum indices.

enum Stat {
	MAX_HP,
	MAX_ENERGY,
	ATTACK_PER_TILE,
	HEAL_PER_TILE,
	ENERGY_PER_TILE,
	ARMOR,
	ARMOR_PEN,
}

## How long a modifier lives — this is what the engine acts on:
## PERMANENT: part of the character (level-ups, equipped gear). Saved.
## RUN: persists across battles (items, NPC blessings). Saved.
## BATTLE: in-battle only (skills, region passives). Never saved.
enum Lifetime { PERMANENT, RUN, BATTLE }

const STAT_NAMES: Dictionary = {
	Stat.MAX_HP: &"max_hp",
	Stat.MAX_ENERGY: &"max_energy",
	Stat.ATTACK_PER_TILE: &"attack_per_tile",
	Stat.HEAL_PER_TILE: &"heal_per_tile",
	Stat.ENERGY_PER_TILE: &"energy_per_tile",
	Stat.ARMOR: &"armor",
	Stat.ARMOR_PEN: &"armor_pen",
}

const LIFETIME_NAMES: Dictionary = {
	Lifetime.PERMANENT: &"permanent",
	Lifetime.RUN: &"run",
	Lifetime.BATTLE: &"battle",
}


static func stat_name(stat: int) -> StringName:
	return STAT_NAMES.get(stat, &"")


## Returns -1 for unknown names so loaders can skip stats from newer
## game versions instead of corrupting the profile.
static func stat_from_name(name: StringName) -> int:
	for stat: int in STAT_NAMES:
		if STAT_NAMES[stat] == name:
			return stat
	return -1


static func lifetime_name(lifetime: int) -> StringName:
	return LIFETIME_NAMES.get(lifetime, &"")


static func lifetime_from_name(name: StringName) -> int:
	for lifetime: int in LIFETIME_NAMES:
		if LIFETIME_NAMES[lifetime] == name:
			return lifetime
	return -1
