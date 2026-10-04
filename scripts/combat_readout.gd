extends Label
## Diagnostic sandbox readout, not final game UI.

@onready var player: CharacterBody3D = get_tree().current_scene.get_node("Player") if get_tree().current_scene != null else get_parent().get_parent().get_node("Player")

func _process(_delta: float) -> void:
	text = "PARRIES: %d   MISSED STRIKES: %d   AIR LIGHTS LEFT: %d\nMiddle pink target: face it and parry as WINDUP ends." % [player.parry.successes, player.training_misses, player.melee.air_lights_left]
