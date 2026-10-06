extends "res://scripts/melee_grunt.gd"
## Launchable gunner: slower repositioning, no contact damage, one readable shot.

func _ready() -> void:
	super._ready()
	trainer.rest_left = 1.0 * trainer.recovery_factor
	visual.scale = Vector3.ONE
	readout.text = "GUNNER %d / %d" % [health, max_health]

func receive_melee_hit(damage: int, direction: int, kind: StringName = &"ground_light") -> void:
	super.receive_melee_hit(damage, direction, kind)
	readout.text = "GUNNER %d / %d" % [health, max_health]

func approach_velocity() -> float:
	var opponent: CharacterBody3D = trainer.player
	if opponent.dead or not opponent.combat_enabled:
		return 0.0
	var offset: float = opponent.position.x - position.x
	if absf(offset) > 11.0:
		return signf(offset) * approach_speed * 0.75
	if absf(offset) < 5.0:
		var retreat: float = -signf(offset) if not is_zero_approx(offset) else 1.0
		if (retreat < 0.0 and position.x > 2.0) or (retreat > 0.0 and position.x < 30.0):
			return retreat * approach_speed * 0.75
	return 0.0
