class_name SkillTreeNode
extends Resource
## One node in a character's skill tree. Unlocking it (with skill points)
## either applies permanent stat modifiers and/or grants a new battle
## skill. New nodes are .tres files; balance lives in the values.

@export var id: StringName
@export var display_name_key: StringName
@export var description_key: StringName
@export var icon: Texture2D # assigned later
@export var cost: int = 1 # skill points
@export var prerequisites: Array[StringName] = [] # node ids that must be unlocked first
@export var pos: Vector2 = Vector2(0.5, 0.5) # screen ratio for tree layout
## StatModifier dicts (the service forces source + permanent lifetime).
@export var stat_mods: Array[Dictionary] = []
@export var granted_skill: SkillDefinition # optional skill this node unlocks
