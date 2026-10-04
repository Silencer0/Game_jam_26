extends SceneTree
## Three actual viewports/worlds: input, physics, damage, state, layout, restart.

var page: Control
var panels: Array[Node]
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

func fresh_page() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "light_attack", "heavy_attack", "parry", "restart"]:
		Input.action_release(action)
	if is_instance_valid(page):
		page.queue_free()
		await ticks(2)
	root.size = Vector2i(1280, 720)
	page = load("res://main.tscn").instantiate()
	page.inactive_simulation_rate = 1.0
	page.native_flow_rates = {&"Past": 1.0, &"Present": 1.0, &"Future": 1.0}
	root.add_child(page)
	current_scene = page
	panels = page.panels
	await ticks(45)

func tap(action: String) -> void:
	Input.action_press(action)
	await ticks(1)
	Input.action_release(action)

func place_for_contact() -> void:
	for panel in panels:
		var player: CharacterBody3D = panel.arena.player
		player.position = Vector3(6.5, 0.8, 0.0)
		player.velocity = Vector3.ZERO
		var enemy: CharacterBody3D = panel.arena.enemies.get_child(0)
		enemy.position = Vector3(8.0, 0.8, 0.0)
		enemy.velocity = Vector3.ZERO
		enemy.trainer.enabled = false
		enemy.trainer.rest_left = 30.0
	await ticks(20)

