class_name CombatantDefinition
extends Resource
## Designer-editable definition of a combatant (player character or
## enemy). Real art is assigned later in the Inspector; the view falls
## back to `color` while `portrait` is empty.

@export var id: StringName
@export var display_name_key: StringName # translation key, resolve with tr()
@export var portrait: Texture2D
@export var color: Color = Color.GRAY

@export_group("Stats")
@export var max_hp: int = 100
@export var max_energy: int = 50
@export var attack_per_tile: int = 5
@export var heal_per_tile: int = 4
@export var energy_per_tile: int = 5
