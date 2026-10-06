extends Node3D
## Ground string, launcher, two airborne lights, and a directional air finisher.
## Hurtboxes use layer 2; solid world geometry uses layer 1.

const STARTUP: Array[float] = [0.05, 0.04, 0.06]
const ACTIVE: Array[float] = [0.08, 0.08, 0.10]
const RECOVERY: Array[float] = [0.11, 0.12, 0.16]
const DAMAGE: Array[int] = [1, 1, 2]

@export var combo_cooldown: float = 0.20
var attacking: bool = false
var swing_sound_played: bool = false
var combo_cooldown_left: float = 0.0
var combo_index: int = 0
var attack_kind: StringName = &"ground_light"
var attack_elapsed: float = 0.0
var attack_direction: int = 1
var queued_kind: StringName = &""
var pending_kind: StringName = &""
var pending_time_left: float = 0.0
var air_lights_left: int = 2
var air_finisher_available: bool = true
var hit_targets: Dictionary = {}
var hit_shape: BoxShape3D = BoxShape3D.new()
var hit_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

@onready var player: CharacterBody3D = get_parent()
@onready var swing: MeshInstance3D = $Swing

func _ready() -> void:
	hit_query.shape = hit_shape
	hit_query.collision_mask = 2
	hit_query.collide_with_areas = true
	hit_query.collide_with_bodies = false
	swing.visible = false

func _physics_process(delta: float) -> void:
	delta *= player.simulation_rate
	if not player.combat_enabled:
		cancel_attack()
		return
	pending_time_left = maxf(0.0, pending_time_left - delta)
	capture_attack_input()
	if player.hit_stopped:
		return
	combo_cooldown_left = maxf(0.0, combo_cooldown_left - delta)
	if player.is_on_floor():
		air_lights_left = 2
		air_finisher_available = true
	if player.dash_time_left > 0.0 or player.parry.window_left > 0.0:
		cancel_attack()
		return
	if attacking and ((attack_kind == &"ground_light" or attack_kind == &"launcher") != player.is_on_floor()):
		cancel_attack()
	if not attacking and pending_time_left > 0.0 and combo_cooldown_left <= 0.0:
		var requested: StringName = pending_kind
		pending_kind = &""
		pending_time_left = 0.0
		if can_start(requested):
			start_attack(0, requested)
	if not attacking:
		return

	attack_elapsed += delta
	var active_start: float = startup_time()
	var active_end: float = active_start + active_time()
	var live: bool = attack_elapsed >= active_start and attack_elapsed < active_end
	swing.visible = live
	if live:
		if not swing_sound_played:
			swing_sound_played = true
			var cue: StringName = &"heavy_swing" if attack_kind in [&"launcher", &"air_finisher"] else (&"swing" if combo_index % 2 == 0 else &"swing_alt")
			Sfx.play_cue(cue, player, 1.0 + combo_index * 0.03)
		check_hits()
	# Buffered air follow-ups link as soon as the live window ends, keeping
	# the short chain reachable while both actors are falling.
	var recovery: float = 0.0 if attack_kind == &"air_light" and queued_kind != &"" else recovery_time()
	if attack_elapsed >= active_end + recovery:
		var next_kind: StringName = queued_kind
		var next_index: int = combo_index + 1 if next_kind == attack_kind else 0
		cancel_attack()
		if next_kind != &"" and combo_cooldown_left <= 0.0 and can_start(next_kind):
			start_attack(next_index, next_kind)

func capture_attack_input() -> void:
	if not player.input_enabled:
		return
	var light: bool = player.action_just_pressed(&"light_attack")
	var heavy: bool = player.action_just_pressed(&"heavy_attack")
	if not light and not heavy:
		return
	if player.dash_time_left > 0.0 or player.parry.window_left > 0.0:
		return
	var kind: StringName = &""
	if heavy:
		kind = &"launcher" if player.is_on_floor() else &"air_finisher"
	else:
		kind = &"ground_light" if player.is_on_floor() else &"air_light"
	if attacking:
		if kind == &"ground_light" and attack_kind == kind and combo_index < 2:
			queued_kind = kind
		elif kind == &"air_light" and attack_kind == kind and air_lights_left > 0:
			queued_kind = kind
		elif heavy and can_start(kind) and attack_kind != &"air_finisher":
			queued_kind = kind
	elif combo_cooldown_left <= 0.0 and can_start(kind):
		pending_kind = kind
		pending_time_left = 0.10

