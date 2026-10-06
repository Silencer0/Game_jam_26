extends "res://scripts/practice_target.gd"
## First enemy: short approach/telegraph/strike/recovery loop on the X/Y plane.

signal defeated
signal damage_received(amount: int, kind: StringName)

@export var max_health: int = 6
@export var approach_speed: float = 3.0345
var health: int = 6
var temporal_id: int = -1
var wave_number: int = 0
var death_cause: StringName = &"combat"
var dead: bool = false
var hitstun_left: float = 0.0
var death_visible_left: float = 0.72
var footstep_distance: float = 0.0

func configure_difficulty(profile: Dictionary) -> void:
	# Applied before entering the tree; _ready initializes current HP from this cap.
	wave_number = profile.wave
	max_health = profile.max_health
	approach_speed *= profile.movement
	var attack: Node3D = get_node("Trainer")
	attack.windup_duration *= profile.windup
	attack.recovery_factor = profile.recovery
	if attack.get("projectile_speed") != null:
		attack.projectile_speed *= profile.projectile

func _ready() -> void:
	super._ready()
	health = max_health
	trainer.enabled = true
	trainer.rest_left = 0.0 # Start approaching without an initial recovery wait.
	readout.text = "GRUNT %d / %d" % [health, max_health]

func receive_melee_hit(damage: int, direction: int, kind: StringName = &"ground_light") -> void:
	if dead:
		return
	super.receive_melee_hit(damage, direction, kind)
	health = maxi(0, health - damage)
	damage_received.emit(damage, kind)
	hitstun_left = 0.22
	trainer.rest_left = 0.25
	readout.text = "GRUNT %d / %d" % [health, max_health]
	if health == 0:
		die(&"combat")

func die(cause: StringName = &"combat") -> void:
	if dead:
		return
	health = 0
	dead = true
	death_cause = cause
	if cause == &"combat":
		Sfx.play_cue(&"enemy_death", self)
	trainer.enabled = false
	trainer.interrupt()
	$Hurtbox.set_deferred("collision_layer", 0)
	defeated.emit()
	death_visible_left = 0.72

func _physics_process(delta: float) -> void:
	if dead:
		super._physics_process(delta)
		death_visible_left -= delta * simulation_rate
		if death_visible_left <= 0.0 and is_on_floor() and not slamming:
			queue_free()
		return
	if hit_stop_left <= 0.0:
		hitstun_left = maxf(0.0, hitstun_left - delta * simulation_rate)
		if is_on_floor() and not slamming and hitstun_left <= 0.0:
			velocity.x = 0.0
						# Commit to the telegraphed direction; never track during a strike.
			# Recovery delays the next strike, not pursuit. At inactive speed a
			# 1.2-second recovery would otherwise freeze approach for 11–13 seconds.
			var ready_to_move: bool = trainer.enabled and trainer.stagger_left <= 0.0 and trainer.windup_left <= 0.0 and trainer.active_left <= 0.0
			if ready_to_move:
				velocity.x = approach_velocity()
	var before_move := position
	super._physics_process(delta)
	if is_on_floor() and hitstun_left <= 0.0 and not hit_stopped and trainer.enabled:
		footstep_distance += absf(position.x - before_move.x)
		if footstep_distance >= 1.4:
			footstep_distance = fmod(footstep_distance, 1.4)
			Sfx.play_cue(&"enemy_step", self)
	else:
		footstep_distance = 0.0

func approach_velocity() -> float:
	var opponent: CharacterBody3D = trainer.player
	var offset: Vector3 = opponent.global_position - global_position
	if opponent.combat_enabled and not opponent.dead and absf(offset.x) > 1.65:
		return signf(offset.x) * approach_speed
	return 0.0
