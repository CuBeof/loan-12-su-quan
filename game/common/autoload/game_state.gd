extends Node
## Cross-scene game state: the chosen player character, the current battle
## target, and map progress. The save/meta layer (Phase 6) will persist
## this; for now it lives only for the session.

const HERO_PATH := "res://data/combatants/hero.tres"

var player_def: CombatantDefinition
var current_enemy: CombatantDefinition # set by the map before launching a battle
var current_node: StringName = &"" # map node that started the current battle
var cleared_nodes: Dictionary = {} # StringName -> true
var last_battle_won: bool = false


func _ready() -> void:
	player_def = load(HERO_PATH) as CombatantDefinition


## Resets progress for a brand-new game (keeps the chosen character).
func reset_progress() -> void:
	current_enemy = null
	current_node = &""
	cleared_nodes.clear()
	last_battle_won = false


func is_node_cleared(node_id: StringName) -> bool:
	return cleared_nodes.has(node_id)


func mark_node_cleared(node_id: StringName) -> void:
	if node_id != &"":
		cleared_nodes[node_id] = true
