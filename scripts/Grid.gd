## Grid.gd — the logical tile grid plus its visual ground plane.
##
## Owns everything tile-related:
##   * builds the ground mesh (one flat plane, grid lines drawn by a shader)
##   * converts between world positions and tile coordinates
##   * tracks which tiles are occupied by towers
##   * turns mouse input into a hover highlight and a `tile_clicked` signal
##
## It deliberately knows NOTHING about money or game rules — it just reports
## "the player clicked tile (x, y)" and lets GameManager.gd decide what to do.
class_name Grid
extends Node3D

## Fired when the player left-clicks a tile that exists on the grid.
signal tile_clicked(tile: Vector2i)

## Number of tiles along each side of the (square) map.
const GRID_SIZE := 12
## Size of one tile in world units (metres). A tower occupies one tile.
const TILE_SIZE := 2.0
## Sentinel value meaning "the mouse is not over any valid tile".
const OFF_GRID := Vector2i(-1, -1)

const HIGHLIGHT_FREE := Color(0.3, 1.0, 0.5, 0.4)     # green = can build here
const HIGHLIGHT_BLOCKED := Color(1.0, 0.35, 0.3, 0.4) # red = occupied

const GRID_SHADER := preload("res://shaders/grid.gdshader")

## Which tiles hold a tower: Vector2i -> Tower node.
## A Dictionary keyed by tile coords is the simplest possible "map data".
var _occupied: Dictionary = {}

var _highlight: MeshInstance3D
var _highlight_material: StandardMaterial3D

## The active camera, needed to turn a 2D mouse position into a 3D ray.
## @onready = "assign this when the node enters the scene, not at load time".
@onready var _camera: Camera3D = get_viewport().get_camera_3d()


func _ready() -> void:
	_build_ground()
	_build_highlight()


## One flat plane for the whole map; the grid lines come from the shader,
## which is far cheaper and simpler than creating hundreds of line meshes.
func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var side := GRID_SIZE * TILE_SIZE
	plane.size = Vector2(side, side)
	ground.mesh = plane

	var material := ShaderMaterial.new()
	material.shader = GRID_SHADER
	# Keep the shader's line spacing in sync with our logical tile size.
	material.set_shader_parameter("tile_size", TILE_SIZE)
	ground.material_override = material

	add_child(ground)


## A translucent quad that floats a hair above the ground under the mouse.
## Green when the tile is buildable, red when it's occupied.
func _build_highlight() -> void:
	_highlight = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(TILE_SIZE, TILE_SIZE) * 0.94 # slight inset looks nicer
	_highlight.mesh = quad
	# 0.02 m above the ground so it doesn't "z-fight" (flicker) with it.
	_highlight.position.y = 0.02
	_highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_highlight_material = StandardMaterial3D.new()
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight.material_override = _highlight_material

	_highlight.visible = false
	add_child(_highlight)


## _unhandled_input only receives events the UI didn't consume first,
## so clicking a button never accidentally builds a tower under it.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_highlight(event.position)
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var tile := _tile_under_mouse(event.position)
			if tile != OFF_GRID:
				tile_clicked.emit(tile)


## Converts a screen-space mouse position into a tile coordinate.
## How: project a ray from the camera through the mouse cursor, intersect it
## with the infinite mathematical plane y = 0 (our flat ground). No physics
## bodies needed — pure geometry. If the map ever gets hills, this is the
## function to replace with a real physics raycast.
func _tile_under_mouse(screen_pos: Vector2) -> Vector2i:
	if _camera == null:
		return OFF_GRID
	var ray_origin := _camera.project_ray_origin(screen_pos)
	var ray_direction := _camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
	if hit == null:
		return OFF_GRID # ray parallel to the ground (can't happen with our camera, but be safe)
	var tile := world_to_tile(hit)
	return tile if is_in_bounds(tile) else OFF_GRID


func _update_highlight(screen_pos: Vector2) -> void:
	var tile := _tile_under_mouse(screen_pos)
	if tile == OFF_GRID:
		_highlight.visible = false
		return
	_highlight.visible = true
	var center := tile_to_world(tile)
	_highlight.position = Vector3(center.x, 0.02, center.z)
	_highlight_material.albedo_color = HIGHLIGHT_FREE if is_tile_free(tile) else HIGHLIGHT_BLOCKED


# --- Public tile API (used by GameManager.gd) -------------------------------

## The grid is centred on the world origin, so tile (0,0) starts at
## (-half, -half) and tile (GRID_SIZE-1, GRID_SIZE-1) ends at (+half, +half).
func world_to_tile(world_pos: Vector3) -> Vector2i:
	var half := GRID_SIZE * TILE_SIZE * 0.5
	return Vector2i(
		floori((world_pos.x + half) / TILE_SIZE),
		floori((world_pos.z + half) / TILE_SIZE)
	)


## Returns the world-space CENTER of a tile (y = 0, ground level).
func tile_to_world(tile: Vector2i) -> Vector3:
	var half := GRID_SIZE * TILE_SIZE * 0.5
	return Vector3(
		tile.x * TILE_SIZE - half + TILE_SIZE * 0.5,
		0.0,
		tile.y * TILE_SIZE - half + TILE_SIZE * 0.5
	)


func is_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < GRID_SIZE and tile.y >= 0 and tile.y < GRID_SIZE


func is_tile_free(tile: Vector2i) -> bool:
	return is_in_bounds(tile) and not _occupied.has(tile)


## Record that a tower now stands on this tile. Keeping a reference to the
## tower node means later increments can look up "which tower is here?"
## for selection, upgrades and interference checks.
func mark_occupied(tile: Vector2i, tower: Node) -> void:
	_occupied[tile] = tower
