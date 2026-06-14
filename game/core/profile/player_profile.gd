class_name PlayerProfile
extends RefCounted
## The player's persistent progress — the single thing the save system
## stores. New progression data later (lives, inventory, skill tree...)
## is added here with a serialization default, never as loose globals.

var character_id: StringName = &"hero"
var level: int = 1
var xp: int = 0 # progress toward the next level
var skill_points: int = 0
var gold: int = 0
var current_hp: int = -1 # -1 = full; SPEC: lost HP persists between battles
var cleared_nodes: Dictionary = {} # map node id (StringName) -> true
var inventory: Dictionary = {} # item id (StringName) -> count
var equipped: Array[StringName] = [] # currently worn equipment ids
var unlocked_nodes: Array[StringName] = [] # skill-tree node ids unlocked
var stats := StatBlock.new()


func max_hp() -> int:
	return stats.get_value(StatTypes.Stat.MAX_HP)


func to_dict() -> Dictionary:
	var nodes_out: Array = []
	for node_id: StringName in cleared_nodes:
		nodes_out.append(String(node_id))
	var inventory_out := {}
	for item_id: StringName in inventory:
		inventory_out[String(item_id)] = int(inventory[item_id])
	var equipped_out: Array = []
	for item_id in equipped:
		equipped_out.append(String(item_id))
	var unlocked_out: Array = []
	for node_id in unlocked_nodes:
		unlocked_out.append(String(node_id))
	return {
		"character_id": String(character_id),
		"level": level,
		"xp": xp,
		"skill_points": skill_points,
		"gold": gold,
		"current_hp": current_hp,
		"cleared_nodes": nodes_out,
		"inventory": inventory_out,
		"equipped": equipped_out,
		"unlocked_nodes": unlocked_out,
		"stats": stats.to_dict(),
	}


static func from_dict(data: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.character_id = StringName(str(data.get("character_id", "hero")))
	profile.level = int(data.get("level", 1))
	profile.xp = int(data.get("xp", 0))
	profile.skill_points = int(data.get("skill_points", 0))
	profile.gold = int(data.get("gold", 0))
	profile.current_hp = int(data.get("current_hp", -1))
	for node_id in data.get("cleared_nodes", []):
		profile.cleared_nodes[StringName(str(node_id))] = true
	var inventory_in: Dictionary = data.get("inventory", {})
	for key: String in inventory_in:
		profile.inventory[StringName(key)] = int(inventory_in[key])
	for item_id in data.get("equipped", []):
		profile.equipped.append(StringName(str(item_id)))
	for node_id in data.get("unlocked_nodes", []):
		profile.unlocked_nodes.append(StringName(str(node_id)))
	profile.stats = StatBlock.from_dict(data.get("stats", {}))
	return profile
