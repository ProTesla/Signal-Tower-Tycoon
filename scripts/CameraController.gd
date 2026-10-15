## CameraController.gd — sets up the isometric view and basic camera controls.
##
## Attached to the Camera3D node in main.tscn. Everything is configured in
## code (rather than in the editor inspector) so you can read exactly what
## makes the camera "isometric".
extends Camera3D

const PAN_SPEED := 14.0 # world units per second at the default zoom
const ZOOM_STEP := 2.0  # how much one mouse-wheel notch changes `size`
const MIN_SIZE := 8.0   # fully zoomed in
const MAX_SIZE := 40.0  # fully zoomed out
const DEFAULT_SIZE := 26.0


func _ready() -> void:
	# Orthogonal projection = no perspective foreshortening. Distant objects
	# stay the same size as near ones — the classic tycoon/isometric look.
	# For an orthogonal camera, `size` is how many world units fit vertically
	# on screen, so it doubles as our zoom level.
	projection = PROJECTION_ORTHOGONAL
	size = DEFAULT_SIZE

	# The classic isometric angle: spin 45° around the vertical axis, then
	# tilt ~32° downward. (True dimetric would be 30°; anything in the
	# 30-35° range reads as "isometric".)
	rotation_degrees = Vector3(-32.0, 45.0, 0.0)

	# Pull the camera back along its own viewing axis so it hovers above and
	# beside the grid, looking at the world origin (the grid is centred there).
	# basis.z points BACKWARD from a camera, so origin + basis.z * 30 puts us
	# 30 units behind the origin along our line of sight. With an orthogonal
	# camera the exact distance doesn't change the image — it only needs to be
	# far enough back that nothing pokes behind the near clip plane.
	position = global_transform.basis.z * 30.0


func _process(delta: float) -> void:
	# WASD / arrow-key panning. (We check raw keys here to keep increment 1
	# simple; a configurable InputMap can replace this later.)
	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.y -= 1.0
	if input_dir == Vector2.ZERO:
		return

	# Pan parallel to the ground: take the camera's own right/forward
	# directions but flatten them onto the XZ plane, so "up" on the keyboard
	# moves the view across the map instead of tilting into the sky.
	var right := global_transform.basis.x
	right.y = 0.0
	var forward := -global_transform.basis.z
	forward.y = 0.0
	var move := right.normalized() * input_dir.x + forward.normalized() * input_dir.y

	# Scale speed with zoom so panning feels equally fast at any zoom level.
	position += move.normalized() * PAN_SPEED * (size / DEFAULT_SIZE) * delta


func _unhandled_input(event: InputEvent) -> void:
	# Mouse-wheel zoom. Smaller `size` = fewer world units on screen = closer.
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = clampf(size - ZOOM_STEP, MIN_SIZE, MAX_SIZE)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = clampf(size + ZOOM_STEP, MIN_SIZE, MAX_SIZE)
