# Temporary smoke test — run with:
#   godot --headless --script res://smoke_test.gd
# Instances the real main scene and drives the tile_clicked signal path.
# Assertions run one frame in, once every node's _ready() has fired.
extends SceneTree

var main


func _initialize() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	# Nodes only become ready when the tree starts processing, so defer the
	# actual test until the first frame has been processed.
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)


func _run_test() -> void:
	var grid = main.get_node("Grid")
	var towers = main.get_node("Towers")
	var failures: Array[String] = []

	if not main.is_node_ready():
		failures.append("main scene never became ready")
	if main.budget != 1000:
		failures.append("start budget = %d, expected 1000" % main.budget)

	# Build on a free tile -> tower appears, budget drops.
	grid.tile_clicked.emit(Vector2i(3, 3))
	if main.budget != 750:
		failures.append("budget after 1st build = %d, expected 750" % main.budget)
	if grid.is_tile_free(Vector2i(3, 3)):
		failures.append("tile (3,3) should be occupied after build")
	if towers.get_child_count() != 1:
		failures.append("expected 1 tower, got %d" % towers.get_child_count())

	# Clicking the same tile again -> rejected, no charge.
	grid.tile_clicked.emit(Vector2i(3, 3))
	if main.budget != 750 or towers.get_child_count() != 1:
		failures.append("occupied tile was not rejected")

	# Spend the rest of the budget (3 more towers = 750).
	grid.tile_clicked.emit(Vector2i(0, 0))
	grid.tile_clicked.emit(Vector2i(1, 0))
	grid.tile_clicked.emit(Vector2i(2, 0))
	if main.budget != 0:
		failures.append("budget should be 0, got %d" % main.budget)

	# Broke -> rejected.
	grid.tile_clicked.emit(Vector2i(5, 5))
	if towers.get_child_count() != 4:
		failures.append("build with 0 credits was not rejected")

	# Build mode OFF -> clicks ignored entirely.
	main.get_node("UI").build_mode_toggled.emit(false)
	grid.tile_clicked.emit(Vector2i(6, 6))
	if towers.get_child_count() != 4:
		failures.append("build-mode OFF did not block building")

	if failures.is_empty():
		print("SMOKE TEST: ALL PASS")
		quit(0)
	else:
		for f in failures:
			printerr("SMOKE TEST FAIL: " + f)
		quit(1)
