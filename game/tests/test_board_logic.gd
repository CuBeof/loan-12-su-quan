extends BoardTestBase
## Unit tests for the pure board logic with the new match rules:
##   match-4 -> +1 extra turn; match-5 -> +1 extra turn + destroy 3 random;
##   L/T -> destroy 3 around the junction. Enhanced tiles count double and
##   each cascade wave multiplies its cleared value by the combo.

const TY := TileTypes.Type


func _cleared_events(result: MoveResult) -> Array:
	var out: Array = []
	for event in result.events:
		if event.kind == BoardEvent.Kind.CLEARED:
			out.append(event)
	return out


func _first_cleared(result: MoveResult) -> Dictionary:
	var events := _cleared_events(result)
	return events[0].data if not events.is_empty() else {}


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
		if board_a.grid[cell].type != board_b.grid[cell].type:
			failures.append("same seed produced different boards at %s" % str(cell))
			return


func test_blocked_cells_stay_empty() -> void:
	var blocked: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 3)]
	var board := BoardLogic.new()
	board.setup(Vector2i(4, 4), 7, blocked)
	check(not board.grid.has(Vector2i(0, 0)), "blocked cell (0,0) still holds a tile")
	check_eq(board.grid.size(), 14, "wrong tile count on a board with blocked cells")


func test_non_adjacent_move_is_invalid() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var result := board.try_move(Vector2i(0, 0), Vector2i(2, 0))
	check(not result.valid, "non-adjacent move must be rejected")
	check(result.events.is_empty(), "non-adjacent move must produce no events")


func test_swap_without_match_is_rejected_with_penalty() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var before := board.snapshot()
	var result := board.try_move(Vector2i(0, 0), Vector2i(1, 0))
	check(not result.valid, "swap without a match must be invalid")
	check_eq(result.events[1].kind, BoardEvent.Kind.SWAP_REJECTED, "second event must be SWAP_REJECTED")
	check_eq(result.penalty_attack_tiles, 2, "a rejected swap carries the 2-attack-tile penalty")
	check_eq(board.snapshot(), before, "board must revert after a rejected swap")


func test_match3_clears_and_tallies_no_extra_turn() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap creating a match-3 must be valid")
	var first: Dictionary = _first_cleared(result)
	check_eq(int(first.counts.get(TY.GOLD, 0)), 3, "exactly 3 gold cleared at combo 1")
	check_eq(result.extra_turns, 0, "match-3 grants no extra turn")
	check(first.lightning.is_empty(), "match-3 triggers no lightning")


func test_match4_grants_one_extra_turn() -> void:
	var board := make_board([
		"ahehae",
		"hahaha",
		"ggageh",
		"heghae",
	])
	var result := board.try_move(Vector2i(2, 3), Vector2i(2, 2))
	check(result.valid, "swap creating a match-4 must be valid")
	var first: Dictionary = _first_cleared(result)
	check_eq(int(first.counts.get(TY.GOLD, 0)), 4, "match-4 clears 4 gold")
	check(bool(first.extra_turn), "the match-4 wave is flagged as granting an extra turn")
	check_eq(result.extra_turns, 1, "match-4 grants exactly one extra turn")
	check(first.lightning.is_empty(), "match-4 triggers no lightning")


func test_match5_grants_extra_turn_and_destroys_three() -> void:
	var board := make_board([
		"ahehae",
		"hegaha",
		"ggaggh",
		"heheae",
	])
	var result := board.try_move(Vector2i(2, 1), Vector2i(2, 2))
	check(result.valid, "swap creating a match-5 must be valid")
	var first: Dictionary = _first_cleared(result)
	check_eq(result.extra_turns, 1, "match-5 grants one extra turn")
	check_eq(first.lightning.size(), 3, "match-5 destroys 3 random tiles (lightning targets)")
	check_eq(first.cells.size(), 8, "first wave clears 5 matched + 3 destroyed")


