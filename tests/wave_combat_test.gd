extends "res://tests/causal_test_base.gd"

func run_checks() -> void:
	await fresh()
	var ledger: Node = page.ledger
	page.addition = 12
	page.multiplier = 4.0
	var profile: Dictionary = ledger.difficulty_profile(6, page.addition)
	var id: int = ledger.spawn_identity(&"grunt", profile)
	ledger.advance(12.0)
	quiet()
	var enemy: CharacterBody3D = ledger.actor_for(id, 0)
	var player: CharacterBody3D = page.panels[0].arena.player
	for panel in page.panels:
		for actor in panel.arena.enemies.get_children():
			actor.position.x = 28
	player.position = Vector3(6, 0.8, 0)
	enemy.position = Vector3(7.4, 0.8, 0)
	await ticks(60)
	var health: int = enemy.health
	key(KEY_J, true)
	await ticks(1)
	key(KEY_J, false)
	await ticks(22)
	check(enemy.health == health - 48 and not enemy.dead and enemy.hit_count == 1, "Actual 48-damage high-MULT melee hits cannot one-shot a scaled wave-six grunt")
	var before: int = enemy.health
	page.addition += 100
	await ticks(2)
	check(enemy.health == before and enemy.max_health == health, "Earning more ADD never changes the current enemy HP or maximum")
	key(KEY_Q, true)
	await ticks(1)
	key(KEY_Q, false)
	await ticks(12)
	check(enemy.velocity.x > 0.0 and enemy.velocity.y > 0.0 and not enemy.is_on_floor(), "Scaled enemies still obey the actual launch input and can be interrupted")

	await fresh()
	ledger = page.ledger
	profile = ledger.difficulty_profile(6, 12)
	id = ledger.spawn_identity(&"grunt", profile)
	ledger.advance(12.0)
	quiet()
	enemy = ledger.actor_for(id, 0)
	player = page.panels[0].arena.player
	player.position = Vector3(6, 0.8, 0)
	enemy.position = Vector3(25, 0.8, 0)
	await ticks(30)
	enemy.trainer.enabled = true
	var start: float = enemy.position.x
	await ticks(30)
	var stride: float = (enemy.approach_speed - 12.0 * 0.85 / 60.0) * 0.85 * 0.5
	check(absf(start - enemy.position.x - stride) < 0.05 and enemy.approach_speed > 4.4, "Actual late-wave pursuit is faster while retaining the native Past local clock")
	enemy.position = player.position + Vector3(1.4, 0, 0)
	enemy.trainer.rest_left = 0.0
	var old_health: int = page.health
	for _i in range(80):
		if page.health < old_health:
			break
		await ticks(1)
	check(page.health == old_health - 1 and enemy.trainer.rest_left < 1.2, "Real scaled melee telegraph/strike still costs one HP and recovers faster")
	enemy.trainer.interrupt()
	check(is_equal_approx(enemy.trainer.rest_left, 1.2 * profile.recovery), "Interruption recovery uses the same bounded attack scaling")

	await fresh()
	ledger = page.ledger
	page.select_panel(2)
	page.addition = 12
	page.multiplier = 4.0
	profile = ledger.difficulty_profile(6, 12)
	id = ledger.spawn_identity(&"gunner", profile)
	quiet()
	var arena: Node3D = page.panels[2].arena
	var gunner: CharacterBody3D = ledger.actor_for(id, 2)
	player = arena.player
	for actor in arena.enemies.get_children():
		actor.position.x = 28
	player.position = Vector3(6, 0.8, 0)
	gunner.position = Vector3(14, 0.8, 0)
	await ticks(30)
	gunner.trainer.enabled = true
	gunner.trainer.rest_left = 0.0
	await ticks(2)
	check(gunner.trainer.windup_left > 0.5 and gunner.trainer.windup_duration < 0.85, "High-wave gunner starts a shorter but readable committed telegraph")
	for _i in range(60):
		if gunner.trainer.shots_fired > 0:
			break
		await ticks(1)
	check(gunner.trainer.shots_fired == 1 and gunner.trainer.rest_left < 1.8, "Actual high-wave firing uses shorter recovery and one shot per windup")
	var bolt: Node3D = arena.get_node("EnemyProjectiles").get_child(0)
	var shot_x: float = bolt.position.x
	check(is_equal_approx(bolt.speed, 4.0 * profile.projectile) and bolt.speed < 6.01, "A real emitted projectile inherits its identity's bounded wave speed")
	gunner.trainer.enabled = false
	await ticks(6)
	check(absf(shot_x - bolt.position.x - bolt.speed * 1.15 * 0.1) < 0.04, "Actual faster bullet motion still respects the Future local clock")
	player.facing_direction = 1
	player.parry.window_left = 0.2
	bolt.position = player.position + Vector3(0.8, 0.08, 0)
	bolt._physics_process(0.1)
	check(bolt.reflected and page.health == page.max_health and player.parry.successes == 1, "Higher-wave bullet remains parryable with the unchanged player window")
	gunner.position = player.position + Vector3(2.0, 0, 0)
	health = gunner.health
	await ticks(30)
	check(gunner.health == health - 96 and not gunner.dead and not is_instance_valid(bolt), "Reflected high-wave bullet applies actual ADD/MULT damage once to scaled HP")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	page.set_paused(false)
	ledger.advance(0.0)
	quiet()
	var created: CharacterBody3D = ledger.actor_for(id, ledger.panel_for_rank(2))
	check(created.max_health == profile.max_health and created.wave_number == 6 and is_equal_approx(created.trainer.projectile_speed, 4.0 * profile.projectile), "Forward copy creation through a role swap preserves the original health and weapon profile")
	check(page.multiplier == 4.0 and page.contradiction_kills == 0, "Creating stronger copies does not farm multiplier score")

	await fresh()
	for expected in range(1, 5):
		check(page.ledger.wave == expected, "Actual-input wave run reaches wave %d in sequence" % expected)
		page.ledger.advance(12.0)
		quiet()
		var ids: Array[int] = page.ledger.wave_ids.duplicate()
		for next: int in ids:
			page.select_panel(page.ledger.panel_for_rank(0))
			var victim: CharacterBody3D = page.ledger.actor_for(next, page.active_index)
			var fighter: CharacterBody3D = page.panels[page.active_index].arena.player
			for actor in fighter.get_parent().enemies.get_children():
				actor.position.x = 28
			fighter.position = Vector3(6, 0.8, 0)
			victim.position = Vector3(7.4, 0.8, 0)
			await ticks(60)
			for _i in range(100):
				if victim.dead:
					break
				key(KEY_J, true)
				await ticks(1)
				key(KEY_J, false)
				await ticks(22)
			check(victim.dead and page.ledger.state_for(next, page.ledger.panel_for_rank(2)) == &"dead", "Actual melee clears wave %d's scaled enemy and its causal later copies" % expected)
		page.ledger.spawning_enabled = true
		page.ledger.advance(0.0)
		check(page.ledger.wave_cleared and page.ledger.wave_remaining() == 0, "Actual combat completion triggers wave %d's break" % expected)
		page.ledger.advance(100.0)
		quiet()
		await ticks(2)
	check(page.ledger.wave == 5 and page.health == page.max_health and page.addition == 7, "Four complete waves progress through real melee inputs and normal ADD awards")
	key(KEY_R, true)
	await ticks(3)
	key(KEY_R, false)
	page = current_scene
	page.set_physics_process(false)
	page.ledger.spawning_enabled = false
	quiet()
	check(page.ledger.wave == 1 and page.ledger.wave_ids.size() == 1 and page.addition == 1 and page.ledger.wave_profile.max_health == 6, "Real restart resets progression, cohort, ADD snapshot and exponential difficulty")
	finish("WAVE COMBAT")
