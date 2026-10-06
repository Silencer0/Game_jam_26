extends "res://tests/causal_test_base.gd"

func run_checks() -> void:
	await fresh()
	var id: int = page.ledger.wave_ids[0]
	page.ledger.advance(0.59)
	check(page.ledger.state_for(id, 1) == &"missing", "Present waits for one tenth of its gap")
	page.ledger.advance(0.01)
	check(page.ledger.state_for(id, 1) == &"alive" and page.ledger.state_for(id, 0) == &"missing", "Present receives an enemy after 0.6 real seconds")
	page.ledger.advance(0.6)
	check(page.ledger.state_for(id, 0) == &"alive", "Past receives its copy after another 0.6 seconds")
	quiet()
	page.gaps.assign([2.0, 4.0])
	id = page.ledger.spawn_identity()
	page.ledger.advance(0.39)
	check(page.ledger.state_for(id, 1) == &"missing", "Reduced Future gap changes trickle delay")
	page.ledger.advance(0.01)
	check(page.ledger.state_for(id, 1) == &"alive", "A four-second gap trickles after 0.4 seconds")
	page.ledger.advance(0.2)
	check(page.ledger.state_for(id, 0) == &"alive", "Unequal gaps use their own migration delay")

	await fresh()
	page.ledger.advance(1.2)
	quiet()
	page.ledger.actor_for(page.ledger.wave_ids[0], 0).receive_melee_hit(100, 1)
	page.ledger.spawning_enabled = true
	page.ledger.advance(0.0)
	check(is_equal_approx(page.ledger.spawn_left, 0.6), "Wave clearance starts a gap/10 intermission")
	page.set_paused(true)
	page.ledger.advance(9.0)
	check(page.ledger.wave == 1 and is_equal_approx(page.ledger.spawn_left, 0.6), "Pause freezes the intermission")
	page.set_paused(false)
	page.ledger.advance(0.59)
	check(page.ledger.wave == 1, "Wave two waits until the full 0.6 seconds elapse")
	page.ledger.advance(0.011)
	check(page.ledger.wave == 2 and page.ledger.wave_ids.size() == 2, "Inactive Future still starts wave two after 0.6 real seconds")
	quiet()

	await fresh()
	page.set_paused(true)
	check(page.frame_shift_cost(2, &"Present") == 5 and page.frame_shift_cost(2, &"Past") == 10, "One-role and two-role costs are 5 and 10 ADD")
	var past: Button = page.pause_slots[0]
	var data := {"panel_session": page.get_instance_id(), "panel_index": 2}
	page.addition = 9
	check(not past._can_drop_data(Vector2.ZERO, data), "Unaffordable role drops are blocked in the real drop handler")
	page.assign_panel_role(2, &"Past")
	check(page.addition == 9 and page.panels[2].arena.temporal_role == &"Future", "Rejected swap changes neither balance nor roles")
	page.addition = 10
	check(past._can_drop_data(Vector2.ZERO, data), "Exactly ten ADD permits Future to Past")
	page.assign_panel_role(2, &"Past")
	check(page.addition == 0 and page.panels[2].arena.temporal_role == &"Past", "Two-role exchange charges ten ADD once, not twice")
	check(page.scaled_damage(1) >= 1, "Spending the entire balance preserves basic combat damage")
	page.addition = 5
	page.assign_panel_role(2, &"Present")
	check(page.addition == 0 and page.panels[2].arena.temporal_role == &"Present", "Past to Present charges five ADD")
	page.assign_panel_role(2, &"Present")
	check(page.addition == 0, "Dropping a frame on its current role is free")
	await ticks(30)
	var flying := 0
	for child in page.pause_overlay.get_children():
		if child is TextureRect:
			flying += 1
	check(flying == 0 and page.pause_slots[1].get_node("Preview").modulate.a == 1.0, "Paused flying previews settle and free their temporary controls")
	page.set_paused(false)
	page.addition = 10
	page.assign_panel_role(2, &"Future")
	check(page.addition == 10 and page.panels[2].arena.temporal_role == &"Present", "Live combat cannot spend ADD on a role swap")

	await fresh()
	page.ledger.advance(1.2)
	quiet()
	await ticks(30)
	var panel: Control = page.panels[1]
	var enemy: CharacterBody3D = page.ledger.actor_for(page.ledger.wave_ids[0], 1)
	var camera: Camera3D = panel.arena.get_node("Camera3D")
	panel.arena.player.position = Vector3(16, 0.8, 0)
	camera.update_follow()
	enemy.position = Vector3(-30, 0.8, 0)
	check(panel.offscreen_enemy_sides() == [true, false], "An enemy beyond the left clipped edge gets a left indicator")
	enemy.position = Vector3(60, 0.8, 0)
	check(panel.offscreen_enemy_sides() == [false, true], "An enemy beyond the right edge gets a right indicator")
	var other: int = page.ledger.spawn_identity()
	page.ledger.advance(1.2)
	quiet()
	page.ledger.actor_for(other, 1).position = Vector3(-30, 0.8, 0)
	check(panel.offscreen_enemy_sides() == [true, true], "Both hidden sides can warn simultaneously")
	page.ledger.actor_for(other, 1).receive_melee_hit(100, 1)
	enemy.position = Vector3(16, 0.8, 0)
	check(panel.offscreen_enemy_sides() == [false, false], "Visible enemies and dead copies do not leave stale indicators")
	page.select_panel(1)
	enemy.position = Vector3(60, 0.8, 0)
	check(panel.offscreen_enemy_sides() == [false, false], "The active panel does not display inactive-panel warnings")
	check(is_equal_approx(Engine.time_scale, 1.0), "Timing and frame shift preserve the global clock")
	finish("FRAME SHIFT FOLLOW-UP")
