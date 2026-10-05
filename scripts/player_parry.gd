extends Node3D
## A brief timed defense, never a held block. Training strikes call try_parry.

@export var parry_window: float = 0.25
@export var parry_cooldown: float = 0.35
var window_left: float = 0.0
var cooldown_left: float = 0.0
var input_buffer_left: float = 0.0
var successes: int = 0
var success_visual_left: float = 0.0

@onready var player: CharacterBody3D = get_parent()
@onready var guard: MeshInstance3D = $Guard

func _physics_process(delta: float) -> void:
	delta *= player.simulation_rate
	success_visual_left = maxf(0.0, success_visual_left - delta)
	if not player.combat_enabled:
		window_left = 0.0
		guard.visible = false
		return
	input_buffer_left = maxf(0.0, input_buffer_left - delta)
	if player.action_just_pressed(&"parry"):
		input_buffer_left = 0.12
	if player.hit_stopped:
		return
	window_left = maxf(0.0, window_left - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if player.dash_time_left > 0.0:
		window_left = 0.0
	elif input_buffer_left > 0.0 and cooldown_left <= 0.0:
		player.melee.cancel_attack()
		window_left = parry_window
		cooldown_left = parry_cooldown
		input_buffer_left = 0.0
	guard.position.x = 0.45 * float(player.facing_direction)
	guard.visible = window_left > 0.0

func try_parry(attacker: Node3D) -> bool:
	if window_left <= 0.0:
		return false
	var toward_attacker: float = attacker.global_position.x - player.global_position.x
	if toward_attacker * float(player.facing_direction) < 0.0:
		return false
	window_left = 0.0
	guard.visible = false
	cooldown_left = 0.0
	successes += 1
	success_visual_left = 0.18
	player.melee.cancel_attack()
	# Successful defense immediately gives back offensive initiative.
	player.melee.combo_cooldown_left = 0.0
	player.apply_hit_stop(0.06)
	attacker.on_parried()
	return true
