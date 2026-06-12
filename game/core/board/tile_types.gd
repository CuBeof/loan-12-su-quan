class_name TileTypes
## Shared enums for the match-3 board. Pure data, no state.

enum Type { ATTACK, HEALTH, GOLD, ENERGY, EXP }

enum Special {
	NONE,
	SWEEP_H, # clears its whole row when activated
	SWEEP_V, # clears its whole column when activated
	BOMB, # clears a 3x3 area when activated
	TRANSFORM, # swap with any tile to consume every tile of that type
}

const TYPE_COUNT := 5
