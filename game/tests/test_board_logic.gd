extends BoardTestBase
## Unit tests for the pure board logic. Each rule row of the special-tile
## matrix in PLAN.md gets at least one test here.

const SP := TileTypes.Special
const TY := TileTypes.Type


func test_setup_has_no_initial_match_and_has_moves() -> void:
	for seed_value in range(1, 11):
		var board := BoardLogic.new()
		board.setup(Vector2i(8, 8), seed_value)
		check(MatchFinder.find_groups(board.grid).is_empty(), "seed %d: có match sẵn sau setup" % seed_value)
		check(not MoveGenerator.find_moves(board.grid).is_empty(), "seed %d: không có nước đi nào" % seed_value)
		check_eq(board.grid.size(), 64, "seed %d: bàn cờ chưa đầy" % seed_value)


func test_setup_is_deterministic_per_seed() -> void:
	var board_a := BoardLogic.new()
	var board_b := BoardLogic.new()
	board_a.setup(Vector2i(8, 8), 99)
	board_b.setup(Vector2i(8, 8), 99)
	for cell: Vector2i in board_a.grid.keys():
		var tile_a: TileState = board_a.grid[cell]
		var tile_b: TileState = board_b.grid[cell]
		if tile_a.type != tile_b.type:
			failures.append("cùng seed nhưng khác bàn cờ tại %s" % str(cell))
			return


func test_blocked_cells_stay_empty() -> void:
	var blocked: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 3)]
	var board := BoardLogic.new()
	board.setup(Vector2i(4, 4), 7, blocked)
	check(not board.grid.has(Vector2i(0, 0)), "ô bị chặn (0,0) vẫn có tile")
	check(not board.grid.has(Vector2i(3, 3)), "ô bị chặn (3,3) vẫn có tile")
	check_eq(board.grid.size(), 14, "số tile sai trên bàn cờ có ô chặn")


func test_non_adjacent_move_is_invalid() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var result := board.try_move(Vector2i(0, 0), Vector2i(2, 0))
	check(not result.valid, "nước đi không kề nhau phải bị từ chối")
	check(result.events.is_empty(), "nước đi không kề nhau không được sinh event")


func test_swap_without_match_is_rejected_and_reverted() -> void:
	var board := make_board(["ahah", "haha", "ahah"])
	var before := board.snapshot()
	var result := board.try_move(Vector2i(0, 0), Vector2i(1, 0))
	check(not result.valid, "swap không tạo match phải invalid")
	check_eq(result.events.size(), 2, "phải có đúng 2 event SWAP + SWAP_REJECTED")
	check_eq(result.events[1].kind, BoardEvent.Kind.SWAP_REJECTED, "event thứ 2 phải là SWAP_REJECTED")
	var after := board.snapshot()
	check_eq(after, before, "bàn cờ phải trở về như cũ sau swap hỏng")


func test_match3_clears_and_tallies() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap tạo match-3 phải hợp lệ")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "phải ăn đúng 3 viên vàng")
	check(not result.extra_turn, "match-3 không được thêm lượt")
	check(not board.grid.has(Vector2i(1, 0)), "cột 1 phải trống ô trên cùng sau khi rơi (refill tắt)")


func test_match4_horizontal_creates_sweeper_and_extra_turn() -> void:
	var board := make_board([
		"ahehae",
		"hahaha",
		"ggageh",
		"heghae",
	])
	var result := board.try_move(Vector2i(2, 3), Vector2i(2, 2))
	check(result.valid, "swap tạo match-4 phải hợp lệ")
	check(result.extra_turn, "match-4 phải được thêm lượt")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 4, "phải ăn đúng 4 viên vàng")
	var special_tile: TileState = board.grid.get(Vector2i(2, 2))
	check(special_tile != null, "phải có viên đặc biệt tại ô swap")
	if special_tile != null:
		check_eq(special_tile.special, SP.SWEEP_V, "ghép 4 ngang phải tạo viên quét dọc")
		check_eq(special_tile.type, TY.GOLD, "viên quét phải cùng loại vàng")


func test_match5_creates_transformer() -> void:
	var board := make_board([
		"ahehae",
		"hegaha",
		"ggaggh",
		"heheae",
	])
	var result := board.try_move(Vector2i(2, 1), Vector2i(2, 2))
	check(result.valid, "swap tạo match-5 phải hợp lệ")
	check(result.extra_turn, "match-5 phải được thêm lượt")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 5, "phải ăn đúng 5 viên vàng")
	var special_tile: TileState = board.grid.get(Vector2i(2, 2))
	check(special_tile != null and special_tile.special == SP.TRANSFORM, "ghép 5 phải tạo viên biến đổi")


