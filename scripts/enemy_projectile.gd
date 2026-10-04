extends Node3D
## One-hit local projectile; a facing parry reverses it into enemy-only damage.

const SPEED: float = 4.0
const LIFETIME: float = 4.5
var arena: Node3D
var direction: int = 1
var reflected: bool = false
var age: float = 0.0
var shape := BoxShape3D.new()
var sweep := BoxShape3D.new()
var wall_query := PhysicsShapeQueryParameters3D.new()
var hit_query := PhysicsShapeQueryParameters3D.new()
var material := StandardMaterial3D.new()

func _ready() -> void:
	shape.size = Vector3(0.25, 0.3, 0.6)
	wall_query.shape = shape
	wall_query.collision_mask = 1
	hit_query.shape = sweep
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.55, 0.25, 0.35)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.7, 0.15)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)

func on_parried() -> void:
	reflected = true
	direction = arena.player.facing_direction
	global_position = arena.player.global_position + Vector3(float(direction) * 0.85, 0.08, 0)
	material.albedo_color = Color(0.9, 1.0, 0.55)
	age = 0.0

func _physics_process(delta: float) -> void:
	if arena.result != &"fighting":
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
	if not space.intersect_shape(wall_query, 1).is_empty():
		queue_free()
		return
	var fractions: PackedFloat32Array = space.cast_motion(wall_query)
	var travel: Vector3 = motion * fractions[0]
	global_position += travel
	sweep.size = Vector3(absf(travel.x) + shape.size.x, shape.size.y, shape.size.z)
	hit_query.transform = Transform3D(Basis.IDENTITY, start + travel * 0.5)
	hit_query.collision_mask = 2 if reflected else 4
	hit_query.collide_with_areas = reflected
	hit_query.collide_with_bodies = not reflected
	var overlaps: Array[Dictionary] = space.intersect_shape(hit_query, 32)
	overlaps.sort_custom(func(a, b): return a.collider.global_position.distance_squared_to(start) < b.collider.global_position.distance_squared_to(start))
	for overlap in overlaps:
		var target: Node3D = overlap.collider.get_parent() if reflected else overlap.collider
		if reflected and (not target.has_method("receive_melee_hit") or target.dead):
			continue
		if not reflected and target != arena.player:
			continue
		var ray := PhysicsRayQueryParameters3D.create(start, target.global_position, 1)
		if not space.intersect_ray(ray).is_empty():
			continue
		if reflected:
			target.receive_melee_hit(2, direction, &"reflected_shot")
			target.apply_hit_stop(0.06)
		elif arena.player.parry.window_left > 0.0:
			# Use the approach side for facing even if a large sweep passes the body.
			global_position = start
			if arena.player.parry.try_parry(self):
				return
			arena.player.receive_damage(1)
		else:
			arena.player.receive_damage(1)
		queue_free()
		return
	if fractions[0] < 1.0:
		queue_free()
