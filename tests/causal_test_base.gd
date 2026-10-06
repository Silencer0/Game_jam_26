extends SceneTree
var page: Control
var failures := 0
func _initialize() -> void:
	call_deferred("run_checks")
func ticks(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func fresh() -> void:
	paused = false
	for action in InputMap.get_actions():
		Input.action_release(action)
	if is_instance_valid(page):
		page.queue_free()
		await ticks(2)
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	page = load("res://main.tscn").instantiate()
	root.add_child(page)
	current_scene = page
	page.set_physics_process(false)
	page.ledger.spawning_enabled = false
	await ticks(2)
	quiet()
func quiet() -> void:
	for panel in page.panels:
		for enemy in panel.arena.enemies.get_children():
			enemy.trainer.enabled = false
func populate() -> int:
	page.ledger.advance(12.0)
	quiet()
	return page.ledger.records.keys()[0]
func key(code: int, held: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = held
	Input.parse_input_event(event)
func finish(name: String) -> void:
	print(name, " COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
