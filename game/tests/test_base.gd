class_name BoardTestBase
extends RefCounted
## Minimal assertion helpers for the headless test runner.

var failures: Array[String] = []

# Letter map for building boards from string rows:
# a=ATTACK h=HEALTH g=GOLD e=ENERGY x=EXP
const CHAR_TO_TYPE := {
	"a": TileTypes.Type.ATTACK,
	"h": TileTypes.Type.HEALTH,
	"g": TileTypes.Type.GOLD,
	"e": TileTypes.Type.ENERGY,
	"x": TileTypes.Type.EXP,
}


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (got %s, expected %s)" % [message, str(actual), str(expected)])


## Builds a deterministic board from string rows. Refill is disabled so
## tests stay deterministic; the layout must not contain pre-made matches.
func make_board(rows: Array[String]) -> BoardLogic:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(rows[0].length(), rows.size()))
	board.refill_enabled = false
	board.rng.seed = 12345
	for y in range(rows.size()):
		var row := rows[y]
		for x in range(row.length()):
			var letter := row[x]
			board.grid[Vector2i(x, y)] = TileState.make(CHAR_TO_TYPE[letter])
	check(MatchFinder.find_groups(board.grid).is_empty(), "test layout contains a pre-made match — fix the layout")
	return board
