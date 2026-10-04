extends SceneTree
## Stage 3 checks run the actual actors and scripted drill through 3D physics.

var arena: Node3D
var player: CharacterBody3D
var target: CharacterBody3D
var melee: Node3D
var parry: Node3D
var trainer: Node3D
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func release_inputs() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "light_attack", "heavy_attack", "parry"]:
		Input.action_release(action)

func reset() -> void:
	release_inputs()
	trainer.enabled = false
	trainer.interrupt()
	trainer.stagger_left = 0.0
	melee.cancel_attack()
	melee.combo_cooldown_left = 0.0
	player.position = Vector3(6.5, 0.8, 0.0)
	player.velocity = Vector3.ZERO
	player.facing_direction = 1
	player.hit_stop_left = 0.0
	player.dash_time_left = 0.0
	player.dash_cooldown_left = 0.0
	player.dash_buffer_left = 0.0
	player.jump_buffer_left = 0.0
	player.training_misses = 0
	parry.window_left = 0.0
	parry.cooldown_left = 0.0
	parry.input_buffer_left = 0.0
	parry.successes = 0
	target.position = Vector3(8.0, 0.8, 0.0)
	target.velocity = Vector3.ZERO
	target.hit_stop_left = 0.0
	target.hit_count = 0
	target.total_damage = 0
	await ticks(30)

func tap(action: String) -> void:
	Input.action_press(action)
	await ticks(1)
	Input.action_release(action)

func wait_for_hit(count: int, limit: int = 50) -> void:
	for i in range(limit):
		if target.hit_count >= count:
			return
		await ticks(1)

func start_drill() -> void:
	trainer.enabled = true
	trainer.rest_left = 0.0
	await ticks(1)

