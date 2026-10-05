extends SceneTree
## Raw key events catch device-specific bindings that action_press tests bypass.

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func ticks(count: int) -> void:
	for _index in range(count):
		await physics_frame
		await process_frame

func key(code: int, pressed: bool, device: int) -> void:
	var event := InputEventKey.new()
	event.device = device
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run_checks() -> void:
	var page: Control = load("res://main.tscn").instantiate()
	root.add_child(page)
	current_scene = page
	for panel in page.panels:
		for enemy in panel.arena.enemies.get_children():
			enemy.trainer.enabled = false
	await ticks(30)
	for device in [0, 16, 17]:
		var player: CharacterBody3D = page.panels[page.active_index].arena.player
		var start: float = player.position.x
		key(KEY_D, true, device)
		await ticks(5)
		check(player.position.x > start and player.velocity.x > 0.0, "D moves player from keyboard device %d" % device)
		key(KEY_D, false, device)
		key(KEY_A, true, device)
		await ticks(2)
		check(player.velocity.x < 0.0, "A reverses movement from keyboard device %d" % device)
		key(KEY_A, false, device)
		await ticks(2)
		check(is_zero_approx(player.velocity.x), "Releasing keys stops movement")
	var player: CharacterBody3D = page.panels[0].arena.player
	key(KEY_SPACE, true, 17)
	await ticks(2)
	check(player.velocity.y > 0.0, "Space starts jump")
	key(KEY_SPACE, false, 17)
	key(KEY_SHIFT, true, 17)
	await ticks(2)
	check(player.dash_time_left > 0.0, "Shift starts air dash")
	key(KEY_SHIFT, false, 17)
	key(KEY_2, true, 17)
	await ticks(2)
	check(page.active_index == 1 and page.panels[1].arena.player.input_enabled, "2 selects and enables the second panel")
	key(KEY_2, false, 17)
	key(KEY_ESCAPE, true, 17)
	await ticks(2)
	check(paused and page.pause_overlay.visible, "Escape pauses")
	key(KEY_ESCAPE, false, 17)
	await ticks(2)
	key(KEY_ESCAPE, true, 17)
	await ticks(2)
	check(not paused and page.panels[1].arena.player.input_enabled, "Escape resumes player input")
	key(KEY_ESCAPE, false, 17)
	key(KEY_D, true, 17)
	await ticks(3)
	check(page.panels[1].arena.player.velocity.x > 0.0, "Movement responds after pause and panel switch")
	key(KEY_D, false, 17)
	print("KEYBOARD INPUT CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
