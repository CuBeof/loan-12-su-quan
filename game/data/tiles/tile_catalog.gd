class_name TileCatalog
extends Resource
## Maps TileTypes.Type to its TileDefinition. Single place where the
## five tile definitions are wired together.

@export var attack: TileDefinition
@export var health: TileDefinition
@export var gold: TileDefinition
@export var energy: TileDefinition
@export var experience: TileDefinition


func get_def(type: int) -> TileDefinition:
	match type:
		TileTypes.Type.ATTACK:
			return attack
		TileTypes.Type.HEALTH:
			return health
		TileTypes.Type.GOLD:
			return gold
		TileTypes.Type.ENERGY:
			return energy
		TileTypes.Type.EXP:
			return experience
	return null
