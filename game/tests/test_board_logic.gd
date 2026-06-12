extends BoardTestBase
## Unit tests for the pure board logic. Each rule row of the special-tile
## matrix in SPEC.md gets at least one test here.

const SP := TileTypes.Special
const TY := TileTypes.Type


func test_setup_has_no_initial_match_and_has_moves() -> void:
	for seed_value in range(1, 11):
		var board := BoardLogic.new()
		board.setup(Vector2i(8, 8), seed_value)
		check(MatchFinder.find_groups(board.grid).is_empty(), "seed %d: board has a pre-made match after setup" % seed_value)
		check(not MoveGenerator.find_moves(board.grid).is_empty(), "seed %d: board has no possible move" % seed_value)
		check_eq(board.grid.size(), 64, "seed %d: board is not fully filled" % seed_value)


func test_setup_is_deterministic_per_seed() -> void:
	var board_a := BoardLogic.new()
	var board_b := BoardLogic.new()
	board_a.setup(Vector2i(8, 8), 99)
	board_b.setup(Vector2i(8, 8), 99)
	for cell: Vector2i in board_a.grid.keys():
		var tile_a: TileState = board_a.grid[cell]
		var tile_b: TileState = board_b.grid[cell]
		if tile_a.type != tile_b.type:
			failures.append("same seed produced different boards at %s" % str(cell))
			return


func test_blocked_cells_stay_empty() -> void:
	var blocked: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 3)]
	var board := BoardLogic.new()
	board.setup(Vector2i(4, 4), 7, blocked)
	check(not board.grid.has(Vector2i(0, 0)), "blocked cell (0,0) still holds a tile")
	check(not board.grid.has(Vector2i(3, 3)), "blocked cell (3,3) still holds a tile")
	check_eq(board.grid.size(), 14, "wrong tile count on a board with blocked cells")


func test_non_adjacent_move_is_invalid() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var result := board.try_move(Vector2i(0, 0), Vector2i(2, 0))
	check(not result.valid, "non-adjacent move must be rejected")
	check(result.events.is_empty(), "non-adjacent move must produce no events")


func test_swap_without_match_is_rejected_and_reverted() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var before := board.snapshot()
	var result := board.try_move(Vector2i(0, 0), Vector2i(1, 0))
	check(not result.valid, "swap without a match must be invalid")
	check_eq(result.events.size(), 2, "exactly 2 events expected: SWAP + SWAP_REJECTED")
	check_eq(result.events[1].kind, BoardEvent.Kind.SWAP_REJECTED, "second event must be SWAP_REJECTED")
	var after := board.snapshot()
	check_eq(after, before, "board must revert after a rejected swap")


## SPEC rule: a rejected swap counts as an enemy attack worth 2 attack
## tiles. Valid moves and non-swaps carry no penalty.
func test_rejected_swap_carries_attack_penalty() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var rejected := board.try_move(Vector2i(0, 0), Vector2i(1, 0))
	check_eq(rejected.penalty_attack_tiles, 2, "rejected swap must carry a 2-attack-tile penalty")

	var non_adjacent := board.try_move(Vector2i(0, 0), Vector2i(2, 0))
	check_eq(non_adjacent.penalty_attack_tiles, 0, "non-adjacent attempt is not a swap, no penalty")

	var valid_board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var valid := valid_board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(valid.valid, "swap must be valid")
	check_eq(valid.penalty_attack_tiles, 0, "valid move must carry no penalty")


func test_match3_clears_and_tallies() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap creating a match-3 must be valid")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "exactly 3 gold tiles must be cleared")
	check(not result.extra_turn, "match-3 must not grant an extra turn")
	check(not board.grid.has(Vector2i(1, 0)), "column 1 top cell must be empty after falling (refill off)")