func test_l_shape_creates_bomb_without_extra_turn() -> void:
	var board := make_board([
		"ageha",
		"hgaeh",
		"eagge",
		"hgeah",
	])
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap tạo hình L phải hợp lệ")
	check(not result.extra_turn, "hình L (3+3) không được thêm lượt")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 5, "hình L phải ăn 5 viên")
	var special_tile: TileState = board.grid.get(Vector2i(1, 2))
	check(special_tile != null and special_tile.special == SP.BOMB, "hình L phải tạo viên nổ")


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
	check(result.valid, "swap phải hợp lệ")
	check_eq(result.total_cleared(), 5, "viên quét ngang phải ăn cả hàng 5 ô")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "3 viên vàng trong hàng")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 1, "1 viên máu trong hàng")
	check_eq(int(result.cleared_counts.get(TY.ENERGY, 0)), 1, "1 viên năng lượng trong hàng")


func test_bomb_in_match_clears_3x3() -> void:
	var board := make_board([
		"aheha",
		"hahah",
		"gaghe",
		"hgeha",
	])
	var bomb: TileState = board.grid[Vector2i(0, 2)]
	bomb.special = SP.BOMB
	var result := board.try_move(Vector2i(1, 3), Vector2i(1, 2))
	check(result.valid, "swap phải hợp lệ")
	check_eq(result.total_cleared(), 7, "viên nổ phải ăn match 3 + vùng 3x3 quanh nó")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 3, "3 viên vàng")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 2, "2 viên máu trong vùng nổ")
	check_eq(int(result.cleared_counts.get(TY.ATTACK, 0)), 2, "2 viên tấn công trong vùng nổ")


func test_transform_swapped_with_normal_clears_all_of_type() -> void:
	var board := make_board([
		"ahah",
		"haha",
		"ahah",
	])
	board.grid[Vector2i(0, 0)] = TileState.make(TY.GOLD, SP.TRANSFORM)
	var result := board.try_move(Vector2i(0, 0), Vector2i(0, 1))
	check(result.valid, "biến đổi + viên thường phải hợp lệ")
	check_eq(int(result.cleared_counts.get(TY.HEALTH, 0)), 6, "phải ăn toàn bộ 6 viên máu")
	check_eq(int(result.cleared_counts.get(TY.GOLD, 0)), 1, "viên biến đổi cũng bị tiêu thụ")


func test_bomb_plus_bomb_grants_extra_turn_and_5x5() -> void:
	var board := make_board([
		"ahah",
		"haha",
		"ahah",
	])
	board.grid[Vector2i(1, 1)] = TileState.make(TY.GOLD, SP.BOMB)
	board.grid[Vector2i(2, 1)] = TileState.make(TY.ENERGY, SP.BOMB)
	var result := board.try_move(Vector2i(1, 1), Vector2i(2, 1))
	check(result.valid, "nổ + nổ phải hợp lệ")
	check(result.extra_turn, "nổ + nổ phải thêm lượt")
	check_eq(result.total_cleared(), 12, "vụ nổ 5x5 phải phủ toàn bàn 4x3")


func test_bomb_plus_sweeper_clears_two_rows_and_columns() -> void:
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
	check(result.valid, "nổ + quét phải hợp lệ")
	# 2 rows (y=2,3) + 2 columns (x=2,3) on 5x5 = 10 + 10 - 4 overlap = 16
	check_eq(result.total_cleared(), 16, "nổ + quét phải ăn 2 hàng và 2 cột")


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
		failures.append("sau xáo trộn vẫn không có nước đi")
	check(not result.events.is_empty(), "bàn cờ chết phải sinh event SHUFFLED")
	if not result.events.is_empty():
		check_eq(result.events[0].kind, BoardEvent.Kind.SHUFFLED, "event phải là SHUFFLED")


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
				failures.append("ván %d nước %d: hết nước đi dù đã có cơ chế xáo trộn" % [game, move_index])
				return
			var move: Dictionary = moves[fuzz_rng.randi_range(0, moves.size() - 1)]
			var result := board.try_move(move.a, move.b)
			if not result.valid:
				failures.append("ván %d nước %d: nước đi do MoveGenerator tìm ra lại bị từ chối" % [game, move_index])
				return
			if board.grid.size() != 64:
				failures.append("ván %d nước %d: bàn cờ còn %d/64 ô sau refill" % [game, move_index, board.grid.size()])
				return
			if not MatchFinder.find_groups(board.grid).is_empty():
				failures.append("ván %d nước %d: còn match chưa xử lý sau khi nước đi kết thúc" % [game, move_index])
				return


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
	check(board.grid.has(Vector2i(0, 2)), "tile cột 0 phải rơi xuống đáy")
	check(board.grid.has(Vector2i(2, 2)) and board.grid.has(Vector2i(2, 1)), "cột 2 phải dồn xuống đáy")
	check(not board.grid.has(Vector2i(0, 0)) and not board.grid.has(Vector2i(2, 0)), "hàng trên phải trống")


func test_refill_fills_every_valid_cell() -> void:
	var board := BoardLogic.new()
	board.init_shape(Vector2i(4, 4))
	board.rng.seed = 5
	var result := MoveResult.new()
	board.apply_gravity(result)
	check_eq(board.grid.size(), 16, "refill phải lấp đầy mọi ô hợp lệ")
	check_eq(result.events.size(), 1, "phải có đúng 1 event GRAVITY")
