class_name StatusEffect
extends RefCounted
## A timed battle condition on one combatant (freeze, poison, immunity,
## vulnerability...). Adding a new mechanic = one Kind entry + one branch
## where it acts (take_damage or TurnManager). Durations tick in turns
## and statuses never outlive the battle.

enum Kind {
	FREEZE, # owner skips their turns
	POISON_ON_SWAP, # owner takes params.damage every time they swap
	SOURCE_IMMUNITY, # immune to damage tagged params.source
	DAMAGE_TAKEN_PERCENT, # +params.percent damage taken, except params.exclude_source
}

const KIND_NAMES: Dictionary = {
	Kind.FREEZE: &"freeze",
	Kind.POISON_ON_SWAP: &"poison_on_swap",
	Kind.SOURCE_IMMUNITY: &"source_immunity",
	Kind.DAMAGE_TAKEN_PERCENT: &"damage_taken_percent",
}

var kind: int
var turns_left: int = 1
var params: Dictionary = {}
var source: StringName # the skill that applied it


static func make(kind_: int, turns_: int, params_: Dictionary = {}, source_: StringName = &"") -> StatusEffect:
	var status := StatusEffect.new()
	status.kind = kind_
	status.turns_left = turns_
	status.params = params_
	status.source = source_
	return status


static func kind_from_name(name: StringName) -> int:
	for kind: int in KIND_NAMES:
		if KIND_NAMES[kind] == name:
			return kind
	return -1


## Builds a status from a skill-effect dict. Caster stats are snapshotted
## at cast time (e.g. poison damage), so the status carries no references.
static func from_dict(data: Dictionary, caster: CombatantState) -> StatusEffect:
	var kind_ := kind_from_name(StringName(str(data.get("status", ""))))
	if kind_ < 0:
		return null
	var turns_ := int(data.get("turns", 1))
	var params_ := {}
	match kind_:
		Kind.POISON_ON_SWAP:
			var default_damage := int(data.get("attack_tiles", 0)) * caster.attack_per_tile
			params_["damage"] = int(data.get("damage", default_damage))
		Kind.SOURCE_IMMUNITY:
			params_["source"] = str(data.get("source", "attack_tiles"))
		Kind.DAMAGE_TAKEN_PERCENT:
			params_["percent"] = int(data.get("percent", 0))
			params_["exclude_source"] = str(data.get("exclude_source", ""))
	return make(kind_, turns_, params_, StringName(str(data.get("source_skill", ""))))
