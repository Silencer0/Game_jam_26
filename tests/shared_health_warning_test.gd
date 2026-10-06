extends "res://tests/causal_test_base.gd"
## Shared HP plus confirmed-damage-only red indicators.

func run_checks() -> void:
	await fresh()
	populate()
	check(page.health == 6 and page.hud.health_value == 6 and page.hud.session == page and page.find_children("*", "ProgressBar", true, false).is_empty(), "Active panel owns one shared drawn health ribbon without detached progress bars")
	var individual_hp: bool = false
	for panel in page.panels:
		individual_hp = individual_hp or panel.status.text.contains("HP:")
	check(not individual_hp, "Panel readouts contain no separate player health counters")
	page.panels[1].arena.player.receive_damage(1)
	await ticks(1)
	check(page.health == 5 and page.hud.health_value == 5 and page.panels[0].arena.player.health == 5 and page.panels[2].arena.player.health == 5, "Damage updates one shared pool and all views")
	check(page.panels[1].danger and not page.panels[0].danger and not page.panels[2].danger, "Only the panel that actually lost health flashes red")
	check(page.panels[1].switch_hint.visible and page.panels[1].switch_hint.text == "2", "Red flash preserves the centered numeric switch marker")
	page.panels[1].arena.player.receive_damage(1)
	check(page.health == 4, "Each distinct damage event still removes one HP")
	check(page.panels[1].damage_indicator_left > 1.5 and page.panels[1].frame.border_width_left == 8 and page.panels[1].impact_left > 0.0, "Repeated damage refreshes a thick border and impact frame")
	page.select_panel(1)
	check(not page.panels[1].danger and page.health == 4, "Selecting the struck panel hides red without restoring health")
	page.select_panel(0)
	await ticks(110)
	check(not page.panels[1].danger and page.panels[1].frame.shadow_size == 0, "Confirmed-damage glow expires in real time despite inactive slowdown")

	await fresh()
	populate()
	var actor: CharacterBody3D = page.panels[1].arena.enemies.get_child(0)
	var victim: CharacterBody3D = page.panels[1].arena.player
	await prepare_strike(actor, victim)
	await ticks(2)
	check(actor.trainer.windup_left > 0.0 and not page.panels[1].danger, "Enemy windup never triggers red before damage")
	await wait_for_damage(6)
	check(page.health == 5 and page.panels[1].danger and page.panels[1].danger_tint.visible, "A real un-parried collision hit triggers red after HP decreases")
	check(page.panels[1].frame.border_color.r > 0.9 and page.panels[1].frame.shadow_size > 0, "Confirmed damage produces a red border and glow")
	actor.trainer.enabled = false
	await ticks(110)
	check(not page.panels[1].danger, "Real hit flash clears without requiring another panel visit")

	await fresh()
	populate()
	actor = page.panels[1].arena.enemies.get_child(0)
	victim = page.panels[1].arena.player
	await prepare_strike(actor, victim)
	victim.position.x -= 5.0
	await ticks(90)
	check(page.health == 6 and not page.panels[1].danger and page.panels[1].damage_indicator_left == 0.0, "A missed strike never triggers a damage indicator")

	await fresh()
	populate()
	actor = page.panels[0].arena.enemies.get_child(0)
	victim = page.panels[0].arena.player
	await prepare_strike(actor, victim)
	victim.facing_direction = 1
	victim.parry.window_left = 0.12
	await ticks(10)
	check(victim.parry.successes == 1 and page.health == 6 and page.panels[0].damage_indicator_left == 0.0, "Parried contact never triggers a damage indicator")

	await fresh()
	populate()
	page.panels[2].arena.player.receive_damage(100)
	await ticks(1)
	check(page.health == 0 and page.hud.health_value == 0 and page.panels[0].arena.player.dead and page.panels[1].arena.player.dead and page.panels[2].arena.player.dead, "Shared health depletion ends every arena")
	check(page.panels[2].danger and not page.panels[1].danger, "Lethal damage flashes only its source panel")
	check(not page.panels[2].arena.player.receive_damage(1), "Duplicate damage after defeat is rejected")
	key(KEY_R, true)
	await ticks(1)
	key(KEY_R, false)
	await ticks(80)
	page = current_scene
	check(page.health == 6 and not page.panels[0].danger and not page.panels[1].danger and not page.panels[2].danger, "Restart restores shared health and clears every damage indicator")
	print("SHARED HEALTH / DAMAGE INDICATORS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)

func prepare_strike(actor: CharacterBody3D, victim: CharacterBody3D) -> void:
	actor.position = Vector3(7.5, 0.8, 0)
	victim.position = Vector3(6, 0.8, 0)
	actor.velocity = Vector3.ZERO
	await ticks(90) # Settle the new copy at inactive local speed before arming a strike.
	actor.trainer.enabled = true
	actor.trainer.rest_left = 0.0
	actor.trainer.windup_left = 0.02
	actor.trainer.strike_direction = -1

func wait_for_damage(old_health: int) -> void:
	for _i in range(200):
		if page.health < old_health:
			return
		await ticks(1)
