extends SceneTree

var player: CharacterBody3D
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
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)

func reset_player() -> void:
	release_inputs()
	player.position = Vector3(5.2, 0.8, 0)
	player.velocity = Vector3.ZERO
	player.facing_direction = 1
	player.dash_time_left = 0.0
	player.dash_cooldown_left = 0.0
	await ticks(30)

func run_checks() -> void:
	var arena: Node = load("res://scenes/movement_sandbox.tscn").instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	await ticks(30)
	check(player.is_on_floor(), "Player settles on floor")
	var start_x: float = player.position.x
	Input.action_press("move_right")
	await ticks(10)
	check(player.position.x > start_x + 1.0 and player.facing_direction == 1, "Right movement and facing")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await ticks(1)
	check(player.velocity.x < 0.0 and player.facing_direction == -1, "Immediate reversal and left facing")
	Input.action_release("move_left")
	await ticks(1)
	check(is_zero_approx(player.velocity.x), "Immediate horizontal stop")
	await reset_player()
	start_x = player.position.x
	Input.action_press("dash")
	await ticks(1)
	check(player.dash_time_left > 0.0 and player.velocity.x > player.move_speed, "Ground dash starts")
	Input.action_release("dash")
	await ticks(30)
	check(player.position.x > start_x + 1.8 and player.dash_time_left == 0.0 and is_zero_approx(player.velocity.x), "Ground dash ends and returns control")
	await reset_player()
	var start_y: float = player.position.y
	Input.action_press("jump")
	await ticks(3)
	check(player.position.y > start_y + 0.4 and not player.is_on_floor(), "Jump leaves floor")
	await ticks(10)
	Input.action_press("dash")
	await ticks(1)
	check(player.dash_time_left > 0.0 and not player.air_dash_available, "Air dash consumes airborne allowance")
	Input.action_release("dash")
	await ticks(23)
	check(not player.is_on_floor(), "Still airborne for second dash attempt")
	Input.action_press("dash")
	await ticks(1)
	check(player.dash_time_left == 0.0 and not player.air_dash_available, "Second airborne dash is rejected after cooldown")
	release_inputs()
	await ticks(60)
	check(player.is_on_floor() and player.air_dash_available and player.dash_time_left == 0.0, "Landing restores one air dash and clears dash state")
	Input.action_press("jump")
	await ticks(2)
	Input.action_press("dash")
	await ticks(1)
	check(player.dash_time_left > 0.0 and not player.air_dash_available, "Next jump can spend the refreshed air dash")
	await reset_player()
	for i in range(15):
		Input.action_press("move_right" if i % 2 == 0 else "move_left")
		Input.action_press("jump")
		await ticks(2)
		Input.action_press("dash")
		await ticks(1)
		release_inputs()
		await ticks(50)
	check(player.is_on_floor() and player.dash_time_left == 0.0 and player.dash_cooldown_left == 0.0, "Repeated jumping/dashing does not stick state")
	await reset_player()
	player.position = Vector3(46.6, 0.8, 0)
	Input.action_press("move_right")
	Input.action_press("dash")
	await ticks(15)
	check(player.position.x <= 46.881 and player.dash_time_left == 0.0, "Wall collision stops dash without tunneling")
	release_inputs()
	Input.action_press("move_left")
	await ticks(3)
	check(player.velocity.x < 0.0, "Can move away from wall after dash")
	release_inputs()
	player.velocity.z = 10.0
	await ticks(10)
	check(is_zero_approx(player.position.z) and is_zero_approx(player.velocity.z), "Movement and collision remain on Z=0 plane")
	player.position = Vector3(24.0, 0.8, 0.0)
	player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	await ticks(10)
	var camera: Camera3D = arena.get_node("Camera3D")
	check(absf(camera.position.x - player.position.x) < 0.01, "3D camera follows horizontal movement")
	release_inputs()
	player.position = Vector3(13.0, 4.0, 0.0)
	player.velocity = Vector3.ZERO
	player.air_dash_available = false
	await ticks(60)
	check(player.is_on_floor() and absf(player.position.y - 2.36) < 0.05 and player.air_dash_available, "Solid 3D platform catches player and restores air dash")
	await reset_player()
	Input.action_press("jump")
	await ticks(5)
	Input.action_release("jump")
	await ticks(5)
	Input.action_press("jump")
	await ticks(1)
	check(player.velocity.y > player.jump_speed * 0.9 and not player.air_jump_available, "Second jump provides a fresh upward impulse")
	await ticks(20)
	check(not player.is_on_floor() and player.velocity.y < 1.0, "Holding jump does not repeat airborne jumps")
	Input.action_release("jump")
	await ticks(1)
	var velocity_before: float = player.velocity.y
	Input.action_press("jump")
	await ticks(1)
	check(player.velocity.y < velocity_before and not player.air_jump_available, "Third jump is rejected before landing")
	Input.action_release("jump")
	Input.action_press("dash")
	await ticks(1)
	check(not player.air_dash_available and not player.air_jump_available, "Air dash does not restore the extra jump")
	release_inputs()
	await ticks(90)
	check(player.is_on_floor() and player.air_jump_available and player.air_dash_available, "Landing restores both airborne allowances")
	Input.action_press("jump")
	await ticks(3)
	Input.action_release("jump")
	Input.action_press("dash")
	await ticks(2)
	Input.action_press("jump")
	await ticks(1)
	check(player.velocity.y > 0.0 and player.dash_time_left == 0.0 and not player.air_dash_available and not player.air_jump_available, "Double jump interrupts dash without restoring it")
	await reset_player()
	player.position = Vector3(24.0, 0.8, 0.0)
	await ticks(30)
	var mouse_event: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse_event.position = root.get_visible_rect().size * 3.0
	Input.parse_input_event(mouse_event)
	await ticks(1)
	check(absf(camera.position.x - player.position.x) < 1.0, "Mouse camera motion eases in rather than snapping")
	await ticks(60)
	var camera_offset: Vector3 = camera.position - Vector3(player.position.x, 3.6, 0.0)
	var yaw_degrees: float = rad_to_deg(atan2(camera_offset.x, camera_offset.z))
	var pitch_change: float = rad_to_deg(atan2(camera_offset.y, Vector2(camera_offset.x, camera_offset.z).length()) - atan2(camera.base_elevation, 20.0))
	check(yaw_degrees > camera.mouse_yaw_degrees * 0.9 and yaw_degrees <= camera.mouse_yaw_degrees + 0.01 and absf(pitch_change) <= camera.mouse_pitch_degrees + 0.01, "Mouse orbit is bounded to small yaw and pitch angles")
	check(is_zero_approx(player.position.z), "Mouse camera tilt never changes the player depth plane")
	camera.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await ticks(60)
	check(absf(camera.position.x - player.position.x) < 0.02, "Camera recenters smoothly when application loses focus")
	print("MOVEMENT CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
