class_name PlayerProfile
extends RefCounted
## The player's persistent progress — the single thing the save system
## stores. New progression data later (lives, inventory, skill tree...)
## is added here with a serialization default, never as loose globals.

var character_id: StringName = &"hero"
var level: int = 1
var xp: int = 0
var gold: int = 0
var current_hp: int = -1 # -1 = full; SPEC: lost HP persists between battles
var cleared_nodes: Dictionary = {} # map node id (StringName) -> true
var stats := StatBlock.new()


func max_hp() -> int:
	return stats.get_value(StatTypes.Stat.MAX_HP)


func to_dict() -> Dictionary:
	var nodes_out: Array = []
	for node_id: StringName in cleared_nodes:
		nodes_out.append(String(node_id))
	return {
		"character_id": String(character_id),
		"level": level,
		"xp": xp,
		"gold": gold,
		"current_hp": current_hp,
		"cleared_nodes": nodes_out,
		"stats": stats.to_dict(),
	}


static func from_dict(data: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.character_id = StringName(str(data.get("character_id", "hero")))
	profile.level = int(data.get("level", 1))
	profile.xp = int(data.get("xp", 0))
	profile.gold = int(data.get("gold", 0))
	profile.current_hp = int(data.get("current_hp", -1))
	for node_id in data.get("cleared_nodes", []):
		profile.cleared_nodes[StringName(str(node_id))] = true
	profile.stats = StatBlock.from_dict(data.get("stats", {}))
	return profile
