class_name ItemService
extends RefCounted
## Pure inventory/shop rules operating on a PlayerProfile. Items are
## referenced by id; effects come in as the definition's dict list so
## this layer never touches Resources. Gold is validated BEFORE spending.

const EQUIP_SOURCE_PREFIX := "equip_"


static func count(profile: PlayerProfile, item_id: StringName) -> int:
	return int(profile.inventory.get(item_id, 0))


static func is_equipped(profile: PlayerProfile, item_id: StringName) -> bool:
	return profile.equipped.has(item_id)


static func can_buy(profile: PlayerProfile, price: int) -> bool:
	return profile != null and profile.gold >= price


static func buy(profile: PlayerProfile, item_id: StringName, price: int) -> bool:
	if not can_buy(profile, price):
		return false
	profile.gold -= price
	profile.inventory[item_id] = count(profile, item_id) + 1
	return true


## Equips an owned item: its stat_mod effects become modifiers tagged
## with a per-item source so unequip can remove exactly them. Equipping
## does not consume the item.
static func equip(profile: PlayerProfile, item_id: StringName, effects: Array) -> bool:
	if profile == null or count(profile, item_id) <= 0 or is_equipped(profile, item_id):
		return false
	for raw in effects:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		if str(data.get("kind", "")) != "stat_mod":
			continue
		var mod_data := data.duplicate()
		mod_data["source"] = String(equip_source(item_id))
		mod_data["lifetime"] = str(data.get("lifetime", "permanent"))
		var mod := StatModifier.from_dict(mod_data)
		if mod != null:
			profile.stats.add_modifier(mod)
	profile.equipped.append(item_id)
	return true


static func unequip(profile: PlayerProfile, item_id: StringName) -> bool:
	if profile == null or not is_equipped(profile, item_id):
		return false
	profile.stats.remove_source(equip_source(item_id))
	profile.equipped.erase(item_id)
	return true


static func equip_source(item_id: StringName) -> StringName:
	return StringName(EQUIP_SOURCE_PREFIX + String(item_id))


## A consumable is usable when at least one of its effects would do
## something (e.g. heal requires missing HP).
static func can_use(profile: PlayerProfile, effects: Array) -> bool:
	if profile == null:
		return false
	for raw in effects:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		match str(data.get("kind", "")):
			"heal":
				if profile.current_hp >= 0 and profile.current_hp < profile.max_hp():
					return true
			"stat_mod":
				return true
	return false


## Consumes one copy and applies the effects to the profile.
static func use(profile: PlayerProfile, item_id: StringName, effects: Array) -> bool:
	if profile == null or count(profile, item_id) <= 0 or not can_use(profile, effects):
		return false
	var remaining := count(profile, item_id) - 1
	if remaining <= 0:
		profile.inventory.erase(item_id)
	else:
		profile.inventory[item_id] = remaining
	for raw in effects:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		match str(data.get("kind", "")):
			"heal":
				_heal(profile, int(data.get("amount", 0)))
			"stat_mod":
				var mod := StatModifier.from_dict(data)
				if mod != null:
					profile.stats.add_modifier(mod)
	return true


static func _heal(profile: PlayerProfile, amount: int) -> void:
	if profile.current_hp < 0:
		return # already full
	profile.current_hp = mini(profile.current_hp + amount, profile.max_hp())
