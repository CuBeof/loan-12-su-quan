extends SceneTree
## Headless test runner:
##   godot --headless --path game -s res://tests/run_tests.gd
## Runs every test_* method in the registered suites; exit code 1 on failure.

const SUITES: Array[String] = [
	"res://tests/test_board_logic.gd",
	"res://tests/test_battle.gd",
]


func _initialize() -> void:
	var total := 0
	var failed := 0
	for suite_path in SUITES:
		var suite: BoardTestBase = load(suite_path).new()
		for method in suite.get_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			suite.call(method_name)
			if suite.failures.is_empty():
				print("PASS  ", method_name)
			else:
				failed += 1
				for failure in suite.failures:
					printerr("FAIL  %s: %s" % [method_name, failure])
	print("--- %d/%d test pass ---" % [total - failed, total])
	quit(1 if failed > 0 else 0)
