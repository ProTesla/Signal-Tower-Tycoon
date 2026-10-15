## UI.gd — all the 2D interface: credits label, build-mode toggle, status text.
##
## Lives on a CanvasLayer, which always draws on top of the 3D world in
## screen space — so the labels stay put no matter where the camera moves.
## The controls are built in code (like the rest of the project) so you can
## see exactly what each one is; a hand-designed .tscn UI can replace this
## once the layout grows.
class_name GameUI
extends CanvasLayer

## Fired when the player toggles the "Build mode" button.
signal build_mode_toggled(enabled: bool)

var _credits_label: Label
var _build_button: Button
var _status_label: Label
var _status_tween: Tween


func _ready() -> void:
	# A vertical stack pinned near the top-left corner of the screen.
	var stack := VBoxContainer.new()
	stack.position = Vector2(16, 16)
	stack.add_theme_constant_override("separation", 8)
	add_child(stack)

	_credits_label = Label.new()
	_credits_label.add_theme_font_size_override("font_size", 24)
	_credits_label.text = "Credits: —"
	stack.add_child(_credits_label)

	# toggle_mode makes this a stay-pressed on/off button instead of a
	# momentary push button.
	_build_button = Button.new()
	_build_button.toggle_mode = true
	_build_button.button_pressed = true # build mode starts ON
	_build_button.text = "Build mode: ON  (tower costs %d cr)" % Tower.BUILD_COST
	_build_button.toggled.connect(_on_build_button_toggled)
	stack.add_child(_build_button)

	# Feedback line for rejected builds ("Tile occupied", etc.).
	# Starts invisible; show_status() fades it in and out.
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_status_label.modulate.a = 0.0
	stack.add_child(_status_label)


## Connected to GameManager.budget_changed.
func set_credits(amount: int) -> void:
	_credits_label.text = "Credits: %d" % amount


## Connected to GameManager.build_failed. Shows the message, holds it for a
## moment, then fades it out.
func show_status(text: String) -> void:
	# If a previous message is still fading, cancel its tween so the timings
	# don't fight each other.
	if _status_tween:
		_status_tween.kill()
	_status_label.text = text
	_status_label.modulate.a = 1.0
	_status_tween = create_tween()
	_status_tween.tween_interval(1.2) # hold fully visible...
	_status_tween.tween_property(_status_label, "modulate:a", 0.0, 0.6) # ...then fade


func _on_build_button_toggled(pressed: bool) -> void:
	if pressed:
		_build_button.text = "Build mode: ON  (tower costs %d cr)" % Tower.BUILD_COST
	else:
		_build_button.text = "Build mode: OFF"
	build_mode_toggled.emit(pressed)
