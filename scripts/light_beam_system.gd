extends Node3D
## Arena-local projectiles and cooldown. Session only chooses forward destinations.

const BEAM_SCRIPT = preload("res://scripts/light_beam.gd")
const COOLDOWN: float = 0.8
const MAX_BEAMS: int = 8
var session: Control
var cooldown_left: float = 0.0
var muzzle_left: float = 0.0
var shots_fired: int = 0
var last_destination: int = -1
var impact_left: float = 0.0
var impact_count: int = 0
var impact: MeshInstance3D
@onready var arena: Node3D = get_parent()
@onready var player: CharacterBody3D = get_node("../Player")
var bolts: Node3D
var muzzle: MeshInstance3D

func _ready() -> void:
	bolts = Node3D.new()
	bolts.name = "Bolts"
	add_child(bolts)
	muzzle = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.6, 0.25, 0.3)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.9, 1.0, 0.55)
	mesh.material = material
	muzzle.mesh = mesh
	muzzle.visible = false
	muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(muzzle)
	impact = MeshInstance3D.new()
	impact.mesh = mesh
	impact.scale = Vector3(1.6, 3.0, 2.0)
	impact.visible = false
	impact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(impact)

func _physics_process(delta: float) -> void:
	delta *= arena.simulation_rate
	impact_left = maxf(0.0, impact_left - delta)
	impact.visible = impact_left > 0.0 and arena.result == &"fighting"
	muzzle_left = maxf(0.0, muzzle_left - delta)
	muzzle.visible = muzzle_left > 0.0 and arena.result == &"fighting"
	if not player.hit_stopped:
		cooldown_left = maxf(0.0, cooldown_left - delta)
	if not is_instance_valid(session) or not player.input_enabled:
		return
	var next: bool = player.action_just_pressed(&"light_beam")
	if next:
		fire()

func fire() -> bool:
	if not is_instance_valid(session) or get_tree().paused or not player.input_enabled or not player.combat_enabled or player.dead or player.hit_stopped or player.dash_time_left > 0.0 or player.parry.window_left > 0.0 or cooldown_left > 0.0 or arena.result != &"fighting":
		return false
	var source_rank: int = session.ROLE_NAMES.find(arena.temporal_role)
	var target_rank: int = source_rank + 1
	if source_rank >= target_rank or target_rank >= session.ROLE_NAMES.size():
		return false
	for index in range(session.panels.size()):
		var target: Node3D = session.panels[index].arena
		if target.temporal_role != session.ROLE_NAMES[target_rank]:
			continue
		var destination: Node3D = self
		if target.result != &"fighting" or destination.bolts.get_child_count() >= MAX_BEAMS:
			return false
		var bolt := Node3D.new()
		bolt.set_script(BEAM_SCRIPT)
		bolt.arena = arena
		bolt.target_arena = target
		bolt.direction = player.facing_direction
		bolt.source_panel = session.active_index + 1
		bolt.position = player.position + Vector3(float(player.facing_direction) * 0.7, 0.08, 0)
		destination.bolts.add_child(bolt)
		cooldown_left = COOLDOWN
		muzzle_left = 0.10
		muzzle.position = bolt.position
		muzzle.visible = true
		shots_fired += 1
		last_destination = index
		return true
	return false

func status_text() -> String:
	if arena.temporal_role == &"Future":
		return "BEAM — no forward role"
	if cooldown_left > 0.0:
		return "BEAM %.1fs" % cooldown_left
	return "E → Present mirages" if arena.temporal_role == &"Past" else "E → Future mirages"

func show_impact(point: Vector3) -> void:
	impact.position = point
	impact_left = 0.14
	impact.visible = true
	impact_count += 1

func cancel_invalid_bolts() -> void:
	for bolt in bolts.get_children():
		if not bolt.route_valid():
			bolt.queue_free()
