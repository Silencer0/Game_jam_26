extends SceneTree
## Exercises real 3D overlaps and input timing in the playable sandbox.

var player: CharacterBody3D
var melee: Node3D
var practice_target: CharacterBody3D
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
	for action in ["light_attack", "move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)

func reset() -> void:
	release_inputs()
	melee.cancel_attack()
	player.position = Vector3(6.5, 0.8, 0.0)
	player.velocity = Vector3.ZERO
	player.facing_direction = 1
	player.dash_time_left = 0.0
	player.dash_cooldown_left = 0.0
	practice_target.position = Vector3(8.0, 0.75, 0.0)
	practice_target.get_node("Hurtbox").position = Vector3.ZERO
	practice_target.hit_count = 0
	practice_target.total_damage = 0
	await ticks(30)

func tap_attack() -> void:
	Input.action_press("light_attack")
	await ticks(1)
	Input.action_release("light_attack")
	await ticks(1)

func run_checks() -> void:
	var arena: Node = load("res://scenes/movement_sandbox.tscn").instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	melee = player.get_node("Melee")
	practice_target = arena.get_node("TargetA")
	await reset()
	Input.action_press("light_attack")
	await ticks(1)
	check(melee.attacking and practice_target.hit_count == 0, "Attack startup cannot hit")
	await ticks(5)
	check(practice_target.hit_count == 1 and practice_target.total_damage == 1, "Live forward hitbox delivers a light hit")
	await ticks(4)
	check(practice_target.hit_count == 1, "Overlapping across the live window hits a target only once")
	await ticks(30)
	check(not melee.attacking and not melee.get_node("Swing").visible and practice_target.hit_count == 1, "Holding attack does not repeat and recovery returns to idle")

	await reset()
	await tap_attack()
	await tap_attack()
	for i in range(25):
		if melee.combo_index == 1:
			break
		await ticks(1)
	check(melee.combo_index == 1, "Buffered second press advances the combo")
	await tap_attack()
	for i in range(70):
		if not melee.attacking:
			break
		await ticks(1)
	check(practice_target.hit_count == 3 and practice_target.total_damage == 4, "Three-hit string applies one hit per swing and stronger final damage")
	check(not melee.attacking and melee.combo_index == 0, "Combo ends cleanly after the third strike")
	for i in range(3):
		await tap_attack()
	check(not melee.attacking and practice_target.hit_count == 3, "Rapid clicks cannot restart a completed combo during cooldown")
	Input.action_press("dash")
	await ticks(1)
	check(player.dash_time_left > 0.0 and melee.combo_cooldown_left > 0.0, "Dash stays responsive without clearing combo cooldown")
	release_inputs()
	await ticks(30)
	check(not melee.attacking and practice_target.hit_count == 3, "Cooldown clicks are discarded rather than queued")
	player.position.x = 6.5
	player.velocity = Vector3.ZERO
	await ticks(2)
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 4 and practice_target.total_damage == 5, "A new string begins at the first hit")

	await reset()
	player.position.x = 9.5
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 0, "Targets behind the facing direction are not hit")
	player.facing_direction = -1
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 1 and practice_target.last_hit_direction == -1, "Left-facing attacks use the correct side")

	await reset()
	practice_target.position.x = 10.0
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 0, "Out-of-range targets are not hit")
	await reset()
	practice_target.get_node("Hurtbox").position.z = 2.0
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 0, "3D hurtbox depth is respected")

	await reset()
	var wall: StaticBody3D = StaticBody3D.new()
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.1, 2.0, 2.0)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(7.2, 1.0, 0.0)
	arena.add_child(wall)
	await ticks(2)
	await tap_attack()
	await ticks(20)
	check(practice_target.hit_count == 0, "Solid geometry blocks melee damage")
	wall.queue_free()
	await ticks(2)

	await reset()
	await tap_attack()
	Input.action_press("dash")
	await ticks(1)
	check(not melee.attacking and player.dash_time_left > 0.0 and practice_target.hit_count == 0, "Dash cancels startup without a ghost hit")
	release_inputs()
	await ticks(30)
	await reset()
	await tap_attack()
	Input.action_press("jump")
	await ticks(1)
	check(not melee.attacking and player.velocity.y > 0.0 and practice_target.hit_count == 0, "Jump cancels startup without delaying movement")
	Input.action_release("jump")
	await tap_attack()
	check(melee.attacking and melee.attack_kind == &"air_light", "Airborne light attacks are available in Stage 3")

	await reset()
	await tap_attack()
	Input.action_press("move_right")
	await ticks(4)
	check(melee.attacking and is_equal_approx(player.velocity.x, player.move_speed), "Melee preserves responsive movement")
	release_inputs()
	await ticks(30)
	for i in range(20):
		await reset()
		await tap_attack()
		if i % 2 == 0:
			Input.action_press("dash")
		else:
			Input.action_press("jump")
		await ticks(2)
		release_inputs()
		await ticks(80)
	check(not melee.attacking and player.is_on_floor() and player.dash_time_left == 0.0, "Repeated attacks and movement cancels leave no stuck state")
	for cancel_action in ["dash", "jump"]:
		await reset()
		await tap_attack()
		await tap_attack()
		for i in range(25):
			if melee.combo_index == 1:
				break
			await ticks(1)
		await tap_attack()
		for i in range(35):
			if melee.combo_index == 2 and practice_target.hit_count == 3:
				break
			await ticks(1)
		Input.action_press(cancel_action)
		await ticks(6)
		check(not melee.attacking and melee.combo_cooldown_left > 0.0, "Live finisher " + cancel_action + " cancel preserves combo cooldown")
		release_inputs()
		await ticks(80)
	print("MELEE CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
