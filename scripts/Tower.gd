## Tower.gd — a single signal tower, built entirely from primitive meshes.
##
## The root node is an empty Node3D sitting at ground level in the middle of
## its tile; the visible parts (pad, mast, antenna) are MeshInstance3D
## children created in code. Because the root's origin is at the BASE of the
## tower, scaling the root vertically makes it grow up out of the ground —
## which is exactly what the placement animation does.
class_name Tower
extends Node3D

# --- Stats -------------------------------------------------------------
# Only BUILD_COST is used in increment 1. The rest are declared now so the
# whole "tower spec" lives in one place, ready for the revenue/coverage
# systems in increment 2.
const BUILD_COST := 250
const MONTHLY_UPKEEP := 20   # credits per game tick (month)
const COVERAGE_RADIUS := 5.0 # world units; ~2.5 tiles in every direction
const CAPACITY := 40         # max users this tower can serve at once
const FREQUENCY_BAND := 0    # index into a future frequency-band table

## The glowing antenna colour. Later this will be driven by FREQUENCY_BAND
## so you can tell bands apart at a glance.
const ANTENNA_COLOR := Color(0.25, 0.85, 0.95)


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	# Concrete pad the tower stands on: a short, slightly tapered cylinder.
	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 0.65
	pad_mesh.bottom_radius = 0.75
	pad_mesh.height = 0.2
	# Meshes are positioned by their CENTER, so a 0.2-tall pad sits at y=0.1
	# to rest exactly on the ground.
	_add_part(pad_mesh, Vector3(0.0, 0.1, 0.0), Color(0.55, 0.56, 0.60))

	# The mast: one tall thin box, painted in classic red-and-white-ish
	# telecom red. (Pad top is at y=0.2; the 2.4-tall mast's centre goes at
	# 0.2 + 2.4/2 = 1.4.)
	var mast_mesh := BoxMesh.new()
	mast_mesh.size = Vector3(0.22, 2.4, 0.22)
	_add_part(mast_mesh, Vector3(0.0, 1.4, 0.0), Color(0.82, 0.30, 0.26))

	# Antenna drum at the top. It GLOWS (emission) so towers read clearly
	# even when zoomed out or in shadow.
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.28
	antenna_mesh.bottom_radius = 0.28
	antenna_mesh.height = 0.45
	var antenna := _add_part(antenna_mesh, Vector3(0.0, 2.825, 0.0), ANTENNA_COLOR)
	var antenna_material: StandardMaterial3D = antenna.material_override
	antenna_material.emission_enabled = true
	antenna_material.emission = ANTENNA_COLOR
	antenna_material.emission_energy_multiplier = 1.6


## Helper: wrap a mesh in a MeshInstance3D with a simple coloured material
## and attach it to the tower. Returns the instance in case the caller wants
## to tweak the material further (like the glowing antenna does).
func _add_part(mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	part.material_override = material
	add_child(part)
	return part


## The "rise up out of the ground" placement animation.
## This is plain transform tweening (allowed by the project scope) — no
## skeletons or imported animations, just animating the `scale` property.
func play_place_animation() -> void:
	# Start squashed flat (y ≈ 0), then spring to full height.
	# TRANS_BACK + EASE_OUT overshoots slightly past full size before
	# settling, which gives the build a satisfying "pop".
	scale = Vector3(1.0, 0.01, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