func test_match4_horizontal_creates_sweeper_and_extra_turn() -> void:
	var board := make_board([
		"ahehae",
		"hahaha",
		"ggageh",
		"heghae",
	])
	var result := board.try_move(Vector2i(2, 3), Vector2i(2, 2))
	check(result.valid, "swap creating a match-4 must be valid")
	check(result.extra_turn, "match-4 must grant an extra turn")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 4, "exactly 4 gold tiles must be cleared")
	var special_tile: TileState = board.grid.get(Vector2i(2, 2))
	check(special_tile != null, "a special tile must appear at the swap cell")
	if special_tile != null:
		check_eq(special_tile.special, SP.SWEEP_V, "horizontal match-4 must create a vertical sweeper")
		check_eq(special_tile.type, TY.GOLD, "the sweeper must keep the gold type")


func test_match5_creates_transformer() -> void:
	var board := make_board([
		"ahehae",
		"hegaha",
		"ggaggh",
		"heheae",
	])
	var result := board.try_move(Vector2i(2, 1), Vector2i(2, 2))
	check(result.valid, "swap creating a match-5 must be valid")
	check(result.extra_turn, "match-5 must grant an extra turn")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 5, "exactly 5 gold tiles must be cleared")
	var special_tile: TileState = board.grid.get(Vector2i(2, 2))
	check(special_tile != null and special_tile.special == SP.TRANSFORM, "match-5 must create a transform tile")


func test_l_shape_creates_bomb_without_extra_turn() -> void:
	var board := make_board([
		"ageha",
		"hgaeh",
		"eagge",
		"hgeah",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap creating an L-shape must be valid")
	check(not result.extra_turn, "L-shape (3+3) must not grant an extra turn")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 5, "L-shape must clear 5 tiles")
	var special_tile: TileState = board.grid.get(Vector2i(1, 2))
	check(special_tile != null and special_tile.special == SP.BOMB, "L-shape must create a bomb")


func test_sweeper_in_match_clears_whole_row() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var sweeper: TileState = board.grid[Vector2i(0, 2)]
	sweeper.special = SP.SWEEP_H
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap must be valid")
	check_eq(result.total_cleared(), 5, "horizontal sweeper must clear the whole 5-cell row")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "3 gold tiles in the row")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 1, "1 health tile in the row")
	check_eq(int(result.cleared_counts.get(TY.ENERGY, 0)), 1, "1 energy tile in the row")


## Candy Crush wrapped: the bomb blasts 3x3, survives, falls, then
## blasts 3x3 again where it lands before disappearing.
func test_bomb_in_match_detonates_twice() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var bomb: TileState = board.grid[Vector2i(0, 2)]
	bomb.special = SP.BOMB
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap must be valid")
	check_eq(result.total_cleared(), 9, "double blast must clear 9 tiles (6 first + 3 second)")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "3 gold tiles (2 matched + the bomb)")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 3, "3 health tiles across both blasts")
	check_eq(int(result.cleared_counts.get(TY.ATTACK, 0)), 3, "3 attack tiles across both blasts")
	var primed_events := 0
	var cleared_events := 0
	for event in result.events:
		if event.kind == BoardEvent.Kind.BOMB_PRIMED:
			primed_events += 1
		elif event.kind == BoardEvent.Kind.CLEARED:
			cleared_events += 1
	check_eq(primed_events, 1, "exactly 1 BOMB_PRIMED event expected")
	check_eq(cleared_events, 2, "exactly 2 CLEARED waves expected")
	for cell: Vector2i in board.grid.keys():
		var tile: TileState = board.grid[cell]
		if tile.special == SP.BOMB:
			failures.append("bomb still on the board after its double blast")
			return


func test_transform_swapped_with_normal_clears_all_of_type() -> void:
	var board := make_board([
		"ahah",
		"haha",
		"ahah",
	])
	board.grid[Vector2i(0, 0)] = TileState.make(TY.GOLD, SP.TRANSFORM)
	var result := board.try_move(Vector2i(0, 0), Vector2i(0, 1))
	check(result.valid, "transform + normal tile must be valid")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 6, "all 6 health tiles must be cleared")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 1, "the transform tile must be consumed too")


