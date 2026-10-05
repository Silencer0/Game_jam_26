extends "res://tests/hit_wave_pressure_test.gd"
## Shared HP plus confirmed-damage-only red indicators.

func run_checks() -> void:
	await fresh_page()
	check(page.health == 6 and page.health_bar.value == 6 and page.find_children("*", "ProgressBar", true, false).size() == 1, "Page shows exactly one full shared health bar")
	var individual_hp: bool = false
	for panel in panels:
		individual_hp = individual_hp or panel.status.text.contains("HP:")
	check(not individual_hp, "Panel readouts contain no separate player health counters")
	panels[1].arena.player.receive_damage(1)
	await ticks(1)
	check(page.health == 5 and page.health_bar.value == 5 and panels[0].arena.player.health == 5 and panels[2].arena.player.health == 5, "Damage updates one shared pool and all views")
	check(panels[1].danger and not panels[0].danger and not panels[2].danger, "Only the panel that actually lost health flashes red")
	check(panels[1].switch_hint.visible and panels[1].switch_hint.text == "2", "Red flash preserves the centered numeric switch marker")
	panels[1].arena.player.receive_damage(1)
	check(page.health == 4, "Each distinct damage event still removes one HP")
	check(panels[1].damage_indicator_left > 1.5 and panels[1].frame.border_width_left == 8 and panels[1].impact_left > 0.0, "Repeated damage refreshes a thick border and impact frame")
	page.select_panel(1)
	check(not panels[1].danger and page.health == 4, "Selecting the struck panel hides red without restoring health")
	page.select_panel(0)
	await ticks(110)
	check(not panels[1].danger and panels[1].frame.shadow_size == 0, "Confirmed-damage glow expires in real time despite inactive slowdown")

	await fresh_page()
	var actor: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	var victim: CharacterBody3D = panels[1].arena.player
	await prepare_strike(actor, victim)
	await ticks(2)
	check(actor.trainer.windup_left > 0.0 and not panels[1].danger, "Enemy windup never triggers red before damage")
	await wait_for_damage(6)
	check(page.health == 5 and panels[1].danger and panels[1].danger_tint.visible, "A real un-parried collision hit triggers red after HP decreases")
	check(panels[1].frame.border_color.r > 0.9 and panels[1].frame.shadow_size > 0, "Confirmed damage produces a red border and glow")
	actor.trainer.enabled = false
	await ticks(110)
	check(not panels[1].danger, "Real hit flash clears without requiring another panel visit")

	await fresh_page()
	actor = panels[1].arena.enemies.get_child(0)
	victim = panels[1].arena.player
	await prepare_strike(actor, victim)
	victim.position.x -= 5.0
	await ticks(90)
	check(page.health == 6 and not panels[1].danger and panels[1].damage_indicator_left == 0.0, "A missed strike never triggers a damage indicator")

	await fresh_page()
	actor = panels[0].arena.enemies.get_child(0)
	victim = panels[0].arena.player
	await prepare_strike(actor, victim)
	victim.facing_direction = 1
	victim.parry.window_left = 0.12
	await ticks(10)
	check(victim.parry.successes == 1 and page.health == 6 and panels[0].damage_indicator_left == 0.0, "Parried contact never triggers a damage indicator")

	await fresh_page()
	panels[2].arena.player.receive_damage(100)
	await ticks(1)
	check(page.health == 0 and page.health_bar.value == 0 and panels[0].arena.player.dead and panels[1].arena.player.dead and panels[2].arena.player.dead, "Shared health depletion ends every arena")
	check(panels[2].danger and not panels[1].danger, "Lethal damage flashes only its source panel")
	check(not panels[2].arena.player.receive_damage(1), "Duplicate damage after defeat is rejected")
	await key(KEY_R)
	await ticks(80)
	page = current_scene
	panels = page.panels
	check(page.health == 6 and not panels[0].danger and not panels[1].danger and not panels[2].danger, "Restart restores shared health and clears every damage indicator")
	print("SHARED HEALTH / DAMAGE INDICATORS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
