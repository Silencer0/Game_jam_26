extends "res://scripts/practice_target.gd"
## First enemy: short approach/telegraph/strike/recovery loop on the X/Y plane.

signal defeated

@export var max_health: int = 6
@export var approach_speed: float = 4.2
var health: int = 6
var dead: bool = false
var hitstun_left: float = 0.0

func _ready() -> void:
	super._ready()
	health = max_health
	trainer.enabled = true
	trainer.rest_left = 0.0 # Start approaching without an initial recovery wait.
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.48, 0.16)
	material.roughness = 1.0
	visual.material_override = material
	readout.text = "GRUNT %d / %d" % [health, max_health]

func receive_melee_hit(damage: int, direction: int, kind: StringName = &"ground_light") -> void:
	if dead:
		return
	super.receive_melee_hit(damage, direction, kind)
	health = maxi(0, health - damage)
	hitstun_left = 0.22
	trainer.rest_left = 0.25
	readout.text = "GRUNT %d / %d" % [health, max_health]
	if health == 0:
		dead = true
		trainer.enabled = false
		trainer.interrupt()
		$Hurtbox.set_deferred("collision_layer", 0)
		defeated.emit()
		# A lethal air finisher still completes its visible diagonal ground slam.
		if kind != &"air_finisher":
			queue_free()

func _physics_process(delta: float) -> void:
	if dead:
		super._physics_process(delta)
		if is_on_floor() and not slamming:
			queue_free()
		return
	if hit_stop_left <= 0.0:
		hitstun_left = maxf(0.0, hitstun_left - delta * simulation_rate)
		if is_on_floor() and not slamming and hitstun_left <= 0.0:
			velocity.x = 0.0
			var opponent: CharacterBody3D = trainer.player
			var offset: Vector3 = opponent.global_position - global_position
			# Commit to the telegraphed direction; never track during a strike.
			# Recovery delays the next strike, not pursuit. At inactive speed a
			# 1.2-second recovery would otherwise freeze approach for 11–13 seconds.
			var ready_to_move: bool = trainer.enabled and trainer.stagger_left <= 0.0 and trainer.windup_left <= 0.0 and trainer.active_left <= 0.0
			if opponent.combat_enabled and not opponent.dead and ready_to_move and absf(offset.x) > 1.65:
				velocity.x = signf(offset.x) * approach_speed
	super._physics_process(delta)