func can_start(kind: StringName) -> bool:
	if kind == &"ground_light" or kind == &"launcher":
		return player.is_on_floor()
	if kind == &"air_light":
		return not player.is_on_floor() and air_lights_left > 0
	if kind == &"air_finisher":
		return not player.is_on_floor() and air_finisher_available
	return false

func startup_time() -> float:
	return 0.09 if attack_kind == &"launcher" else STARTUP[mini(combo_index, 2)]

func active_time() -> float:
	return 0.10 if attack_kind == &"launcher" or attack_kind == &"air_finisher" else ACTIVE[mini(combo_index, 2)]

func recovery_time() -> float:
	return 0.16 if attack_kind == &"launcher" or attack_kind == &"air_finisher" else RECOVERY[mini(combo_index, 2)]

func start_attack(index: int, kind: StringName = &"ground_light") -> void:
	attacking = true
	combo_index = index
	attack_kind = kind
	attack_elapsed = 0.0
	swing_sound_played = false
	attack_direction = player.facing_direction
	queued_kind = &""
	pending_kind = &""
	pending_time_left = 0.0
	hit_targets.clear()
	swing.visible = false
	if kind == &"air_light":
		air_lights_left -= 1
	elif kind == &"air_finisher":
		air_finisher_available = false
	var reach: float = 1.5 + 0.15 * float(index)
	hit_shape.size = Vector3(reach, 1.2 if kind != &"ground_light" else 0.95, 0.8)
	swing.position = Vector3(float(attack_direction) * (0.32 + reach * 0.5), 0.08, 0.0)
	swing.scale = hit_shape.size

func cancel_attack() -> void:
	# Movement/parry cancels preserve finisher cooldown and airborne budgets.
	if attacking and attack_elapsed >= startup_time():
		if (attack_kind == &"ground_light" and combo_index == 2) or attack_kind == &"launcher" or attack_kind == &"air_finisher":
			combo_cooldown_left = maxf(combo_cooldown_left, combo_cooldown)
	attacking = false
	combo_index = 0
	attack_elapsed = 0.0
	queued_kind = &""
	pending_kind = &""
	pending_time_left = 0.0
	hit_targets.clear()
	if is_instance_valid(swing):
		swing.visible = false

func check_hits() -> void:
	hit_query.transform = Transform3D(Basis.IDENTITY, player.global_position + swing.position)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var made_contact: bool = false
	var stop_duration: float = 0.035 if attack_kind == &"ground_light" or attack_kind == &"air_light" else 0.06
	for overlap in space.intersect_shape(hit_query, 32):
		var hurtbox: Area3D = overlap["collider"]
		var receiver: Node3D = hurtbox.get_parent()
		var target_id: int = receiver.get_instance_id()
		if hit_targets.has(target_id) or not receiver.has_method("receive_melee_hit"):
			continue
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			player.global_position + Vector3(0.0, 0.08, 0.0), receiver.global_position, 1, [player.get_rid()]
		)
		if not space.intersect_ray(ray).is_empty():
			continue
		hit_targets[target_id] = true
		var damage: int = 2 if attack_kind == &"launcher" or attack_kind == &"air_finisher" else DAMAGE[mini(combo_index, 2)]
		if player.health_owner != null and player.health_owner.has_method("scaled_damage"):
			damage = player.health_owner.scaled_damage(damage)
		receiver.receive_melee_hit(damage, attack_direction, attack_kind)
		receiver.apply_hit_stop(stop_duration)
		made_contact = true
	if made_contact:
		player.apply_hit_stop(stop_duration)
		if attack_kind == &"air_light":
			player.velocity.y = maxf(player.velocity.y, 6.0)
