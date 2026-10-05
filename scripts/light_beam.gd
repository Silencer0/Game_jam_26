extends Node3D
## Visible source-panel bolt hits exact mirrored positions in one later world.

const SPEED: float = 24.0
const DAMAGE: int = 2
const LIFETIME: float = 1.5
var arena: Node3D
var target_arena: Node3D
var direction: int = 1
var source_panel: int = 1
var age: float = 0.0
var visual: MeshInstance3D
var beam_mesh: QuadMesh
var beam_material: ShaderMaterial
var hit_targets: Dictionary = {}
var shape := BoxShape3D.new()
var wall_query := PhysicsShapeQueryParameters3D.new()
var hit_query := PhysicsShapeQueryParameters3D.new()
var sweep_shape := BoxShape3D.new()

func _ready() -> void:
	shape.size = Vector3(0.3, 0.35, 0.7)
	wall_query.shape = shape
	wall_query.collision_mask = 1
	hit_query.shape = sweep_shape
	hit_query.collision_mask = 2
	hit_query.collide_with_bodies = false
	hit_query.collide_with_areas = true
	visual = MeshInstance3D.new()
	beam_mesh = QuadMesh.new()
	beam_mesh.size = Vector2(0.3, 0.48)
	visual.mesh = beam_mesh
	beam_material = ShaderMaterial.new()
	beam_material.shader = preload("res://shaders/light_beam.gdshader")
	visual.material_override = beam_material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if direction < 0:
		visual.rotation.z = PI
	add_child(visual)

func _physics_process(delta: float) -> void:
	if arena.result != &"fighting" or target_arena.result != &"fighting" or not route_valid():
		queue_free()
		return
	delta *= arena.simulation_rate
	age += delta

	if age >= LIFETIME:
		queue_free()
		return
	var start: Vector3 = global_position
	var motion := Vector3(float(direction) * SPEED * delta, 0, 0)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	wall_query.transform = Transform3D(Basis.IDENTITY, start)
	wall_query.motion = motion
	# A bolt starting inside solid geometry cannot damage through it.
	if not space.intersect_shape(wall_query, 1).is_empty():
		queue_free()
		return
	var fractions: PackedFloat32Array = space.cast_motion(wall_query)
	var target_space: PhysicsDirectSpaceState3D = target_arena.get_world_3d().direct_space_state
	var target_start: Vector3 = target_arena.to_global(arena.to_local(start))
	wall_query.transform.origin = target_start
	if not target_space.intersect_shape(wall_query, 1).is_empty():
		queue_free()
		return
	var target_fractions: PackedFloat32Array = target_space.cast_motion(wall_query)
	var fraction: float = minf(fractions[0], target_fractions[0])
	var travel: Vector3 = motion * fraction
	global_position += travel
	# A white-hot ray grows behind the travelling collision tip, not ahead of it.
	var length: float = clampf(age * SPEED, 0.3, 4.5)
	beam_mesh.size.x = length
	visual.position.x = -float(direction) * length * 0.5
	beam_material.set_shader_parameter("local_time", age)
	sweep_shape.size = Vector3(absf(travel.x) + shape.size.x, shape.size.y, shape.size.z)
	hit_query.transform = Transform3D(Basis.IDENTITY, target_start + travel * 0.5)
	for overlap in target_space.intersect_shape(hit_query, 32):
		var receiver: Node3D = overlap.collider.get_parent()
		var id: int = receiver.get_instance_id()
		if hit_targets.has(id) or not receiver.has_method("receive_melee_hit") or receiver.dead:
			continue
		# The expanded sweep must never reach a target on the far side of a wall.
		var ray := PhysicsRayQueryParameters3D.create(target_start, receiver.global_position, 1)
		if not target_space.intersect_ray(ray).is_empty():
			continue
		hit_targets[id] = true
		receiver.receive_melee_hit(DAMAGE, direction, &"light_beam")
		receiver.apply_hit_stop(0.035)
		get_parent().get_parent().show_impact(receiver.position)
	if fraction < 1.0:
		queue_free()

func route_valid() -> bool:
	var roles: Array[StringName] = [&"Past", &"Present", &"Future"]
	return is_instance_valid(target_arena) and roles.find(target_arena.temporal_role) == roles.find(arena.temporal_role) + 1
