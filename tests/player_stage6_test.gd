extends SceneTree
## Real worlds, input events, local clocks, scaled collision movement, and state.

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

func fresh_page(disable_enemies: bool = true, use_native_flow: bool = false) -> void:
	for action in ["move_left", "move_right", "jump", "dash", "light_attack", "heavy_attack", "parry", "restart", "light_beam"]:
		Input.action_release(action)
	if is_instance_valid(page):
		page.queue_free()
		await ticks(2)
	root.size = Vector2i(1280, 720)
	page = load("res://main.tscn").instantiate()
	if not use_native_flow:
		page.native_flow_rates = {&"Past": 1.0, &"Present": 1.0, &"Future": 1.0}
	root.add_child(page)
	current_scene = page
	panels = page.panels
	await ticks(80)
	if disable_enemies:
		for panel in panels:
			var enemy: CharacterBody3D = panel.arena.enemies.get_child(0)
			enemy.trainer.enabled = false
			enemy.trainer.rest_left = 100.0

func tap(action: String) -> void:
	Input.action_press(action)
	await ticks(1)
	Input.action_release(action)

func key(code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(1)

func close_range() -> void:
	var player: CharacterBody3D = panels[0].arena.player
	var enemy: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	player.position = Vector3(6.5, 0.8, 0.0)
	player.velocity = Vector3.ZERO
	player.facing_direction = 1
	enemy.position = Vector3(8.0, 0.8, 0.0)
	enemy.velocity = Vector3.ZERO
	await ticks(20)

func wait_for_hit(count: int) -> void:
	for i in range(60):
		if panels[0].arena.enemies.get_child(0).hit_count >= count:
			return
		await ticks(1)

func run_checks() -> void:
	await fresh_page(false)
	check(page.active_index == 0 and panels[0].arena.simulation_rate == 1.0 and is_equal_approx(panels[1].arena.simulation_rate, 0.1), "A starts at full speed with B and C locally slowed")
	check(panels[0].arena.enemies_alive == 1 and panels[1].arena.enemies_alive == 1 and panels[2].arena.enemies_alive == 1, "All three panels immediately contain a live encounter")
	var untouched_b: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	var untouched_c: CharacterBody3D = panels[2].arena.enemies.get_child(0)
	var start_b: float = untouched_b.position.x
	var start_c: float = untouched_c.position.x
	await ticks(120)
	check(page.active_index == 0 and untouched_b.position.x < start_b - 0.5 and untouched_c.position.x < start_c - 0.5, "Enemies in never-selected panels approach at slow speed without requiring a visit")
	check(panels[1].switch_hint.visible and panels[1].switch_hint.text == "2" and panels[2].switch_hint.visible and panels[2].switch_hint.text == "3" and not panels[0].switch_hint.visible, "Inactive panels display their numeric switch keys and active panel hides its marker")
	check(panels[1].switch_hint.get_global_rect().get_center().distance_to(panels[1].get_global_rect().get_center()) < 1.0, "Inactive switch marker remains centered in its panel")
	var world_ids: Array[RID] = []
	var actor_ids: Array[int] = []
	for panel in panels:
		world_ids.append(panel.arena.get_world_3d().space)
		actor_ids.append(panel.arena.player.get_instance_id())
	await key(KEY_2)
	check(page.active_index == 1 and panels[1].arena.player.input_enabled and not panels[0].arena.player.input_enabled and not panels[2].arena.player.input_enabled, "2 instantly transfers input to Panel B")
	check(not panels[1].switch_hint.visible and panels[0].switch_hint.visible and panels[0].switch_hint.text == "1", "Numeric markers follow selection while their identities stay fixed")
	check(panels[1].position.is_zero_approx() and panels[1].size.x > panels[0].size.x * 1.8 and panels[1].header.text.contains("ACTIVE"), "Selected arena takes the large frame and active border/header")
	await key(KEY_TAB)
	check(page.active_index == 2, "Tab cycles B to C")
	await key(KEY_TAB)
	check(page.active_index == 0, "Tab wraps C to A")
	await key(KEY_3)
	check(page.active_index == 2, "3 selects C directly")
	await key(KEY_1)
	var stable_worlds: bool = true
	for i in range(3):
		stable_worlds = stable_worlds and panels[i].arena.get_world_3d().space == world_ids[i] and panels[i].arena.player.get_instance_id() == actor_ids[i]
	check(stable_worlds, "Switching reuses existing worlds and actors without reparenting or resetting them")
	var old_position: Vector3 = panels[0].arena.player.position
	await key(KEY_1)
	check(panels[0].arena.player.position.is_equal_approx(old_position), "Reselecting the active panel is harmless")
	page.select_panel(-1)
	page.select_panel(3)
	check(page.active_index == 0, "Invalid selections cannot corrupt the active index")

	await key(KEY_2)
	var b_before: float = panels[1].arena.player.position.x
	var a_before: float = panels[0].arena.player.position.x
	Input.action_press("move_right")
	await ticks(8)
	check(panels[1].arena.player.position.x > b_before and is_equal_approx(panels[0].arena.player.position.x, a_before), "Movement follows selection without leaking to the outgoing player")
	page.select_panel(2)
	var c_before: float = panels[2].arena.player.position.x
	await ticks(4)
	Input.action_release("move_right")
	check(panels[2].arena.player.position.x > c_before, "Held directional movement transfers immediately on switch")

	await fresh_page()
	Input.action_press("heavy_attack")
	await ticks(1)
	page.select_panel(1)
	await ticks(10)
	check(not panels[1].arena.player.melee.attacking and not panels[0].arena.player.melee.attacking, "Held attack never becomes a ghost attack in the destination panel")
	Input.action_release("heavy_attack")
	await ticks(2)
	await tap("heavy_attack")
	check(panels[1].arena.player.melee.attacking, "A fresh attack press works immediately after releasing the transferred button")
	Input.action_press("parry")
	await ticks(1)
	page.select_panel(2)
	await ticks(1)
	check(panels[1].arena.player.parry.window_left == 0.0 and panels[2].arena.player.parry.window_left == 0.0, "Switch closes the old guard and does not copy held parry to the new player")
	Input.action_release("parry")

	await fresh_page()
	await close_range()
	var player_a: CharacterBody3D = panels[0].arena.player
	var target_a: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	await tap("heavy_attack")
	await wait_for_hit(1)
	page.select_panel(1)
	check(not player_a.melee.attacking and player_a.melee.combo_cooldown_left == 0.0 and not player_a.melee.swing.visible, "Switch cancels outgoing recovery and immediately removes its attack box")
	var launched_y: float = target_a.position.y
	await ticks(50) # Let the 60 ms contact freeze finish at 10% speed.
	check(target_a.position.y > launched_y and target_a.velocity.y > 9.0 and not target_a.is_on_floor(), "Launched enemy keeps moving slowly while its panel is inactive")
	page.select_panel(0)
	Input.action_press("jump") # Follow the suspended target with a full jump.
	Input.action_press("move_right")
	await ticks(14)
	Input.action_release("move_right")
	await ticks(4)
	Input.action_release("jump")
	await tap("light_attack")
	await wait_for_hit(2)
	await tap("light_attack")
	await wait_for_hit(3)
	await tap("heavy_attack")
	await wait_for_hit(4)
	check(target_a.hit_count == 4 and target_a.dead and target_a.velocity.x > 0.0 and target_a.velocity.y < 0.0, "Launch, switch away, return, and aerial combo still ends in a diagonal lethal slam")

	await fresh_page()
	player_a = panels[0].arena.player
	await tap("jump")
	await ticks(4)
	await tap("jump")
	await tap("dash")
	await tap("light_attack") # May be blocked during dash; budgets checked separately.
	var jump_budget: bool = player_a.air_jump_available
	var dash_budget: bool = player_a.air_dash_available
	var dash_left: float = player_a.dash_time_left
	var airborne_y: float = player_a.position.y
	page.select_panel(1)
	await ticks(8)
	check(not jump_budget and not dash_budget and not player_a.air_jump_available and not player_a.air_dash_available, "Switching does not refresh double jump or air dash allowances")
	check(player_a.position.y >= airborne_y and player_a.dash_time_left < dash_left and player_a.dash_time_left > 0.0, "An outgoing air dash continues at local slow speed without resetting momentum")
	page.select_panel(0)
	await ticks(100)
	check(player_a.is_on_floor() and player_a.air_jump_available and player_a.air_dash_available, "Returning and landing restores movement budgets without stuck dash state")

	await fresh_page()
	player_a = panels[0].arena.player
	Input.action_press("jump")
	await ticks(18)
	Input.action_release("jump")
	await tap("light_attack")
	await ticks(4)
	await tap("heavy_attack")
	await ticks(8)
	check(player_a.melee.air_lights_left == 1 and not player_a.melee.air_finisher_available, "Air attacks spend their normal budgets before switching")
	page.select_panel(1)
	page.select_panel(0)
	check(player_a.melee.air_lights_left == 1 and not player_a.melee.air_finisher_available and not player_a.melee.attacking, "Switch cancels an air attack without refunding its light or finisher allowance")

	await fresh_page()
	panels[1].arena.player.receive_damage(100)
	page.select_panel(1)
	check(panels[1].arena.result == &"defeat" and panels[1].arena.player.dead, "Selecting a defeated arena cannot revive its player")
	page.select_panel(2)
	await tap("jump")
	check(panels[2].arena.player.dead and not panels[2].arena.player.melee.attacking and panels[2].arena.result == &"defeat", "Switching cannot bypass shared health depletion")

	await fresh_page()
	# Same native velocity, ten times less displacement in inactive worlds.
	for panel in panels:
		var actor: CharacterBody3D = panel.arena.enemies.get_child(0)
		actor.position = Vector3(10.0, 5.0, 0.0)
		actor.velocity = Vector3(10.0, 0.0, 0.0)
		actor.slamming = true # Preserve horizontal velocity until ground impact.
	await ticks(6)
	var active_actor: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	var slow_actor: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	var active_distance: float = active_actor.position.x - 10.0
	var slow_distance: float = slow_actor.position.x - 10.0
	check(absf(slow_distance / active_distance - 0.1) < 0.01, "Collision movement is scaled to 10%, not only AI timers")
	check(absf(slow_actor.velocity.y / active_actor.velocity.y - 0.1) < 0.01 and slow_actor.position.y > active_actor.position.y, "Inactive gravity and fall displacement use the same local clock")
	check(is_equal_approx(slow_actor.velocity.x, 10.0), "Slow motion preserves native velocity units for seamless activation")
	page.select_panel(1)
	var resume_x: float = slow_actor.position.x
	await ticks(6)
	check(absf(slow_actor.position.x - resume_x - 1.0) < 0.05, "Reactivated actor immediately resumes full-speed movement")

	await fresh_page()
	for panel in panels:
		var actor: CharacterBody3D = panel.arena.enemies.get_child(0)
		actor.trainer.enabled = true
		actor.trainer.windup_left = 0.5
		actor.trainer.rest_left = 0.0
	await ticks(12)
	check(absf(panels[0].arena.enemies.get_child(0).trainer.windup_left - 0.3) < 0.03 and absf(panels[1].arena.enemies.get_child(0).trainer.windup_left - 0.48) < 0.01, "Enemy windups progress at full and reduced local rates")
	for panel in panels:
		panel.arena.player.apply_hit_stop(0.2)
		panel.arena.enemies.get_child(0).apply_hit_stop(0.2)
	await ticks(6)
	check(absf(panels[0].arena.player.hit_stop_left - 0.1) < 0.02 and absf(panels[1].arena.player.hit_stop_left - 0.19) < 0.01 and absf(panels[1].arena.enemies.get_child(0).hit_stop_left - 0.19) < 0.01, "Player and enemy hit-stop durations use their arena's local clock")

	await fresh_page()
	var slow_player: CharacterBody3D = panels[1].arena.player
	slow_player.receive_damage(1)
	await ticks(6)
	check(absf(slow_player.damage_flash_left - 0.64) < 0.01, "Damage feedback flash follows local time")
	panels[1].arena.enemies.get_child(0).receive_melee_hit(100, 1)
	await ticks(30)
	check(panels[1].arena.enemies_alive == 0 and panels[1].arena.next_wave_left > 0.9, "Inactive wave countdown advances slowly without pausing")
	page.select_panel(1)
	await ticks(65)
	check(panels[1].arena.wave == 2 and panels[1].arena.enemies_alive == 2, "Wave progression resumes at full speed after selecting that arena")
	check(panels[1].arena.enemies.get_child(0).simulation_rate == 1.0, "Newly spawned enemies inherit the arena's current clock")
	page.select_panel(0)
	check(is_equal_approx(panels[1].arena.enemies.get_child(0).simulation_rate, 0.1), "Switch slowdown includes enemies spawned in later waves")

	await fresh_page()
	for i in range(60):
		page.select_panel(i % 3)
		await ticks(1)
	var only_one: int = 0
	var plane_ok: bool = true
	for panel in panels:
		only_one += 1 if panel.arena.player.input_enabled else 0
		plane_ok = plane_ok and is_zero_approx(panel.arena.player.position.z)
	check(only_one == 1 and plane_ok and is_equal_approx(Engine.time_scale, 1.0), "Repeated rapid switches preserve one input owner, the depth plane, and global time")
	var camera: Camera3D = panels[page.active_index].arena.get_node("Camera3D")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = Vector2(1280, 720)
	Input.parse_input_event(motion)
	await ticks(6)
	check(camera.mouse_tilt.length() > 0.0, "Mouse camera input follows the newly selected panel")
	root.size = Vector2i(960, 540)
	await ticks(5)
	var layout_ok: bool = true
	for panel in panels:
		layout_ok = layout_ok and page.get_global_rect().encloses(panel.get_global_rect()) and panel.viewport.size == Vector2i(panel.viewport.get_parent().size)
	check(layout_ok, "Selected panel layout and render sizes remain valid after window resizing")
	var old_page: int = page.get_instance_id()
	await key(KEY_R)
	current_scene.native_flow_rates = {&"Past": 1.0, &"Present": 1.0, &"Future": 1.0}
	current_scene.update_simulation_rates()
	await ticks(80)
	page = current_scene
	panels = page.panels
	check(page.get_instance_id() != old_page and page.active_index == 0 and panels[0].arena.player.health == 6 and panels[1].arena.player.health == 6 and is_equal_approx(panels[1].arena.simulation_rate, 0.1), "R restores all encounters, default selection, and inactive slowdown")
	print("STAGE 6 CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