func run_checks() -> void:
	arena = load("res://scenes/movement_sandbox.tscn").instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	target = arena.get_node("TargetA")
	melee = player.get_node("Melee")
	parry = player.get_node("Parry")
	trainer = target.get_node("Trainer")
	arena.get_node("TargetB/Trainer").enabled = false

	await reset()
	await start_drill()
	check(trainer.windup_left > 0.0 and player.training_misses == 0, "Training strike begins with a visible windup")
	for i in range(50):
		if trainer.windup_left > 0.0 and trainer.windup_left <= 0.06:
			break
		await ticks(1)
	melee.combo_cooldown_left = 0.2
	await tap("parry")
	for i in range(8):
		if parry.successes > 0:
			break
		await ticks(1)
	check(parry.successes == 1 and player.training_misses == 0, "Facing timed parry prevents the incoming strike")
	check(trainer.stagger_left > 0.0 and trainer.active_left == 0.0, "Parry interrupts and staggers the training attacker")
	check(melee.combo_cooldown_left == 0.0, "Successful parry restores immediate offensive initiative")
	await tap("light_attack")
	await wait_for_hit(1)
	check(target.hit_count == 1, "Attack tapped during parry hit-stop becomes an immediate counterattack")

	await reset()
	await start_drill()
	Input.action_press("parry")
	await ticks(60)
	check(parry.successes == 0 and player.training_misses == 1, "Early held parry expires and cannot become a passive block")
	release_inputs()
	await reset()
	await start_drill()
	player.facing_direction = -1
	for i in range(50):
		if trainer.windup_left > 0.0 and trainer.windup_left <= 0.06:
			break
		await ticks(1)
	await tap("parry")
	await ticks(10)
	check(parry.successes == 0 and player.training_misses == 1, "Parry cannot protect the player's back")

	await reset()
	await tap("heavy_attack")
	await wait_for_hit(1)
	check(target.velocity.x > 3.0 and target.velocity.y > 10.0 and target.total_damage == 2, "Ground heavy launches the target up and away")
	var player_position: Vector3 = player.position
	var target_position: Vector3 = target.position
	var unaffected: CharacterBody3D = arena.get_node("TargetC")
	unaffected.position.y = 3.0
	unaffected.velocity = Vector3.ZERO
	var other_y: float = unaffected.position.y
	var camera: Camera3D = arena.get_node("Camera3D")
	var camera_position: Vector3 = camera.position
	var mouse_event: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse_event.position = root.get_visible_rect().size
	Input.parse_input_event(mouse_event)
	await ticks(2)
	check(player.position.is_equal_approx(player_position) and target.position.is_equal_approx(target_position), "Hit-stop briefly freezes only the contacting actors")
	check(not camera.position.is_equal_approx(camera_position), "Mouse camera easing continues during actor hit-stop")
	check(unaffected.position.y < other_y and is_equal_approx(Engine.time_scale, 1.0), "Uninvolved actors continue and global time scale stays unchanged")
	await tap("jump")
	await ticks(4)
	check(not player.is_on_floor() and player.velocity.y > 0.0, "Jump tapped during hit-stop executes when the freeze ends")
	Input.action_press("move_right")
	await ticks(14)
	Input.action_release("move_right")
	await tap("light_attack")
	await wait_for_hit(2)
	check(target.hit_count >= 2 and melee.air_lights_left == 1, "Launched target can be followed with an aerial light hit")
	await tap("light_attack")
	await wait_for_hit(3)
	check(target.hit_count >= 3 and melee.air_lights_left == 0, "A second aerial light connects and spends the remaining air hit")
	await ticks(20)
	await tap("light_attack")
	check(not melee.attacking, "Aerial light spam cannot extend the chain indefinitely")
	await tap("heavy_attack")
	await wait_for_hit(4)
	check(target.hit_count == 4 and target.velocity.x >= 10.0 and target.velocity.y <= -18.0, "Aerial finisher slams the target diagonally forward and downward")
	await ticks(100)
	check(not target.slamming and target.velocity.is_zero_approx(), "Ground impact ends the slam without sliding or bouncing")
	check(player.is_on_floor() and target.is_on_floor() and melee.air_lights_left == 2 and melee.air_finisher_available, "Landing resets aerial allowances and both actors recover")
	check(is_zero_approx(player.position.z) and is_zero_approx(target.position.z), "Launch and finish preserve the 2.5D depth plane")

	await reset()
	target.position.x = 10.0
	await tap("heavy_attack")
	await ticks(10)
	check(target.hit_count == 0 and player.hit_stop_left == 0.0, "Whiffed heavy produces no hit-stop")

	await reset()
	await tap("light_attack")
	await wait_for_hit(1)
	await tap("dash")
	await ticks(5)
	check(player.dash_time_left > 0.0 and not melee.attacking, "Dash tapped during hit-stop resumes as a clean cancel")

	await reset()
	Input.action_press("jump")
	await ticks(8)
	Input.action_release("jump")
	await tap("light_attack")
	await ticks(5)
	melee.cancel_attack()
	await tap("light_attack")
	await ticks(5)
	melee.cancel_attack()
	await tap("light_attack")
	check(melee.air_lights_left == 0 and not melee.attacking, "Cancelling aerial attacks cannot refresh the two-hit budget")
	await ticks(100)
	check(player.is_on_floor() and melee.air_lights_left == 2, "Aerial cancellation recovery restores attacks only on landing")
	await reset()
	player.position.x = 9.5
	player.facing_direction = -1
	await tap("heavy_attack")
	await wait_for_hit(1)
	await tap("jump")
	Input.action_press("move_left")
	await ticks(20)
	Input.action_release("move_left")
	await tap("light_attack")
	await wait_for_hit(2)
	await tap("heavy_attack")
	await wait_for_hit(3)
	check(target.hit_count == 3 and target.velocity.x < 0.0 and target.velocity.y < 0.0, "Left-facing aerial finisher pushes left and down")
	await ticks(100)
	check(not melee.attacking and player.is_on_floor() and target.is_on_floor(), "Mirrored aerial sequence exits without stuck state")
	print("STAGE 3 CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
