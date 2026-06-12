class_name SkillDefinition
extends Resource
## Designer-editable skill. `effects` is a data-driven list interpreted
## by SkillResolver — new skills are new .tres files, no code. Each entry:
##   {"kind": "damage", "attack_tiles": 4, "target": "enemy"}
##   {"kind": "board_blast", "width": 2, "height": 2}
##   {"kind": "status", "status": "freeze", "turns": 4, "target": "enemy"}
##   {"kind": "stat_mod", "stat": "armor", "amount": 4, "kind2"...}
## Balance lives entirely in the .tres values.

@export var id: StringName
@export var display_name_key: StringName # translation key
@export var description_key: StringName # translation key
@export var icon: Texture2D # assigned later; buttons show text until then
@export var energy_cost: int = 20
@export var ends_turn: bool = true # casting uses up the turn by default
@export var effects: Array[Dictionary] = []
