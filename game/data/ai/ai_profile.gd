class_name AIProfile
extends Resource
## Designer-editable behavior profile for an AI combatant. The AIController
## scores every legal move by how many tiles of each type it clears times
## these weights, so different enemies play differently with zero code —
## an attacker weights ATTACK high, a healer weights HEALTH high. Pure data
## (numbers only); a new AI personality is a new .tres.

@export_range(0.0, 1.0, 0.05) var difficulty: float = 0.8 # chance to pick the best move vs a random one
@export_range(0.0, 1.0, 0.05) var skill_chance: float = 0.5 # per-turn chance to cast an affordable, useful skill
@export var extra_turn_bonus: float = 6.0 # value of a move that grants another turn
@export var special_bonus: float = 4.0 # value of creating a special tile (greed)

@export_group("Tile weights")
@export var weight_attack: float = 3.0
@export var weight_health: float = 2.0
@export var weight_gold: float = 1.0
@export var weight_energy: float = 1.5
@export var weight_exp: float = 0.5
## How strongly low HP boosts the value of HEALTH tiles. The health weight
## scales with the fraction of HP missing, so healing at full HP is ignored.
@export var low_hp_heal_scale: float = 3.0
