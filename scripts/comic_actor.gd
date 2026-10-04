extends MeshInstance3D
## Small articulated flat-color silhouette. Visual animation never moves the body.

@export_enum("Player", "Grunt", "Gunner") var identity: int = 1
var clock: float = 0.0
var limbs: Array[Node3D] = []
var streaks: Array[Node3D] = []
var health_fill: Node3D
var actor: CharacterBody3D
var dark := StandardMaterial3D.new()
var accent := StandardMaterial3D.new()
var ink := StandardMaterial3D.new()
var light := StandardMaterial3D.new()

func _ready() -> void:
	actor = get_parent()
	mesh = null
	for material in [dark, accent, ink, light]:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = Color(0.06, 0.08, 0.12)
	accent.albedo_color = [Color(0.1, 0.8, 0.95), Color(1.0, 0.35, 0.12), Color(0.45, 0.8, 0.25)][identity]
	ink.albedo_color = Color(0.015, 0.018, 0.028)
	ink.cull_mode = BaseMaterial3D.CULL_FRONT
	light.albedo_color = Color(1.0, 0.9, 0.5)
	part(Vector3(0, 0.02, 0), Vector3(0.5, 0.45, 0.4), accent)
	part(Vector3(0, 0.39, 0), Vector3(0.4, 0.28, 0.38), dark)
	part(Vector3(0, 0.4, 0.21), Vector3(0.3, 0.08, 0.05), light, false)
	part(Vector3(0, 0.05, 0.23), Vector3(0.18, 0.16, 0.06), light, false)
	for side in [-1.0, 1.0]:
		var leg := part(Vector3(side * 0.16, -0.35, 0), Vector3(0.18, 0.3, 0.28), dark)
		limbs.append(leg)
		var arm := part(Vector3(side * 0.36, 0.01, 0), Vector3(0.17, 0.4, 0.22), accent)
		limbs.append(arm)
	if identity == 2:
		part(Vector3(0.42, 0.08, 0.14), Vector3(0.5, 0.14, 0.2), dark)
	elif identity == 0:
		part(Vector3(-0.2, 0.18, -0.25), Vector3(0.4, 0.16, 0.07), accent)
		for index in range(3):
			var streak := part(Vector3(-0.9, 0.2 - float(index) * 0.18, 0.1), Vector3(0.6 + float(index) * 0.12, 0.035, 0.035), light, false)
			streak.visible = false
			streaks.append(streak)

	if identity != 0 and actor.has_signal("defeated"):
		part(Vector3(0, 0.82, 0.05), Vector3(0.65, 0.06, 0.06), dark, false)
		health_fill = part(Vector3(0, 0.82, 0.09), Vector3(0.6, 0.04, 0.04), accent, false)
		actor.get_node("Readout").visible = false

func part(at: Vector3, dimensions: Vector3, material: Material, outlined: bool = true) -> Node3D:
	var root := Node3D.new()
	var factor: float = 1.0 if identity == 0 else 1.4
	root.position = at * factor
	add_child(root)
	var box := BoxMesh.new()
	box.size = dimensions * factor
	var visual := MeshInstance3D.new()
	visual.mesh = box
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(visual)
	if outlined:
		var border := MeshInstance3D.new()
		border.mesh = box
		border.scale = Vector3.ONE + Vector3(0.045, 0.045, 0.045) / dimensions
		border.material_override = ink
		border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(border)
	return root

func _process(delta: float) -> void:
	if is_instance_valid(health_fill):
		health_fill.scale.x = maxf(0.01, float(actor.health) / float(actor.max_health))
	if actor.hit_stopped:
		return
	clock += delta * actor.simulation_rate
	for streak in streaks:
		streak.visible = actor.dash_time_left > 0.0
		streak.position.x = -float(actor.dash_direction) * 0.9
	var moving: bool = absf(actor.velocity.x) > 0.3 and actor.is_on_floor()
	for index in range(limbs.size()):
		limbs[index].rotation.z = sin(clock * 16.0 + float(index % 2) * PI) * (0.22 if moving else 0.0)
