extends "res://scripts/training_striker.gd"
## Reuses interruption/stagger state; horizontal aim is locked at windup start.

const PROJECTILE = preload("res://scripts/enemy_projectile.gd")
const RECOVERY: float = 1.8
const MAX_PROJECTILES: int = 8
var shots_fired: int = 0
var projectile_speed: float = 4.0
@onready var arena: Node3D = actor.get_parent().get_parent()

func _physics_process(delta: float) -> void:
	delta *= actor.simulation_rate
	strike_visual.visible = false
	warning.visible = enabled and not actor.dead and show_debug_text
	if not enabled or actor.dead or player.dead or not player.combat_enabled:
		interrupt()
		return
	if actor.hit_stopped:
		return
	if stagger_left > 0.0:
		stagger_left = maxf(0.0, stagger_left - delta)
		warning.text = "PARRIED"
		return
	if not actor.is_on_floor() or actor.hitstun_left > 0.0:
		if windup_left > 0.0:
			interrupt()
		warning.text = "AIRBORNE" if not actor.is_on_floor() else "STUNNED"
		return
	if windup_left > 0.0:
		windup_left = maxf(0.0, windup_left - delta)
		warning.text = "FIRE %s %.1f" % ["→" if strike_direction > 0 else "←", windup_left]
		strike_visual.visible = true
		strike_visual.position = Vector3(float(strike_direction) * 3.0, 0.08, 0)
		strike_visual.scale = Vector3(3.0, 0.12, 0.35)
		if windup_left <= 0.0:
			shoot()
			rest_left = RECOVERY * recovery_factor
			strike_visual.visible = false
		return
	rest_left = maxf(0.0, rest_left - delta)
	warning.text = "RELOAD" if rest_left > 0.0 else "AIM"
	var offset: Vector3 = player.global_position - actor.global_position
	if rest_left <= 0.0 and absf(offset.x) <= 14.0 and absf(offset.y) < 1.0:
		var ray := PhysicsRayQueryParameters3D.create(actor.global_position, player.global_position, 1)
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			strike_direction = 1 if offset.x >= 0.0 else -1
			windup_left = windup_duration
			Sfx.play_cue(&"enemy_windup", actor)

func shoot() -> void:
	var projectiles: Node3D = arena.get_node("EnemyProjectiles")
	if projectiles.get_child_count() >= MAX_PROJECTILES or arena.result != &"fighting":
		return
	var shot := Node3D.new()
	shot.set_script(PROJECTILE)
	shot.arena = arena
	shot.direction = strike_direction
	shot.speed = projectile_speed
	shot.position = actor.position + Vector3(float(strike_direction) * 0.7, 0.08, 0)
	projectiles.add_child(shot)
	shots_fired += 1
	Sfx.play_cue(&"enemy_shot", actor)
