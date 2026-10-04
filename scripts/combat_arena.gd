extends Node3D
## Reusable single-arena encounter: three finite grunt waves, defeat/victory, and instant restart.

const ENEMY_SCENE: PackedScene = preload("res://scenes/melee_grunt.tscn")
const RANGED_SCENE: PackedScene = preload("res://scenes/ranged_enemy.tscn")
var WAVE_SIZES: Array[int] = [1, 2, 3] # Preserved standalone encounter.
@export var restart_enabled: bool = true
@export var ranged_enemies_enabled: bool = false

var temporal_role: StringName = &"Present"
var simulation_rate: float = 1.0

var wave: int = 0
var enemies_alive: int = 0
var defeated_count: int = 0
var next_wave_left: float = 0.6
var result: StringName = &"fighting"

@onready var player: CharacterBody3D = $Player
@onready var enemies: Node3D = $Enemies
@onready var readout: Label = $HUD/CombatReadout

func _ready() -> void:
	if ranged_enemies_enabled:
		WAVE_SIZES = [1, 2, 1, 2]
	player.defeated.connect(on_player_defeated)
	spawn_wave() # All panels begin with an encounter before local slowdown applies.

func set_simulation_rate(rate: float) -> void:
	simulation_rate = clampf(rate, 0.01, 1.15)
	player.simulation_rate = simulation_rate
	for enemy in enemies.get_children():
		enemy.simulation_rate = simulation_rate

func _unhandled_input(event: InputEvent) -> void:
	if restart_enabled and event.is_action_pressed("restart") and not event.is_echo():
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	delta *= simulation_rate
	if result != &"fighting":
		return
	if enemies_alive == 0:
		next_wave_left = maxf(0.0, next_wave_left - delta)
		if next_wave_left <= 0.0:
			spawn_wave()

func spawn_wave() -> void:
	if result != &"fighting" or enemies_alive > 0:
		return
	wave += 1
	if wave > WAVE_SIZES.size():
		result = &"victory"
		player.combat_enabled = false
		player.melee.cancel_attack()
		return
	for index in range(WAVE_SIZES[wave - 1]):
		var enemy: CharacterBody3D = RANGED_SCENE.instantiate() if ranged_enemies_enabled and (wave == 3 or (wave == 4 and index == 1)) else ENEMY_SCENE.instantiate()
		# Alternate sides, keep spawn away from the player and inside arena walls.
		var side: float = 1.0 if index % 2 == 0 else -1.0
		var spawn_x: float = clampf(player.position.x + side * (7.0 + float(index) * 2.0), 2.0, 30.0)
		if absf(spawn_x - player.position.x) < 4.0:
			spawn_x = clampf(player.position.x - side * 7.0, 2.0, 30.0)
		enemy.position = Vector3(spawn_x, 0.8, 0.0)
		enemy.simulation_rate = simulation_rate
		enemy.defeated.connect(on_enemy_defeated)
		enemies.add_child(enemy)
		enemies_alive += 1

func on_enemy_defeated() -> void:
	enemies_alive -= 1
	defeated_count += 1
	if enemies_alive == 0:
		next_wave_left = 1.0

func on_player_defeated() -> void:
	result = &"defeat"

func _process(_delta: float) -> void:
	readout.text = status_text()

func status_text(include_health: bool = true) -> String:
	var status: String
	if result == &"victory":
		status = "ARENA CLEAR — R to replay"
	elif result == &"defeat":
		status = "DEFEATED — R to retry"
	elif enemies_alive == 0:
		status = "Next wave incoming..."
	else:
		status = "WAVE %d / %d   ENEMIES: %d" % [wave, WAVE_SIZES.size(), enemies_alive]
	var counters: String = "PARRIES: %d   DEFEATED: %d\n%s" % [player.parry.successes, defeated_count, status]
	return ("HP: %d / %d   " % [player.health, player.max_health] if include_health else "") + counters
