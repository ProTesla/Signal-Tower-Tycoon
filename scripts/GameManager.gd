## GameManager.gd — the root script that owns game state and game rules.
##
## In increment 1 that means: the budget, and the rules for placing towers.
## The monthly tick, revenue, coverage % and interference all land here in
## increment 2.
##
## Architecture note: the pieces talk through SIGNALS, Godot's built-in
## observer pattern. Grid reports clicks, GameManager applies the rules,
## UI listens for the results. No node reaches into another node's internals,
## which keeps each script replaceable and testable on its own:
##
##   Grid.tile_clicked ──▶ GameManager ──▶ budget_changed ──▶ UI label
##                                     └──▶ build_failed  ──▶ UI status text
extends Node3D

## Fired whenever the budget changes, so the UI can update its label.
signal budget_changed(new_budget: int)
## Fired when a build attempt is rejected, with a human-readable reason.
signal build_failed(reason: String)

## The scene instanced for every successful build.
const TOWER_SCENE := preload("res://scenes/tower.tscn")

## Starting money. Each tower costs Tower.BUILD_COST (see Tower.gd) —
## 1000 credits = 4 towers before the player runs dry.
var budget: int = 1000
## While true, left-clicking a free tile builds a tower. The UI toggle
## controls this; later, OFF will mean "click to select/inspect towers".
var build_mode: bool = true

# Typed references to our child nodes, resolved once the scene is ready.
@onready var _grid: Grid = $Grid
@onready var _towers: Node3D = $Towers
@onready var _ui: GameUI = $UI
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_setup_lighting()

	# All signal wiring lives here in one place, so this function is the
	# map of "who talks to whom" for the whole game.
	_grid.tile_clicked.connect(_on_tile_clicked)
	_ui.build_mode_toggled.connect(_on_build_mode_toggled)
	budget_changed.connect(_ui.set_credits)
	build_failed.connect(_ui.show_status)

	# Push the starting budget to the UI now that everything is connected.
	budget_changed.emit(budget)


func _setup_lighting() -> void:
	# One angled "sun" so the primitive shapes get clear directional shading
	# (a box lit straight-on just looks like a flat rectangle)...
	_light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	_light.light_energy = 1.2
	_light.shadow_enabled = true

	# ...plus soft ambient light from a WorldEnvironment so the shadowed
	# faces aren't pitch black.
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.10, 0.13, 0.18) # dark blue-grey backdrop
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.70, 0.75, 0.85)
	environment.ambient_light_energy = 0.6
	_world_environment.environment = environment


func _on_build_mode_toggled(enabled: bool) -> void:
	build_mode = enabled


## The core placement rule-check. Runs every time the player clicks a tile.
func _on_tile_clicked(tile: Vector2i) -> void:
	if not build_mode:
		return # In a later increment this click will select the tower instead.
	if not _grid.is_tile_free(tile):
		build_failed.emit("Tile occupied")
		return
	if budget < Tower.BUILD_COST:
		build_failed.emit("Not enough credits (need %d)" % Tower.BUILD_COST)
		return
	_place_tower(tile)


func _place_tower(tile: Vector2i) -> void:
	var tower: Tower = TOWER_SCENE.instantiate()
	# Add to the tree FIRST, then position — a node has no place in the world
	# until it's inside the scene tree.
	_towers.add_child(tower)
	tower.position = _grid.tile_to_world(tile)
	_grid.mark_occupied(tile, tower)

	budget -= Tower.BUILD_COST
	budget_changed.emit(budget)

	tower.play_place_animation()
