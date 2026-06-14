class_name SkillTree
extends Resource
## A character's full skill tree. Designers add nodes here; the screen
## lays them out and the service resolves unlock state.

@export var nodes: Array[SkillTreeNode] = []


func get_node_by_id(node_id: StringName) -> SkillTreeNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null
