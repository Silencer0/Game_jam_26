extends "res://tests/player_stage6_test.gd"
## Actual collision strikes, distinct-hit damage, misses, parries, wave-independent flow.

func prepare_strike(actor: CharacterBody3D, victim: CharacterBody3D) -> void:
	actor.position = victim.position + Vector3(1.5, 0.23, 0.0)
	actor.velocity = Vector3.ZERO
	actor.trainer.interrupt()
	actor.trainer.enabled = false
	await ticks(3)
	actor.trainer.windup_duration = 0.02
	actor.trainer.rest_left = 0.0
	actor.trainer.enabled = true

func wait_for_damage(previous: int) -> void:
	for i in range(100):
		if page.health < previous:
			return
		await ticks(1)

func clear_current_wave(index: int) -> void:
	for enemy in panels[index].arena.enemies.get_children():
		enemy.receive_melee_hit(100, 1)
	await ticks(2)

func run_checks() -> void:
	await fresh_page()
	for index in range(3):
		var actor: CharacterBody3D = panels[index].arena.enemies.get_child(0)
		var victim: CharacterBody3D = panels[index].arena.player
		var previous: int = page.health
		await prepare_strike(actor, victim)
		await wait_for_damage(previous)
		check(page.health == previous - 1 and actor.trainer.strike_spent, "A real un-parried collision strike in panel %d removes exactly one shared HP" % (index + 1))
		await ticks(70)
		check(page.health == previous - 1, "One overlapping attack in panel %d cannot drain health on subsequent frames" % (index + 1))
		actor.trainer.enabled = false
		actor.trainer.interrupt()

	await fresh_page()
	var victim: CharacterBody3D = panels[0].arena.player
	var original: CharacterBody3D = panels[0].arena.enemies.get_child(0)
	await prepare_strike(original, victim)
	await wait_for_damage(6)
	original.trainer.enabled = false
	var extra: CharacterBody3D = load("res://scenes/melee_grunt.tscn").instantiate()
	panels[0].arena.enemies.add_child(extra)
	await prepare_strike(extra, victim)
	await wait_for_damage(5)
	check(page.health == 4 and victim.damage_flash_left > 0.0, "A second enemy's distinct hit damages during the first hit's feedback flash")
	extra.trainer.enabled = false

	await fresh_page()
	original = panels[0].arena.enemies.get_child(0)
	victim = panels[0].arena.player
	await prepare_strike(original, victim)
	# Move outside its committed box while it winds up.
	victim.position.x -= 5.0
	await ticks(15)
	check(page.health == 6, "A dodged strike does not reduce health")
	await fresh_page()
	original = panels[0].arena.enemies.get_child(0)
	victim = panels[0].arena.player
	await prepare_strike(original, victim)
	victim.parry.window_left = 0.12
	victim.facing_direction = 1
	await ticks(10)
	check(victim.parry.successes == 1 and page.health == 6, "A correctly parried collision strike does not reduce health")

	await fresh_page()
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1) and is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Equal wave progress uses baseline 10% inactive speed")
	await clear_current_wave(0)
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1) and is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Clearing one wave does not speed up trailing panels")
	check(panels[1].header.text.contains("10%"), "Panel header shows its fixed inactive speed")
	await ticks(65)
	for actor in panels[0].arena.enemies.get_children():
		actor.trainer.enabled = false
	await clear_current_wave(0)
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1) and is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Two cleared waves leave inactive speed unchanged")
	page.select_panel(1)
	check(panels[1].arena.simulation_rate == 1.0 and is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Switching activates only the selected panel without changing other inactive rates")
	await clear_current_wave(1)
	check(is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Catching up leaves other inactive rates unchanged")
	page.select_panel(0)
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1), "Catching up does not modify inactive speed")
	await ticks(65)
	for actor in panels[0].arena.enemies.get_children():
		actor.trainer.enabled = false
	await clear_current_wave(0)
	check(is_equal_approx(panels[2].arena.simulation_rate, 0.1), "Clearing all waves leaves unfinished panels at fixed inactive speed")
	page.select_panel(2)
	check(is_equal_approx(panels[1].arena.simulation_rate, 0.1), "Inactive rate stays fixed regardless of which panel leads")
	check(is_equal_approx(Engine.time_scale, 1.0), "Role flow remains local and leaves global time unchanged")
	await key(KEY_R)
	await ticks(80)
	page = current_scene
	panels = page.panels
	check(page.health == 6 and is_equal_approx(panels[1].arena.simulation_rate, 0.1), "Restart resets shared health and restores fixed inactive flow")
	print("HIT / WAVE-INDEPENDENT FLOW COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