func test_bomb_plus_bomb_grants_extra_turn_and_5x5() -> void:
	var board := make_board([
		"ahah",
		"haha",
		"ahah",
	])
	board.grid[Vector2i(1, 1)] = TileState.make(TY.GOLD, SP.BOMB)
	board.grid[Vector2i(2, 1)] = TileState.make(TY.ENERGY, SP.BOMB)
	var result := board.try_move(Vector2i(1, 1), Vector2i(2, 1))
	check(result.valid, "bomb + bomb must be valid")
	check(result.extra_turn, "bomb + bomb must grant an extra turn")
	check_eq(result.total_cleared(), 12, "the 5x5 blast must cover the whole 4x3 board")


func test_bomb_plus_sweeper_clears_giant_cross() -> void:
	var board := make_board([
		"ahaha",
		"hahah",
		"ahaha",
		"hahah",
		"ahaha",
	])
	board.grid[Vector2i(2, 2)] = TileState.make(TY.GOLD, SP.BOMB)
	board.grid[Vector2i(2, 3)] = TileState.make(TY.ENERGY, SP.SWEEP_H)
	var result := board.try_move(Vector2i(2, 2), Vector2i(2, 3))
	check(result.valid, "bomb + sweeper must be valid")
	# Candy Crush giant cross centered (2,3): rows 2-4 + cols 1-3 on 5x5
	# = 15 + 15 - 9 overlap = 21
	check_eq(result.total_cleared(), 21, "bomb + sweeper must clear 3 rows and 3 columns")


func test_sweeper_plus_sweeper_clears_cross() -> void:
	var board := make_board([
		"ahaha",
		"hahah",
		"ahaha",
		"hahah",
		"ahaha",
	])
	board.grid[Vector2i(2, 2)] = TileState.make(TY.GOLD, SP.SWEEP_H)
	board.grid[Vector2i(2, 3)] = TileState.make(TY.ENERGY, SP.SWEEP_V)
	var result := board.try_move(Vector2i(2, 2), Vector2i(2, 3))
	check(result.valid, "sweeper + sweeper must be valid")
	check(not result.extra_turn, "sweeper + sweeper must not grant an extra turn")
	# First CLEARED event: cross = row 3 (5 cells) + column 2 (5 cells) - 1 overlap
	check_eq(result.events[1].kind, BoardEvent.Kind.CLEARED, "second event must be CLEARED")
	var first_cleared: Array[Vector2i] = result.events[1].data.cells
	check_eq(first_cleared.size(), 9, "the cross must clear 1 row + 1 column = 9 cells")


## Candy Crush: a color bomb caught in a blast activates passively,
## consuming every tile of one random type.
func test_transform_hit_by_blast_activates() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var sweeper: TileState = board.grid[Vector2i(0, 2)]
	sweeper.special = SP.SWEEP_H
	var transform: TileState = board.grid[Vector2i(4, 2)]
	transform.special = SP.TRANSFORM
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap must be valid")
	check(result.total_cleared() >= 5, "at least the swept row must be cleared")
	for cell: Vector2i in board.grid.keys():
		var tile: TileState = board.grid[cell]
		if tile.special == SP.TRANSFORM:
			failures.append("the transform tile must be consumed when hit by a blast")
			return


func test_dead_board_gets_reshuffled() -> void:
	# 3x3 with no possible move after the swap resolves would need a crafted
	# dead end; instead verify _ensure_moves directly on a dead layout.
	var board := make_board([
		"ahg",
		"hge",
		"gex",
	])
	var result := MoveResult.new()
	board._ensure_moves(result)
	if MoveGenerator.find_moves(board.grid).is_empty():
		failures.append("still no possible move after reshuffle")
	check(not result.events.is_empty(), "a dead board must emit a SHUFFLED event")
	if not result.events.is_empty():
		check_eq(result.events[0].kind, BoardEvent.Kind.SHUFFLED, "the event must be SHUFFLED")