func test_l_shape_destroys_three_around_no_extra_turn() -> void:
	var board := make_board([
		"ageha",
		"hgaeh",
		"eagge",
		"hgeah",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap creating an L-shape must be valid")
	var first: Dictionary = _first_cleared(result)
	check_eq(result.extra_turns, 0, "an L/T grants no extra turn")
	check_eq(first.lightning.size(), 3, "an L/T destroys 3 tiles around the junction")
	check_eq(first.cells.size(), 8, "first wave clears 5 matched + 3 around")


func test_enhanced_tile_counts_double() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	# Make one of the three matched gold tiles enhanced (it lines up at x=1).
	board.grid[Vector2i(0, 2)].enhanced = true # (0,2)=g, part of the gold match
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap must be valid")
	var first: Dictionary = _first_cleared(result)
	check_eq(int(first.counts.get(TY.GOLD, 0)), 4, "3 gold with one enhanced counts as 2+1+1 = 4")


func test_combo_multiplies_later_waves() -> void:
	# This layout cascades: the swap clears one wave, then gravity forms a
	# second match at combo 2 whose value is doubled.
	var board := make_board([
		"gexex",
		"xaxhg",
		"aeehe",
		"eeaee",
		"gaxag",
	])
	var result := board.try_move(Vector2i(2, 2), Vector2i(2, 3))
	check(result.valid, "the cascading swap must be valid")
	check(result.max_combo >= 2, "a cascade must raise the combo to at least 2")
	var waves := _cleared_events(result)
	check(waves.size() >= 2, "there must be at least two clear waves")
	var wave2: BoardEvent = waves[1]
	check_eq(int(wave2.data.combo), 2, "the second wave is combo 2")
	var total := 0
	for type: int in wave2.data.counts:
		total += int(wave2.data.counts[type])
	check_eq(total, 2 * wave2.data.cells.size(), "combo-2 wave value is doubled (no enhanced tiles)")


func test_extra_turns_capped_in_result() -> void:
	var result := MoveResult.new()
	for i in range(5):
		result.grant_extra_turn()
	check_eq(result.extra_turns, 2, "a single move never grants more than +2 extra turns")


func test_gravity_compacts_columns() -> void:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(3, 3))
	board.refill_enabled = false
	board.grid[Vector2i(0, 0)] = TileState.make(TY.ATTACK)
	board.grid[Vector2i(2, 0)] = TileState.make(TY.GOLD)
	board.grid[Vector2i(2, 1)] = TileState.make(TY.HEALTH)
	var result := MoveResult.new()
	board.apply_gravity(result)
	check(board.grid.has(Vector2i(0, 2)), "column 0 tile must fall to the bottom")
	check(board.grid.has(Vector2i(2, 2)) and board.grid.has(Vector2i(2, 1)), "column 2 must compact to the bottom")
	check(not board.grid.has(Vector2i(0, 0)), "the top must be empty after falling")


func test_refill_fills_every_valid_cell() -> void:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(4, 4))
	board.rng.seed = 5
	var result := MoveResult.new()
	board.apply_gravity(result)
	check_eq(board.grid.size(), 16, "refill must fill every valid cell")


func test_dead_board_gets_reshuffled() -> void:
	var board := make_board([
		"ahg",
		"hge",
		"gex",
	])
	var result := MoveResult.new()
	board._ensure_moves(result)
	check(MoveGenerator.has_move(board.grid), "the board must have a move after reshuffle")
	check_eq(result.events[0].kind, BoardEvent.Kind.SHUFFLED, "a dead board emits a SHUFFLED event")


func test_random_play_keeps_board_consistent() -> void:
	var fuzz_rng := RandomNumberGenerator.new()
	fuzz_rng.seed = 2026
	for game in range(3):
		var board := BoardLogic.new()
		board.setup(Vector2i(8, 8), fuzz_rng.randi())
		for move_index in range(100):
			var moves := MoveGenerator.find_moves(board.grid)
			if moves.is_empty():
				failures.append("game %d move %d: no moves left despite reshuffle" % [game, move_index])
				return
			var move: Dictionary = moves[fuzz_rng.randi_range(0, moves.size() - 1)]
			var result := board.try_move(move.a, move.b)
			if not result.valid:
				failures.append("game %d move %d: a found move was rejected" % [game, move_index])
				return
			if board.grid.size() != 64:
				failures.append("game %d move %d: board has %d/64 cells" % [game, move_index, board.grid.size()])
				return
			if not MatchFinder.find_groups(board.grid).is_empty():
				failures.append("game %d move %d: unresolved match after the move" % [game, move_index])
				return
			if result.extra_turns > 2:
				failures.append("game %d move %d: extra_turns exceeded the cap" % [game, move_index])
				return


func test_find_hint_returns_a_legal_two_tile_move() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 3)
	var hint := board.find_hint()
	check(not hint.is_empty(), "a fresh board must offer a hint")
	if hint.is_empty():
		return
	check_eq(hint.cells.size(), 2, "the hint highlights exactly the two tiles to swap")
	var found := false
	for move in MoveGenerator.find_moves(board.grid):
		if move.a == hint.a and move.b == hint.b:
			found = true
	check(found, "the hinted move must be legal")


func test_blast_cells_clears_and_settles() -> void:
	var board := BoardLogic.new()
	board.setup(Vector2i(8, 8), 4)
	var targets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var result := board.blast_cells(targets)
	check(result.valid, "blasting present cells is a valid result")
	check(result.total_cleared() >= 3, "at least the 3 blasted tiles are cleared")
	check_eq(board.grid.size(), 64, "the board refills after a blast")
