class_name ItemDefinition
extends Resource
## Designer-editable item. `effects` is the same data-driven dict list
## used by skills:
## - EQUIPMENT: stat_mod entries applied while equipped, e.g.
##     {"kind": "stat_mod", "stat": "armor", "amount": 5}
##   (ItemService forces a removable per-item source on equip).
## - CONSUMABLE: applied once on use, e.g. {"kind": "heal", "amount": 50},
##   or stat_mod with lifetime "run" for battle-prep buffs.
## New items are .tres files; balance lives in the values.

enum Kind { EQUIPMENT, CONSUMABLE }

@export var id: StringName
@export var display_name_key: StringName # translation key
@export var description_key: StringName # translation key
@export var icon: Texture2D # assigned later
@export var color: Color = Color.GRAY # placeholder swatch until icon exists
@export var kind: Kind = Kind.CONSUMABLE
@export var price: int = 100
@export var effects: Array[Dictionary] = []
