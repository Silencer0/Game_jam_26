extends "res://tests/causal_test_base.gd"
## Recovery limits strikes, not pursuit; switching preserves the local attack clock.

func run_checks() -> void:
	await fresh()
	populate()
	await ticks(100) # Settle freshly arrived copies before measuring pursuit.
	for index in range(3):
		page.select_panel(index)
		var actor: CharacterBody3D = page.panels[index].arena.enemies.get_child(0)
		actor.position.x = 14.0
		page.panels[index].arena.player.position.x = 6.0
		actor.velocity = Vector3.ZERO
		actor.trainer.enabled = true
		actor.trainer.windup_left = 0.0
		actor.trainer.active_left = 0.0
		actor.trainer.rest_left = 1.2
		page.select_panel((index + 1) % 3)
		var start_x: float = actor.position.x
		await ticks(12)
		check(actor.position.x < start_x - 0.05, "Panel %d pursues immediately after switching away during attack recovery" % (index + 1))
		check(actor.trainer.rest_left > 1.1 and actor.trainer.windup_left == 0.0, "Panel %d retains slowed attack cooldown while pursuing" % (index + 1))
		page.select_panel(index)
		start_x = actor.position.x
		await ticks(6)
		check(actor.position.x < start_x - 0.2, "Panel %d resumes native pursuit immediately when selected during recovery" % (index + 1))
		actor.trainer.enabled = false
		actor.trainer.rest_left = 100.0
	await fresh()
	populate()
	await ticks(100) # Settle freshly arrived copies before measuring pursuit.
	var actor: CharacterBody3D = page.panels[0].arena.enemies.get_child(0)
	actor.position.x = 14.0
	actor.trainer.enabled = true
	actor.trainer.rest_left = 0.0
	actor.trainer.windup_left = 0.5
	var start_x: float = actor.position.x
	await ticks(6)
	check(is_equal_approx(actor.position.x, start_x), "Windup still commits the enemy in place")
	actor.trainer.windup_left = 0.0
	actor.trainer.stagger_left = 0.5
	await ticks(6)
	check(is_equal_approx(actor.position.x, start_x), "Parry stagger still prevents pursuit")
	actor.trainer.stagger_left = 0.0
	actor.hitstun_left = 0.2
	await ticks(6)
	check(is_equal_approx(actor.position.x, start_x), "Hit stun still prevents pursuit")
	await fresh()
	populate()
	await ticks(100) # Settle freshly arrived copies before measuring pursuit.
	actor = page.panels[1].arena.enemies.get_child(0)
	actor.position = page.panels[1].arena.player.position + Vector3(1.5, 0.0, 0.0)
	actor.velocity = Vector3.ZERO
	actor.trainer.enabled = true
	actor.trainer.rest_left = 1.2
	var saved_health: int = page.health
	await ticks(60)
	check(actor.trainer.rest_left > 1.0 and actor.trainer.windup_left == 0.0 and page.health == saved_health, "Inactive enemy in range cannot bypass recovery or attack early")
	page.select_panel(1)
	await ticks(85)
	check(actor.trainer.windup_left > 0.0 or actor.trainer.active_left > 0.0 or page.health < saved_health, "Recovered enemy in range restarts its attack loop without getting stuck")
	print("ENEMY SWITCH MOVEMENT COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
