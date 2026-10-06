extends "res://tests/causal_test_base.gd"
var screenshots: bool = false
var geometry: Dictionary = {}
func normalized_rect(control: Control) -> Array:
	var rect := control.get_global_rect()
	var canvas: Vector2 = root.get_visible_rect().size
	return [rect.position.x / canvas.x, rect.position.y / canvas.y, rect.size.x / canvas.x, rect.size.y / canvas.y]
func capture(name: String) -> void:
	if not screenshots:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/" + name + ".png")

func click_button(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	press.pressed = true
	root.push_input(press, true)
	await ticks(1)
	press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	root.push_input(press, true)
	await ticks(2)

func run_checks() -> void:
	screenshots = DisplayServer.get_name() != "headless"
	await fresh()
	await ticks(30)
	check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1920 and ProjectSettings.get_setting("display/window/size/viewport_height") == 1080, "Project uses a 1920x1080 canvas")
	check(ProjectSettings.get_setting("display/window/size/mode") == 3 and ProjectSettings.get_setting("display/window/size/mode.web") == 0, "Native fullscreen and gesture-driven Web fullscreen are configured separately")
	check(not page.has_node("Margin/Page/Controls") and not page.has_node("Margin/Page/Score") and page.find_children("*", "ProgressBar", true, false).is_empty(), "Main page has no detached control text, header bars or generic progress widgets")
	var big: Control = page.panels[page.active_index]
	var left: Control = page.panels[1]
	var right: Control = page.panels[2]
	check(big.position.is_equal_approx(Vector2.ZERO) and absf(big.size.x - page.panel_layout.size.x) < 1, "Active panel spans the upper page")
	check(left.position.y > big.size.y and right.position.y == left.position.y, "Both inactive panels occupy the lower strip")
	check(left.edges.w < left.edges.y and right.edges.x > right.edges.z, "Actual viewport masks create the diagonal lower gutter")
	var lower_top_gap: float = right.position.x + right.edges.x * right.size.x - left.position.x - left.edges.y * left.size.x
	var lower_bottom_gap: float = right.position.x + right.edges.z * right.size.x - left.position.x - left.edges.w * left.size.x
	check(absf(lower_top_gap - 20) < 1 and absf(lower_bottom_gap - 20) < 1, "Diagonal gutter retains a consistent 20-pixel horizontal separation")
	check(Geometry2D.is_point_in_polygon(left.size * 0.5, left.polygon()) and not Geometry2D.is_point_in_polygon(Vector2(left.size.x - 5, left.size.y - 5), left.polygon()), "Inactive geometry contains the camera center and excludes the cut corner")
	check(page.hud.anchor().x > big.position.x and page.hud.anchor().y < big.size.y and page.hud.session == page, "One shared HUD is anchored inside the active panel")
	var opening_enemy: CharacterBody3D = page.ledger.actor_for(page.ledger.wave_ids[0], 2)
	check(not opening_enemy.trainer.show_debug_text and not opening_enemy.trainer.warning.visible, "Main-game enemies retain graphical telegraphs without testing readout labels")
	check(big.status.text == "WAVE 01", "Panel footer shows only the wave, without parry or enemy counters")
	await capture("manga-page")
	page.select_panel(2)
	await ticks(1)
	check(page.active_index == 2 and page.page_tween.is_running() and page.panels[2].switch_flash > 0, "Switch immediately changes control while starting the eased ink transition")
	for i in range(18):
		page.select_panel(i % 3)
		await ticks(1)
	await ticks(30)
	big = page.panels[page.active_index]
	check(big.position.is_equal_approx(Vector2.ZERO) and big.edges.is_equal_approx(Vector4(0, 1, 0, 1)) and not page.page_tween.is_running(), "Rapid repeated switching cancels obsolete tweens and settles to the latest page")
	var controlled_count := 0
	for panel in page.panels:
		controlled_count += 1 if panel.arena.player.input_enabled else 0
		check(panel.viewport.size.x <= 1440 and panel.viewport.size.y > 64, "Each world render target stays bounded at the larger canvas size")
	check(controlled_count == 1 and is_equal_approx(Engine.time_scale, 1), "Animation preserves exactly one controlled player and global time scale")
	root.size = Vector2i(1280, 720)
	await ticks(35)
	check(page.hud.hud_scale() >= 0.7 and page.panels[page.active_index].size.x > 1200, "Window resize preserves the complete 1080p design with canvas scaling")
	root.size = Vector2i(1920, 1080)
	await ticks(35)
	page.set_paused(true)
	await ticks(12)
	var menu: Control = page.get_node("PauseOverlay/Center/Card/Margin/Menu")
	check(page.pause_page == &"timeline" and page.pause_slots[0].is_visible_in_tree() and not menu.get_node("ControlsPage").visible, "Escape opens the Timeline page with role previews and links")
	check(page.pause_overlay.z_index > page.panels[0].z_index + page.panels[0].ink.z_index and page.hud.z_index > page.pause_overlay.z_index, "Pause spread covers world frames while score-collection graphics remain visible")
	geometry["past"] = normalized_rect(page.pause_slots[0])
	geometry["future"] = normalized_rect(page.pause_slots[2])
	geometry["controls"] = normalized_rect(menu.get_node("Tabs/Controls"))
	await capture("manga-timeline")
	await click_button(menu.get_node("Tabs/Controls"))
	check(page.pause_page == &"controls" and menu.get_node("ControlsPage").visible and menu.get_node("Fullscreen").visible and not page.pause_slots[0].is_visible_in_tree(), "Real pointer input opens a separate Controls page and fullscreen button")
	check(menu.get_node("ControlsPage").BINDINGS.size() == 10, "Controls page includes movement, jump, dash, attack, launch, parry, switching, dilation, pause and restart")
	var fighter: CharacterBody3D = page.panels[page.active_index].arena.player
	var at: Vector3 = fighter.position
	key(KEY_D, true)
	await ticks(10)
	key(KEY_D, false)
	check(fighter.position == at and paused, "Reading controls cannot leak input into paused gameplay")
	await capture("manga-controls")
	geometry["fullscreen"] = normalized_rect(menu.get_node("Fullscreen"))
	geometry["timeline"] = normalized_rect(menu.get_node("Tabs/Timeline"))
	var geometry_file := FileAccess.open("res://build/qa/ui-geometry.json", FileAccess.WRITE)
	geometry_file.store_string(JSON.stringify(geometry))
	geometry_file.close()
	key(KEY_ESCAPE, true)
	await ticks(1)
	key(KEY_ESCAPE, false)
	check(paused and page.pause_page == &"timeline", "Escape from Controls returns to Timeline without accidentally resuming combat")
	key(KEY_ESCAPE, true)
	await ticks(1)
	key(KEY_ESCAPE, false)
	check(not paused and fighter.input_enabled, "Escape from Timeline resumes normal player input")
	key(KEY_D, true)
	await ticks(5)
	key(KEY_D, false)
	check(fighter.position.x > at.x, "Movement remains responsive after navigating both pause pages")
	await fresh()
	var id: int = populate()
	page.ledger.actor_for(id, 2).receive_melee_hit(100, 1)
	check(page.hud.emitted_add == 1 and page.hud.emitted_mult == 0 and page.hud.flights.size() == 1, "A genuine direct death sends exactly one ADD fragment into the HUD")
	await ticks(50)
	check(page.hud.flights.is_empty() and page.hud.add_value == page.addition, "ADD collection animation completes without withholding the logical score")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	check(page.pause_slots[0].preview_tween != null and page.pause_slots[0].preview_tween.is_running(), "Role swaps ease the pause previews as well as the underlying page")
	check(page.hud.emitted_mult == 2 and page.hud.flights.size() == 2 and page.multiplier == 3, "Two real contradiction deaths send two MULT fragments while paused")
	await ticks(60)
	check(page.hud.flights.is_empty() and page.hud.bursts.is_empty() and page.hud.mult_value == 3, "Paused meter animations complete and clean up independently of frozen combat")
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Present")
	page.assign_panel_role(2, &"Present")
	check(page.hud.emitted_mult == 2, "Repeated swaps do not create fake collection animations or rewards")
	page.set_paused(false)
	for _i in range(100):
		page.hud.launch_score(&"combat", Vector2(600, 400))
	check(page.hud.flights.size() == page.hud.MAX_FLIGHTS, "Heavy score bursts retain a bounded presentation pool")
	await ticks(80)
	check(page.hud.flights.is_empty() and page.hud.bursts.is_empty(), "All fragment trails and collection bursts expire after heavy activity")
	check(page.addition == 2 and page.multiplier == 3, "Presentation-only effects never award extra ADD or MULT")
	page.gaps.assign([0.0, 0.0])
	page.finish_singularity()
	await ticks(10)
	check(page.panels[page.active_index].size.is_equal_approx(page.panel_layout.size) and page.panels[page.active_index].edges == Vector4(0, 1, 0, 1), "Singularity expands to one unclipped final page with the shared HUD retained")
	await capture("manga-victory")
	finish("MANGA UI")
