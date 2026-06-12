class_name TileDefinition
extends Resource
## Visual/audio definition of one tile type. Real assets are assigned
## later in the Inspector; the view falls back to color + drawn glyph
## while `texture` is empty.

@export var id: StringName
@export var display_name_key: StringName # translation key, resolve with tr()
@export var color: Color = Color.GRAY
@export var texture: Texture2D
@export var match_sfx: StringName = &"tile_match"
