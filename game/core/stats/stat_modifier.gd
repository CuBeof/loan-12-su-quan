class_name StatModifier
extends RefCounted
## One adjustment to one stat, tagged with its origin and lifetime.
## Every armor (or any stat) source — gear, items, skills, NPC buffs,
## map-region passives — is just an instance of this class:
##   StatModifier.make(Stat.ARMOR, 2, &"equip_iron_vest", Lifetime.PERMANENT)

enum Kind { FLAT, PERCENT } # PERCENT amount of 25 = +25%

const KIND_NAMES: Dictionary = {
	Kind.FLAT: &"flat",
	Kind.PERCENT: &"percent",
}

var stat: int
var amount: int = 0
var kind: int = Kind.FLAT
var source: StringName # e.g. &"equip_iron_vest", &"region_warlord_keep"
var lifetime: int = StatTypes.Lifetime.BATTLE


static func make(stat_: int, amount_: int, source_: StringName, lifetime_: int,
		kind_: int = Kind.FLAT) -> StatModifier:
	var mod := StatModifier.new()
	mod.stat = stat_
	mod.amount = amount_
	mod.source = source_
	mod.lifetime = lifetime_
	mod.kind = kind_
	return mod


func to_dict() -> Dictionary:
	return {
		"stat": String(StatTypes.stat_name(stat)),
		"amount": amount,
		"kind": String(KIND_NAMES.get(kind, &"flat")),
		"source": String(source),
		"lifetime": String(StatTypes.lifetime_name(lifetime)),
	}


## Returns null for data this version doesn't understand (forward compat).
## Reads "mod_kind" for flat/percent first so effect dicts can use "kind"
## for their own effect type without colliding.
static func from_dict(data: Dictionary) -> StatModifier:
	var stat_ := StatTypes.stat_from_name(StringName(str(data.get("stat", ""))))
	var lifetime_ := StatTypes.lifetime_from_name(StringName(str(data.get("lifetime", ""))))
	if stat_ < 0 or lifetime_ < 0:
		return null
	var kind_ := Kind.FLAT
	var kind_name := str(data.get("mod_kind", data.get("kind", "flat")))
	for candidate: int in KIND_NAMES:
		if String(KIND_NAMES[candidate]) == kind_name:
			kind_ = candidate
	return make(stat_, int(data.get("amount", 0)), StringName(str(data.get("source", ""))), lifetime_, kind_)
