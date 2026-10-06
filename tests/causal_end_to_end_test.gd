extends "res://tests/causal_test_base.gd"
## Complete the new loop through raw attack, pause, GUI drag and hold-E input.
var snapshots: bool = false
func capture(name: String) -> void:
	if not snapshots:
		return
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://build/qa/" + name + ".png")

func drag_role(source_index: int, target_rank: int) -> void:
	key(KEY_ESCAPE, true)
	await ticks(1)
	key(KEY_ESCAPE, false)
	await ticks(2)
	var source: Vector2 = page.pause_buttons[source_index].get_global_rect().get_center()
	var target: Vector2 = page.pause_slots[target_rank].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = source
	motion.global_position = source
	root.push_input(motion, true)
	await ticks(1)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.position = source
	press.global_position = source
	root.push_input(press, true)
	await ticks(2)
	motion = InputEventMouseMotion.new()
	motion.position = target
	motion.global_position = target
	motion.relative = target - source
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await ticks(3)
	press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = target
	press.global_position = target
	press.pressed = false
	root.push_input(press, true)
	await ticks(3)
	check(page.panels[source_index].arena.temporal_role == page.ROLE_NAMES[target_rank], "Actual mouse drag swaps the selected arena into its target role")
	await capture("pause-links")
	key(KEY_ESCAPE, true)
	await ticks(1)
	key(KEY_ESCAPE, false)
	await ticks(2)

func defeat_future(id: int, shift_after: bool = true, target_rank: int = 2) -> void:
	var future: int = page.ledger.panel_for_rank(target_rank)
	page.select_panel(future)
	var victim: CharacterBody3D = page.ledger.actor_for(id, future)
	var player: CharacterBody3D = page.panels[future].arena.player
	player.position = Vector3(6, 0.8, 0)
	victim.position = Vector3(7.4, 0.8, 0)
	quiet()
	await ticks(60)
	var old_add: int = page.addition
	for _i in range(12):
		if victim.dead:
			break
		key(KEY_J, true)
		await ticks(1)
		key(KEY_J, false)
		await ticks(22)
	check(victim.dead and page.addition == old_add + 1, "Raw melee input earns one ADD by killing a Future representation")
	await capture("future-death")
	if shift_after:
		# Earn the real shift cost through raw combat, without injected ADD.
		while page.addition < page.frame_shift_cost(future, &"Past"):
			var funding_id: int = page.ledger.spawn_identity()
			check(funding_id > 0, "A funding encounter fits within the population bound")
			if funding_id < 0:
				break
			page.ledger.advance(1.2)
			quiet()
			await defeat_future(funding_id, false, 0)
		await drag_role(future, 0)

func hold_ultimate(rank: int) -> void:
	page.select_panel(page.ledger.panel_for_rank(rank))
	page.set_physics_process(true)
	await ticks(2) # Observe the released E after fixture-paused session processing.
	key(KEY_E, true)
	await ticks(12)
	check(page.dilation.charging, "Raw held E starts charging an earned MULT meter")
	await capture("dilation")
	for _i in range(400):
		if not page.dilation.charging:
			break
		await ticks(1)
	key(KEY_E, false)
	await ticks(2)
	page.set_physics_process(false)
	check(page.dilation.spent_total > 0 and (page.multiplier == 1.0 or page.result == &"singularity"), "Holding spends whole earned charges until the spare MULT is exhausted")

func run_checks() -> void:
	snapshots = DisplayServer.get_name() != "headless"
	await fresh()
	await capture("gameplay")
	var first: int = populate()
	var second: int = page.ledger.spawn_identity()
	page.ledger.advance(12.0)
	quiet()
	await defeat_future(first)
	await defeat_future(second)
	check(page.multiplier == page.MAX_MULT and page.contradiction_kills >= 3, "Genuine kills plus GUI contradictions earn a full MULT bar")
	for rank in [0, 2]:
		for batch in range(2):
			if rank != 0 or batch != 0:
				for _i in range(3):
					if page.multiplier >= page.MAX_MULT:
						break
					var next: int = page.ledger.spawn_identity()
					page.ledger.advance(12.0)
					quiet()
					await defeat_future(next)
				check(page.multiplier == page.MAX_MULT, "Genuine contradictions refill MULT for another three-second gap reduction")
			await hold_ultimate(rank)
		check(page.gaps[0 if rank == 0 else 1] == 0.0, "Two earned three-charge batches close the six-second gap")
		if rank == 0:
			check(page.result == &"fighting", "One closed gap keeps the encounter running")
	await ticks(3)
	check(page.result == &"singularity" and page.health > 0, "Complete actual-input loop reaches singularity without forced scores or gaps")
	await capture("singularity")
	finish("CAUSAL END TO END")
