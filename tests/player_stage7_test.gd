extends "res://tests/player_stage6_test.gd"
## Temporal role permutations, separate clocks, state preservation, and pause UI.

func roles() -> String:
	return "%s/%s/%s" % [panels[0].arena.temporal_role, panels[1].arena.temporal_role, panels[2].arena.temporal_role]

func run_checks() -> void:
	await fresh_page(true, true)
	check(roles() == "Past/Present/Future", "Initial roles assign one Past, Present, and Future to fixed panel identities")
	check(is_equal_approx(panels[0].arena.simulation_rate, 0.7) and is_equal_approx(panels[1].arena.simulation_rate, 0.1) and is_equal_approx(panels[2].arena.simulation_rate, 0.13), "Native flow multiplies activity speed: active Past 70%, inactive Present 10%, Future 13%")
	page.select_panel(2)
	check(is_equal_approx(panels[2].arena.simulation_rate, 1.3) and is_equal_approx(panels[0].arena.simulation_rate, 0.07), "Selected Future runs at 130% while inactive Past runs at 7%")
	check(panels[2].header.text.contains("FUTURE") and panels[2].header.text.contains("130%"), "Header exposes temporal role and effective speed")
	page.select_panel(0)
	var actor_ids: Array[int] = []
	var spaces: Array[RID] = []
	var positions: Array[Vector3] = []
	for panel in panels:
		actor_ids.append(panel.arena.player.get_instance_id())
		spaces.append(panel.arena.get_world_3d().space)
		positions.append(panel.arena.player.position)
	panels[0].arena.player.receive_damage(1)
	var permutations: Dictionary = {}
	for i in range(3):
		permutations[roles()] = true
		page.twist_timeline()
	page.twist_timeline(true)
	for i in range(3):
		permutations[roles()] = true
		page.twist_timeline()
	check(permutations.size() == 6, "Rotate and Past/Future swap can reach all six temporal permutations")
	check(page.active_index == 0 and page.health == 5, "Twisting preserves selected arena and shared health")
	var state_preserved: bool = true
	for index in range(3):
		state_preserved = state_preserved and panels[index].arena.player.get_instance_id() == actor_ids[index] and panels[index].arena.get_world_3d().space == spaces[index] and panels[index].arena.player.position.is_equal_approx(positions[index])
	check(state_preserved, "Twisting never recreates or moves gameplay actors or physics worlds")
	await key(KEY_T)
	check(roles() == "Past/Future/Present", "T keyboard input rotates assignments")
	await key(KEY_Y)
	check(roles() == "Future/Past/Present", "Y keyboard input exchanges Past and Future")
	check(panels[0].switch_hint.text == "1" and panels[1].switch_hint.text == "2" and panels[2].switch_hint.text == "3", "Switch numbers always follow arena identity, never temporal role")

	await fresh_page(true, true)
	await tap("light_attack")
	var player: CharacterBody3D = panels[0].arena.player
	var elapsed: float = player.melee.attack_elapsed
	page.twist_timeline()
	check(player.melee.attacking and player.melee.attack_elapsed == elapsed, "Twisting changes flow without cancelling or resetting an ongoing attack")
	var enemy: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	enemy.receive_melee_hit(2, 1, &"launcher")
	var velocity: Vector3 = enemy.velocity
	page.twist_timeline()
	check(enemy.velocity.is_equal_approx(velocity) and enemy.health == 4, "Twisting preserves launch momentum and enemy health")
	player.air_jump_available = false
	player.air_dash_available = false
	player.melee.air_lights_left = 0
	player.melee.air_finisher_available = false
	page.twist_timeline(true)
	check(not player.air_jump_available and not player.air_dash_available and player.melee.air_lights_left == 0 and not player.melee.air_finisher_available, "Twisting cannot refund airborne allowances")

	await fresh_page(true, true)
	for actor in panels[0].arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(2)
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1) and is_equal_approx(panels[2].arena.simulation_rate, 0.13), "Clearing a wave leaves inactive role speeds unchanged")
	page.twist_timeline(true)
	check(is_equal_approx(panels[0].arena.simulation_rate, 1.3) and is_equal_approx(panels[2].arena.simulation_rate, 0.07), "Twisting applies native multipliers independent of wave progress")

	await fresh_page(true, true)
	await key(KEY_ESCAPE)
	check(paused and page.pause_overlay.visible, "Esc pauses the game and opens the overlay menu")
	var saved_positions: Array[Vector3] = []
	var saved_windups: Array[float] = []
	for panel in panels:
		var actor: CharacterBody3D = panel.arena.enemies.get_child(0)
		actor.velocity.y = 5.0
		actor.trainer.windup_left = 0.5
		actor.trainer.enabled = true
		saved_positions.append(actor.position)
		saved_windups.append(actor.trainer.windup_left)
	var health_before: int = page.health
	await ticks(40)
	var all_frozen: bool = true
	for index in range(3):
		var actor: CharacterBody3D = panels[index].arena.enemies.get_child(0)
		all_frozen = all_frozen and actor.position.is_equal_approx(saved_positions[index]) and actor.trainer.windup_left == saved_windups[index]
	check(all_frozen and page.health == health_before, "Pause freezes all three worlds, attack timers, and damage")
	page.pause_buttons[1].pressed.emit()
	check(paused and page.active_index == 1 and page.pause_buttons[1].tooltip_text.contains("selected"), "Menu button selects Panel 2 while keeping the game paused")
	page.twist_timeline()
	check(paused and roles() == "Present/Future/Past" and page.active_index == 1, "Pause menu can twist roles without changing input ownership")
	var slot: Button = page.pause_slots[0]
	var drag_data: Dictionary = {"panel_session": page.get_instance_id(), "panel_index": 1}
	var before_position: Vector3 = panels[1].arena.player.position
	check(slot._can_drop_data(Vector2.ZERO, drag_data), "Role slots accept panel drags from this session")
	slot._drop_data(Vector2.ZERO, drag_data)
	check(paused and roles() == "Present/Past/Future" and page.active_index == 1, "Dropping a panel swaps roles while preserving pause and selection")
	check(panels[1].arena.player.position == before_position and page.pause_buttons[1] == slot, "Dragged panel retains gameplay state and moves to its role slot")
	slot._drop_data(Vector2.ZERO, drag_data)
	check(roles() == "Present/Past/Future", "Dropping onto the existing role leaves assignments unchanged")
	check(not slot._can_drop_data(Vector2.ZERO, {"panel_session": -1, "panel_index": 1}) and not slot._can_drop_data(Vector2.ZERO, {"panel_session": page.get_instance_id(), "panel_index": 8}), "Role slots reject foreign and invalid drags")
	await key(KEY_3)
	check(paused and page.active_index == 2, "Number shortcuts also select panels safely while paused")
	Input.action_press("light_attack")
	page.get_node("PauseOverlay/Center/Card/Margin/Menu/Resume").pressed.emit()
	await ticks(2)
	check(not paused and not page.pause_overlay.visible and not panels[2].arena.player.melee.attacking, "Resume unpauses without turning a menu-time held button into an attack")
	Input.action_release("light_attack")
	await ticks(2)
	await tap("light_attack")
	check(panels[2].arena.player.melee.attacking, "Fresh combat input works after resuming")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	check(not paused and not page.pause_overlay.visible, "Esc toggles the menu closed and resumes")
	await key(KEY_ESCAPE)
	page.get_node("PauseOverlay/Center/Card/Margin/Menu/Restart").pressed.emit()
	await ticks(80)
	page = current_scene
	panels = page.panels
	check(not paused and page.health == 6 and page.active_index == 0 and roles() == "Past/Present/Future" and not page.pause_overlay.visible, "Restart from pause restores health, default roles, selection, and running state")
	check(is_equal_approx(Engine.time_scale, 1.0), "Temporal roles and pause never change global time scale")
	print("STAGE 7 / PAUSE CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
