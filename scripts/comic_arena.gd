extends Node3D
## Noncolliding reactor hangar set dressing. Low-poly props and flat opaque shapes.

const RAIL = preload("res://assets/kenney/station/balcony-rail-center.fbx")
const CONSOLE = preload("res://assets/kenney/station/computer-system.fbx")
const CRATE = preload("res://assets/kenney/station/container-flat.fbx")
const FONT = preload("res://assets/kenney/fonts/KenneyFuture.ttf")
var materials: Dictionary = {}

func _ready() -> void:
	var navy := Color(0.055, 0.075, 0.13)
	var steel := Color(0.15, 0.21, 0.3)
	var yellow := Color(0.95, 0.7, 0.22)
	for x in range(2, 32, 4):
		box(Vector3(x, 3.5, -2.5), Vector3(0.45, 7, 0.5), navy)
		box(Vector3(x, 6.4, -2.2), Vector3(3.3, 0.16, 0.12), yellow)
		box(Vector3(x, 2.6, -2.6), Vector3(2.8, 4.8, 0.16), steel)
		box(Vector3(x, 2.6, -2.45), Vector3(2.4, 0.07, 0.08), navy)
		box(Vector3(x, 0.06, -1.7), Vector3(2.4, 0.04, 0.5), yellow)
	for x in range(1, 32, 2):
		box(Vector3(x, 0.025, 0), Vector3(0.025, 0.025, 5.5), navy)
	box(Vector3(16, -0.15, 2.85), Vector3(32, 0.15, 0.15), yellow)
	box(Vector3(16, 6.9, -2.6), Vector3(32, 0.45, 0.5), navy)
	for x in [3.0, 29.0]:
		prop(CONSOLE, Vector3(x, 0, -1.5), 1.0, steel)
		prop(CRATE, Vector3(x + (1.3 if x < 16 else -1.3), 0, -1.8), 1.0, yellow)
	for x in [8.0, 16.0, 24.0]:
		prop(RAIL, Vector3(x, 0, -2.0), 1.5, steel)
	var sign := Label3D.new()
	sign.text = "SHIFT // REACTOR 01"
	sign.font = FONT
	sign.font_size = 80
	sign.pixel_size = 0.012
	sign.position = Vector3(16, 5.0, -2.0)
	sign.modulate = Color(1, 0.84, 0.45)
	sign.outline_size = 10
	add_child(sign)

func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var value := StandardMaterial3D.new()
		value.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		value.albedo_color = color
		materials[color] = value
	return materials[color]

func box(at: Vector3, dimensions: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.material_override = material(color)
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)

func prop(scene: PackedScene, at: Vector3, factor: float, color: Color) -> void:
	var value: Node3D = scene.instantiate()
	value.position = at
	value.scale = Vector3.ONE * factor
	add_child(value)
	for visual in value.find_children("*", "MeshInstance3D", true, false):
		visual.material_override = material(color)
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
