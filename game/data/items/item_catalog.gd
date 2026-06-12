class_name ItemCatalog
extends Resource
## Registry of every item in the game, so saved item ids resolve back
## to definitions. Add new items here when creating their .tres.

@export var items: Array[ItemDefinition] = []


func get_def(item_id: StringName) -> ItemDefinition:
	for item in items:
		if item.id == item_id:
			return item
	return null