func run_checks() -> void:
	await fresh_page()
	check(panels.size() == 3 and panels[0].arena_id == &"A" and panels[1].arena_id == &"B" and panels[2].arena_id == &"C", "Page contains three distinct arena identities")
	var world_a: World3D = panels[0].arena.get_world_3d()
	var world_b: World3D = panels[1].arena.get_world_3d()
	var world_c: World3D = panels[2].arena.get_world_3d()
	check(world_a.space != world_b.space and world_a.space != world_c.space and world_b.space != world_c.space, "Each arena owns a separate 3D physics world")
	check(panels[0].arena.player.input_enabled and not panels[1].arena.player.input_enabled and not panels[2].arena.player.input_enabled, "Only Panel A accepts player input")
	var all_live: bool = true
	var all_cameras: bool = true
	for panel in panels:
		all_live = all_live and panel.arena.wave == 1 and panel.arena.enemies_alive == 1 and panel.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS
		all_cameras = all_cameras and panel.viewport.get_camera_3d() == panel.arena.get_node("Camera3D") and not panel.arena.get_node("HUD").visible
	check(all_live, "All three viewports render live independently spawned encounters")
	check(all_cameras, "Each viewport renders its own camera with a separate panel readout")
	check(panels[0].size.x > panels[1].size.x * 1.8 and panels[0].size.y > panels[1].size.y * 1.8, "Controlled panel receives the large readable frame")
	check(panels[1].get_global_rect().end.y <= panels[2].get_global_rect().position.y and page.get_global_rect().encloses(panels[2].get_global_rect()), "Stacked side panels remain separated and inside the page")
	var pixels: int = 0
	for panel in panels:
		var container: SubViewportContainer = panel.viewport.get_parent()
		check(panel.viewport.size == Vector2i(container.size), "Viewport render size follows its displayed panel size")
		pixels += panel.viewport.size.x * panel.viewport.size.y
	check(pixels < 1280 * 720, "Combined viewport pixel count stays below one full-window frame")

	await place_for_contact()
	var before: float = panels[0].arena.player.position.x
	Input.action_press("move_right")
	await ticks(8)
	Input.action_release("move_right")
	check(panels[0].arena.player.position.x > before and is_equal_approx(panels[1].arena.player.position.x, 6.5) and is_equal_approx(panels[2].arena.player.position.x, 6.5), "Movement input cannot leak into side-panel players")
	await tap("jump")
	await ticks(4)
	check(not panels[0].arena.player.is_on_floor() and panels[1].arena.player.is_on_floor() and panels[2].arena.player.is_on_floor(), "Jump input remains scoped to Panel A")
	await tap("dash")
	check(panels[0].arena.player.dash_time_left > 0.0 and panels[1].arena.player.dash_time_left == 0.0 and panels[2].arena.player.dash_time_left == 0.0, "Dash input remains scoped to Panel A")

	await fresh_page()
	await place_for_contact()
	await tap("light_attack")
	await ticks(5)
	check(panels[0].arena.enemies.get_child(0).health == 5 and panels[1].arena.enemies.get_child(0).health == 6 and panels[2].arena.enemies.get_child(0).health == 6, "Melee damages only its own world's overlapping enemy")
	check(not panels[1].arena.player.melee.attacking and not panels[2].arena.player.melee.attacking, "Attack input never starts side-panel attacks")
	await ticks(20)
	await tap("parry")
	check(panels[0].arena.player.parry.window_left > 0.0 and panels[1].arena.player.parry.window_left == 0.0 and panels[2].arena.player.parry.window_left == 0.0, "Parry input remains scoped to Panel A")

	await fresh_page()
	await place_for_contact()
	await tap("heavy_attack")
	await ticks(6)
	check(panels[0].arena.enemies.get_child(0).velocity.y > 10.0 and panels[1].arena.enemies.get_child(0).health == 6 and panels[2].arena.enemies.get_child(0).health == 6, "Q launches only the controlled arena's target")

	await fresh_page()
	await place_for_contact()
	var frozen: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	var moving_b: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	var moving_c: CharacterBody3D = panels[2].arena.enemies.get_child(0)
	for actor in [frozen, moving_b, moving_c]:
		actor.position.y = 3.0
		actor.velocity = Vector3.ZERO
	frozen.apply_hit_stop(0.2)
	await ticks(5)
	check(is_equal_approx(frozen.position.y, 3.0) and moving_b.position.y < 3.0 and moving_c.position.y < 3.0, "Contact freeze in one world does not freeze either neighboring arena")
	check(is_equal_approx(moving_b.position.y, moving_c.position.y), "Uncontrolled arenas currently simulate at the same full speed")

	await fresh_page()
	await place_for_contact()
	var camera_a: Camera3D = panels[0].arena.get_node("Camera3D")
	var camera_b: Camera3D = panels[1].arena.get_node("Camera3D")
	var camera_c: Camera3D = panels[2].arena.get_node("Camera3D")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = Vector2(1280, 720)
	Input.parse_input_event(motion)
	await ticks(5)
	check(camera_a.mouse_tilt.length() > 0.0 and camera_b.mouse_tilt.is_zero_approx() and camera_c.mouse_tilt.is_zero_approx(), "Global mouse motion gently tilts only the controlled camera")
	page.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await ticks(40)
	check(camera_a.mouse_tilt.length() < 0.01, "Controlled mouse camera recenters after focus loss")
	root.size = Vector2i(960, 540)
	await ticks(5)
	var panels_fit: bool = true
	for panel in panels:
		panels_fit = panels_fit and page.get_global_rect().encloses(panel.get_global_rect()) and panel.viewport.size == Vector2i(panel.viewport.get_parent().size)
	check(panels_fit, "Page layout and render sizes adapt to a smaller window")

	await fresh_page()
	var side_enemy: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	var side_start_x: float = side_enemy.position.x
	await ticks(230)
	check(side_enemy.position.x < side_start_x and panels[1].arena.player.health < 6 and panels[2].arena.player.health < 6, "Uncontrolled arenas keep approaching and delivering real collision damage")
	panels[1].arena.player.damage_flash_left = 0.0
	panels[1].arena.player.receive_damage(100)
	check(page.health == 0 and panels[0].arena.player.dead and panels[1].arena.player.dead and panels[2].arena.player.dead, "Shared health depletion ends all three arenas")
	await fresh_page()
	await place_for_contact()
	var arena_a: Node3D = panels[0].arena
	arena_a.enemies.get_child(0).receive_melee_hit(100, 1)
	await ticks(65)
	check(arena_a.wave == 2 and arena_a.enemies_alive == 2 and panels[2].arena.wave == 1, "Wave progress and enemy counts remain independent across panels")
	check(panels[1].status.text.contains("WAVE 1") and panels[0].status.text.contains("WAVE 2"), "Panel labels report their own independent encounter states")
	check(is_equal_approx(Engine.time_scale, 1.0), "Three-panel simulation never changes global time scale")

	var old_page_id: int = page.get_instance_id()
	var restart: InputEventKey = InputEventKey.new()
	restart.physical_keycode = KEY_R
	restart.pressed = true
	Input.parse_input_event(restart)
	await ticks(2)
	restart = InputEventKey.new()
	restart.physical_keycode = KEY_R
	restart.pressed = false
	Input.parse_input_event(restart)
	await ticks(45)
	page = current_scene
	panels = page.panels
	var reset_all: bool = page.get_instance_id() != old_page_id
	for panel in panels:
		reset_all = reset_all and panel.arena.wave == 1 and panel.arena.enemies_alive == 1 and panel.arena.player.health == 6 and panel.arena.result == &"fighting"
	check(reset_all, "R restarts the entire page once, with three clean encounters")
	print("STAGE 5 CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
