extends CharacterBody3D
## Launchable test actor: no health, death, chasing, or enemy decisions.

@export var training_strike_enabled: bool = false
var slamming: bool = false
var hit_count: int = 0
var total_damage: int = 0
var last_hit_direction: int = 1
var feedback_time_left: float = 0.0
var simulation_rate: float = 1.0
var hit_stop_left: float = 0.0
var hit_stopped: bool = false

@onready var visual: Node3D = $Visual
@onready var readout: Label3D = $Readout
@onready var trainer: Node3D = $Trainer

func _ready() -> void:
	trainer.enabled = training_strike_enabled

func apply_hit_stop(duration: float) -> void:
	hit_stop_left = maxf(hit_stop_left, duration)

func receive_melee_hit(damage: int, direction: int, kind: StringName = &"ground_light") -> void:
	Sfx.play_cue(&"heavy_hit" if kind in [&"launcher", &"air_finisher", &"reflected_shot"] else &"hit", self)
	hit_count += 1
	total_damage += damage
	last_hit_direction = direction
	feedback_time_left = 0.12
	visual.scale = Vector3(1.12, 0.9, 1.12)
	readout.text = "HITS: %d\nTOTAL: %d" % [hit_count, total_damage]
	trainer.interrupt()
	if kind == &"launcher":
		velocity = Vector3(float(direction) * 8.0, 10.5, 0.0)
	elif kind == &"air_light" and not is_on_floor():
		velocity.y = maxf(velocity.y, 4.0)
	elif kind == &"air_finisher":
		slamming = true
		velocity = Vector3(float(direction) * 10.0, -18.0, 0.0)

func on_parried() -> void:
	trainer.stagger_left = 1.0
	trainer.interrupt()
	apply_hit_stop(0.06)

func _physics_process(delta: float) -> void:
	delta *= simulation_rate
	hit_stopped = hit_stop_left > 0.0
	if hit_stopped:
		hit_stop_left = maxf(0.0, hit_stop_left - delta)
		return
	if feedback_time_left > 0.0:
		feedback_time_left = maxf(0.0, feedback_time_left - delta)
		if feedback_time_left <= 0.0:
			visual.scale = Vector3.ONE
	velocity.y = maxf(velocity.y - 18.0 * delta, -20.0)
	if not slamming:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = 0.0
	# move_and_slide uses engine delta; keep stored velocity in native units.
	velocity *= simulation_rate
	move_and_slide()
	velocity /= simulation_rate
	if slamming and is_on_floor():
		Sfx.play_cue(&"slam", self)
		velocity = Vector3.ZERO
		slamming = false
	position.z = 0.0
