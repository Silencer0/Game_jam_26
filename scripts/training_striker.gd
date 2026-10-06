extends Node3D
## Fixed parry drill: approach -> windup -> one strike -> rest. No enemy AI.

@export var player_path: NodePath = NodePath("../../Player")
@export var enabled: bool = false
var show_debug_text: bool = true
@export var windup_duration: float = 0.75
var windup_left: float = 0.0
var active_left: float = 0.0
var rest_left: float = 0.6
var stagger_left: float = 0.0
var strike_direction: int = 1
var strike_spent: bool = false
var recovery_factor: float = 1.0
var strike_shape: BoxShape3D = BoxShape3D.new()
var strike_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

@onready var actor: CharacterBody3D = get_parent()
@onready var player: CharacterBody3D = get_node(player_path)
@onready var warning: Label3D = $Warning
@onready var strike_visual: MeshInstance3D = $StrikeVisual

func _ready() -> void:
	strike_shape.size = Vector3(1.6, 1.1, 0.8)
	strike_query.shape = strike_shape
	strike_query.collision_mask = 4
	strike_query.collide_with_bodies = true
	strike_query.collide_with_areas = false
	strike_visual.visible = false

func interrupt() -> void:
	windup_left = 0.0
	active_left = 0.0
	rest_left = 1.2 * recovery_factor
	strike_spent = false
	strike_visual.visible = false

func _physics_process(delta: float) -> void:
	delta *= actor.simulation_rate
	if not enabled:
		warning.visible = false
		strike_visual.visible = false
		return
	warning.visible = show_debug_text
	if actor.hit_stopped:
		return
	if stagger_left > 0.0:
		stagger_left = maxf(0.0, stagger_left - delta)
		warning.text = "PARRIED"
		return
	if not actor.is_on_floor():
		# Landing detection at spawn must not repeatedly restart attack recovery.
		if windup_left > 0.0 or active_left > 0.0:
			interrupt()
		warning.text = "AIRBORNE"
		return
	if windup_left > 0.0:
		windup_left = maxf(0.0, windup_left - delta)
		warning.text = "WINDUP %.1f" % windup_left
		if windup_left <= 0.0:
			Sfx.play_cue(&"enemy_swing", actor)
			active_left = 0.10
			strike_spent = false
	elif active_left > 0.0:
		active_left = maxf(0.0, active_left - delta)
		strike_visual.position = Vector3(float(strike_direction) * 1.25, 0.0, 0.0)
		strike_visual.visible = active_left > 0.0
		warning.text = "STRIKE"
		if not strike_spent:
			check_strike()
		if active_left <= 0.0:
			strike_visual.visible = false
			rest_left = 1.2 * recovery_factor
	else:
		rest_left = maxf(0.0, rest_left - delta)
		warning.text = "PARRY DRILL: F / Right click"
		var offset: Vector3 = player.global_position - actor.global_position
		if rest_left <= 0.0 and absf(offset.x) < 2.2 and absf(offset.y) < 1.0:
			strike_direction = 1 if offset.x >= 0.0 else -1
			windup_left = windup_duration
			Sfx.play_cue(&"enemy_windup", actor)

func check_strike() -> void:
	strike_query.transform = Transform3D(Basis.IDENTITY, actor.global_position + Vector3(float(strike_direction) * 1.25, 0.0, 0.0))
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for overlap in space.intersect_shape(strike_query, 4):
		if overlap["collider"] != player:
			continue
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(actor.global_position, player.global_position, 1)
		if not space.intersect_ray(ray).is_empty():
			continue
		strike_spent = true
		if not player.parry.try_parry(actor):
			on_unparried_strike()
		return

func on_unparried_strike() -> void:
	player.training_misses += 1
