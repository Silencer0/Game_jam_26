extends "res://scripts/training_striker.gd"
## Reuses the proven telegraph, collision query, facing parry, and hit-stop.

func _physics_process(delta: float) -> void:
	if player.dead or not player.combat_enabled:
		interrupt()
		enabled = false
		super._physics_process(delta)
		return
	super._physics_process(delta)
	if enabled and stagger_left <= 0.0 and windup_left <= 0.0 and active_left <= 0.0 and actor.is_on_floor():
		warning.text = "RECOVER" if rest_left > 0.0 else "APPROACH"

func on_unparried_strike() -> void:
	player.receive_damage(1)