## Fuzz: plays hundreds of random valid moves; catches crashes and
## invariant breaks in rare combos (edge bombs, stacked cascades).
func test_random_play_keeps_board_consistent() -> void:
	var fuzz_rng := RandomNumberGenerator.new()
	fuzz_rng.seed = 2026
	for game in range(3):
		var board := BoardLogic.new()
		board.setup(Vector2i(8, 8), fuzz_rng.randi())
		for move_index in range(100):
			var moves := MoveGenerator.find_moves(board.grid)
			if moves.is_empty():
				failures.append("game %d move %d: no moves left despite the reshuffle mechanism" % [game, move_index])
				return
			var move: Dictionary = moves[fuzz_rng.randi_range(0, moves.size() - 1)]
			var result := board.try_move(move.a, move.b)
			if not result.valid:
				failures.append("game %d move %d: a move found by MoveGenerator was rejected" % [game, move_index])
				return
			if board.grid.size() != 64:
				failures.append("game %d move %d: board has %d/64 cells after refill" % [game, move_index, board.grid.size()])
				return
			if not MatchFinder.find_groups(board.grid).is_empty():
				failures.append("game %d move %d: unresolved match left after the move finished" % [game, move_index])
				return
			if not board._pending_bombs.is_empty() or not board._pending_blasts.is_empty():
				failures.append("game %d move %d: pending blasts left after settle" % [game, move_index])
				return


func test_find_hint_returns_a_legal_resolving_move() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 3)
	var hint := board.find_hint()
	check(not hint.is_empty(), "a fresh playable board must offer a hint")
	if hint.is_empty():
		return
	var legal := MoveGenerator.find_moves(board.grid)
	var found := false
	for move in legal:
		if move.a == hint.a and move.b == hint.b:
			found = true
	check(found, "the hint must be one of the legal moves")
	var tile_a: TileState = board.grid[hint.a]
	var tile_b: TileState = board.grid[hint.b]
	if not MoveGenerator.is_special_combo(tile_a, tile_b):
		board._swap_tiles(hint.a, hint.b)
		check(not MatchFinder.find_groups(board.grid).is_empty(), "the hinted swap must create a match")
		board._swap_tiles(hint.a, hint.b)
	check(hint.cells.size() >= 2, "the hint must highlight at least the swapped pair")


func test_find_hint_prefers_the_largest_match() -> void:
	# Swapping the central 'h' (2,0) with the 'a' below it (2,1) turns row 0
	# into a 5-line of 'a' — a stronger move than any plain 3-match.
	var board := make_board([
		"aahaa",
		"hhahh",
		"aahaa",
	])
	var hint := board.find_hint()
	check(not hint.is_empty(), "hint must exist")
	check(hint.cells.size() >= 4, "hint should pick the move clearing the most tiles")


func test_gravity_compacts_columns() -> void:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(3, 3))
	board.refill_enabled = false
	board.rng.seed = 1
	board.grid[Vector2i(0, 0)] = TileState.make(TY.ATTACK)
	board.grid[Vector2i(2, 0)] = TileState.make(TY.GOLD)
	board.grid[Vector2i(2, 1)] = TileState.make(TY.HEALTH)
	var result := MoveResult.new()
	board.apply_gravity(result)
	check(board.grid.has(Vector2i(0, 2)), "column 0 tile must fall to the bottom")
	check(board.grid.has(Vector2i(2, 2)) and board.grid.has(Vector2i(2, 1)), "column 2 must compact to the bottom")
	check(not board.grid.has(Vector2i(0, 0)) and not board.grid.has(Vector2i(2, 0)), "the top row must be empty")


func test_refill_fills_every_valid_cell() -> void:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(4, 4))
	board.rng.seed = 5
	var result := MoveResult.new()
	board.apply_gravity(result)
	check_eq(board.grid.size(), 16, "refill must fill every valid cell")
	check_eq(result.events.size(), 1, "exactly 1 GRAVITY event expected")
