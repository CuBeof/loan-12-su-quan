class_name StatBlock
extends RefCounted
## Base values plus a modifier list, with cached final values.
## The one rule of the stat system: nothing ever writes a final stat —
## systems add or remove modifiers, the block computes the result:
##   final = (base + sum of FLAT) * (100 + sum of PERCENT) / 100, min 0.

var _base: Dictionary = {} # StatTypes.Stat -> int
var _modifiers: Array[StatModifier] = []
var _cache: Dictionary = {} # StatTypes.Stat -> int


func set_base(stat: int, value: int) -> void:
	_base[stat] = value
	_cache.clear()


func get_base(stat: int) -> int:
	return int(_base.get(stat, 0))


func get_value(stat: int) -> int:
	if _cache.has(stat):
		return int(_cache[stat])
	var total := int(_base.get(stat, 0))
	var percent := 100
	for mod in _modifiers:
		if mod.stat != stat:
			continue
		if mod.kind == StatModifier.Kind.FLAT:
			total += mod.amount
		else:
			percent += mod.amount
	total = maxi(int(total * percent / 100.0), 0)
	_cache[stat] = total
	return total


func add_modifier(mod: StatModifier) -> void:
	_modifiers.append(mod)
	_cache.clear()


## Removes every modifier from one source (e.g. unequipping an item).
func remove_source(source: StringName) -> void:
	for i in range(_modifiers.size() - 1, -1, -1):
		if _modifiers[i].source == source:
			_modifiers.remove_at(i)
	_cache.clear()


## Expires all modifiers of a lifetime (e.g. BATTLE at battle end).
func clear_lifetime(lifetime: int) -> void:
	for i in range(_modifiers.size() - 1, -1, -1):
		if _modifiers[i].lifetime == lifetime:
			_modifiers.remove_at(i)
	_cache.clear()


func modifier_count() -> int:
	return _modifiers.size()


## Serializes by stat NAME (not enum index) so saves survive new stats
## being added in any order. BATTLE modifiers are never persisted.
func to_dict() -> Dictionary:
	var base_out := {}
	for stat: int in _base:
		base_out[String(StatTypes.stat_name(stat))] = int(_base[stat])
	var mods_out: Array = []
	for mod in _modifiers:
		if mod.lifetime == StatTypes.Lifetime.BATTLE:
			continue
		mods_out.append(mod.to_dict())
	return {"base": base_out, "modifiers": mods_out}


static func from_dict(data: Dictionary) -> StatBlock:
	var block := StatBlock.new()
	var base_in: Dictionary = data.get("base", {})
	for key: String in base_in:
		var stat := StatTypes.stat_from_name(StringName(key))
		if stat >= 0: # unknown stats from newer versions are skipped, not fatal
			block._base[stat] = int(base_in[key])
	for mod_data in data.get("modifiers", []):
		if mod_data is Dictionary:
			var mod := StatModifier.from_dict(mod_data)
			if mod != null:
				block._modifiers.append(mod)
	return block
