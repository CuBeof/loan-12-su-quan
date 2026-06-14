class_name SkillTreeService
extends RefCounted
## Pure skill-tree unlock rules over a PlayerProfile. Takes node data as
## primitives (id/cost/prereqs/stat_mods) so the core never references the
## SkillTreeNode resource or its assets. Spent points and applied stat
## modifiers persist via the profile's serialization.

const SOURCE_PREFIX := "skilltree_"


static func is_unlocked(profile: PlayerProfile, node_id: StringName) -> bool:
	return profile != null and profile.unlocked_nodes.has(node_id)


static func prereqs_met(profile: PlayerProfile, prerequisites: Array) -> bool:
	for prereq in prerequisites:
		if not is_unlocked(profile, StringName(str(prereq))):
			return false
	return true


static func can_unlock(profile: PlayerProfile, node_id: StringName, cost: int, prerequisites: Array) -> bool:
	return profile != null \
		and not is_unlocked(profile, node_id) \
		and profile.skill_points >= cost \
		and prereqs_met(profile, prerequisites)


## Spends the cost, marks the node unlocked, and applies its stat
## modifiers as PERMANENT (so they serialize and can be removed by source
## if a respec feature ever lands).
static func unlock(profile: PlayerProfile, node_id: StringName, cost: int,
		prerequisites: Array, stat_mods: Array) -> bool:
	if not can_unlock(profile, node_id, cost, prerequisites):
		return false
	profile.skill_points -= cost
	profile.unlocked_nodes.append(node_id)
	for raw in stat_mods:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw.duplicate()
		data["source"] = SOURCE_PREFIX + String(node_id)
		data["lifetime"] = "permanent"
		var mod := StatModifier.from_dict(data)
		if mod != null:
			profile.stats.add_modifier(mod)
	return true
