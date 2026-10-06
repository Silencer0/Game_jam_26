extends CharacterBody3D
## 2.5D movement: 3D bodies, X/Y gameplay plane, Z locked to zero.
## All durations use physics delta, never frame counts.

@export var move_speed: float = 8.4
@export var jump_speed: float = 13.2
@export var gravity: float = 38.0
@export var max_fall_speed: float = 22.0
@export var dash_speed: float = 19.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.22
@export var coyote_time: float = 0.09
@export var jump_buffer_time: float = 0.10

signal defeated
signal damage_taken

@export var input_enabled: bool = true
@export var max_health: int = 6
var health_owner: Node = null
var health: int = 6
var dead: bool = false
var combat_enabled: bool = true
var damage_flash_left: float = 0.0

var simulation_rate: float = 1.0
var hit_stop_left: float = 0.0
var hit_stopped: bool = false
var dash_buffer_left: float = 0.0
var blocked_inputs: Dictionary = {}
var training_misses: int = 0

var facing_direction: int = 1
var air_dash_available: bool = true
var air_jump_available: bool = true
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var coyote_time_left: float = 0.0
var jump_buffer_left: float = 0.0
var dash_direction: int = 1
var footstep_distance: float = 0.0

@onready var parry: Node3D = $Parry
@onready var melee: Node3D = $Melee
@onready var facing_marker: MeshInstance3D = $FacingMarker

func _ready() -> void:
	health = max_health

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	jump_buffer_left = 0.0
	dash_buffer_left = 0.0
	parry.input_buffer_left = 0.0
	blocked_inputs.clear()
	if enabled:
		# Held buttons belong to the previous panel until released and pressed again.
		for action in [&"jump", &"dash", &"light_attack", &"heavy_attack", &"parry", &"dilate"]:
			if Input.is_action_pressed(action) or Input.is_action_just_pressed(action):
				blocked_inputs[action] = true
	else:
		melee.cancel_attack()
		melee.combo_cooldown_left = 0.0 # Switching cancels offensive recovery.
		parry.window_left = 0.0
		parry.guard.visible = false

func action_just_pressed(action: StringName) -> bool:
	if not input_enabled:
		return false
	if blocked_inputs.has(action):
		if not Input.is_action_pressed(action) and not Input.is_action_just_pressed(action):
			blocked_inputs.erase(action)
		return false
	return Input.is_action_just_pressed(action)

func receive_damage(damage: int) -> bool:
	if dead or not combat_enabled:
		return false
	if health_owner != null:
		health_owner.apply_shared_damage(damage)
	else:
		health = maxi(0, health - damage)
	damage_flash_left = 0.65
	melee.cancel_attack()
	parry.window_left = 0.0
	dash_time_left = 0.0
	apply_hit_stop(0.06)
	if health == 0:
		finish_defeat()
	damage_taken.emit()
	Sfx.play_cue(&"hurt", self)
	return true

func finish_defeat() -> void:
	if dead:
		return
	dead = true
	combat_enabled = false
	velocity = Vector3.ZERO
	dash_time_left = 0.0
	melee.cancel_attack()
	parry.window_left = 0.0
	parry.guard.visible = false
	defeated.emit()

func apply_hit_stop(duration: float) -> void:
	hit_stop_left = maxf(hit_stop_left, duration)

func _physics_process(delta: float) -> void:
	delta *= simulation_rate
	damage_flash_left = maxf(0.0, damage_flash_left - delta)
	$Body.visible = dead or damage_flash_left <= 0.0 or int(damage_flash_left * 20.0) % 2 == 0
	if dead:
		return
	var jump_released: bool = input_enabled and not blocked_inputs.has(&"jump") and Input.is_action_just_released("jump")
	# Capture taps even during the brief contact freeze.
	jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	dash_buffer_left = maxf(0.0, dash_buffer_left - delta)
	if action_just_pressed(&"jump"):
		jump_buffer_left = jump_buffer_time
	if action_just_pressed(&"dash"):
		dash_buffer_left = 0.10
	hit_stopped = hit_stop_left > 0.0
	if hit_stopped:
		hit_stop_left = maxf(0.0, hit_stop_left - delta)
		return
	var grounded: bool = is_on_floor()
	var direction: float = Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	if grounded:
		air_dash_available = true
		air_jump_available = true
		coyote_time_left = coyote_time
	else:
		coyote_time_left = maxf(0.0, coyote_time_left - delta)

	if direction != 0.0:
		facing_direction = 1 if direction > 0.0 else -1
	facing_marker.position.x = 0.40 * float(facing_direction)

	# A buffered jump runs before dash eligibility, so jump+dash spends the air dash.
	if jump_buffer_left > 0.0 and (coyote_time_left > 0.0 or air_jump_available):
		melee.cancel_attack()
		# The floor/coyote jump is free; only the extra airborne jump spends this.
		if coyote_time_left <= 0.0:
			air_jump_available = false
			Sfx.play_cue(&"double_jump", self)
		else:
			Sfx.play_cue(&"jump", self)
		# Jump can interrupt a dash, but does not restore its airborne allowance.
		dash_time_left = 0.0
		velocity.y = jump_speed
		jump_buffer_left = 0.0
		coyote_time_left = 0.0
		grounded = false

	if dash_buffer_left > 0.0 and dash_time_left <= 0.0 and dash_cooldown_left <= 0.0:
		if grounded or air_dash_available:
			melee.cancel_attack()
			dash_buffer_left = 0.0
			dash_direction = facing_direction
			dash_time_left = dash_duration
			dash_cooldown_left = dash_duration + dash_cooldown
			Sfx.play_cue(&"dash", self)
			coyote_time_left = 0.0
			if not grounded:
				air_dash_available = false

	if dash_time_left > 0.0:
		dash_time_left = maxf(0.0, dash_time_left - delta)
		velocity = Vector3(float(dash_direction) * dash_speed, 0.0, 0.0)
	else:
		velocity.x = direction * move_speed
		if not grounded:
			velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
			# Release jump for a shorter hop; holding gives the full jump.
			if jump_released and velocity.y > jump_speed * 0.45:
				velocity.y = jump_speed * 0.45

	# Keep both input and collision response on the side-view gameplay plane.
	velocity.z = 0.0
	# move_and_slide uses engine delta; keep stored velocity in native units.
	velocity *= simulation_rate
	var before_move := position
	move_and_slide()
	velocity /= simulation_rate
	if is_on_floor() and grounded and dash_time_left <= 0.0 and absf(direction) > 0.0:
		footstep_distance += absf(position.x - before_move.x)
		if footstep_distance >= 1.9:
			footstep_distance = fmod(footstep_distance, 1.9)
			Sfx.play_cue(&"footstep", self)
	else:
		footstep_distance = 0.0
	position.z = 0.0
	if is_on_wall() and dash_time_left > 0.0:
		dash_time_left = 0.0
	if is_on_floor():
		air_dash_available = true
		air_jump_available = true
		# End a dash on landing; do not carry an aerial dash into grounded state.
		if not grounded:
			Sfx.play_cue(&"landing", self)
			dash_time_left = 0.0
