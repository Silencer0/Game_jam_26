extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var id: int = populate()
	var arena: Node3D = page.panels[0].arena
	var enemy: CharacterBody3D = page.ledger.actor_for(id, 0)
	var player: CharacterBody3D = arena.player
	player.position = Vector3(6, 0.8, 0)
	enemy.position = Vector3(25, 0.8, 0)
	await ticks(30)
	enemy.trainer.enabled = true
	page.multiplier = page.MAX_MULT
	page.dilation.begin()
	page.dilation.step(page.dilation.HOLD_SECONDS)
	var player_x: float = player.position.x
	var enemy_x: float = enemy.position.x
	player.parry.cooldown_left = 1.0
	var shot := Node3D.new()
	shot.set_script(load("res://scripts/enemy_projectile.gd"))
	shot.arena = arena
	shot.direction = 1
	shot.position = Vector3(12, 2, 0)
	arena.get_node("EnemyProjectiles").add_child(shot)
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	check(absf(player.position.x - player_x - player.move_speed * 0.85 * 0.5) < 0.16, "Actual player movement keeps native Past speed during dilation")
	check(absf(enemy.position.x - enemy_x + enemy.approach_speed * 0.255 * 0.5) < 0.06, "Actual enemy pursuit uses slowed environmental flow")
	check(absf(shot.position.x - 12.0 - 4.0 * 0.255 * 0.5) < 0.04, "Actual enemy projectile movement uses slowed environmental flow")
	check(absf(player.parry.cooldown_left - (1.0 - 0.85 * 0.5)) < 0.04, "Player parry cooldown keeps the player's undilated clock")
	page.dilation.stop()
	page.dilation.step(page.dilation.remaining_for(0))
	check(is_equal_approx(enemy.simulation_rate, 0.85) and is_equal_approx(player.simulation_rate, 0.85), "Purchased duration expiry restores every existing enemy and player clock")

	await fresh()
	page.select_panel(2)
	page.multiplier = page.MAX_MULT
	page.dilation.begin()
	page.dilation.step(page.dilation.HOLD_SECONDS)
	var identity: int = page.ledger.records.keys()[0]
	page.ledger.actor_for(identity, 2).receive_melee_hit(100, 1)
	page.ledger.advance(12.0)
	page.ledger.actor_for(identity, 0).receive_melee_hit(100, 1)
	page.ledger.spawning_enabled = true
	page.ledger.advance(0.0)
	var spawn_before: float = page.ledger.spawn_left
	page.ledger.spawning_enabled = true
	page.ledger.advance(0.1)
	check(absf(spawn_before - page.ledger.spawn_left - 0.1) < 0.001, "Gap-based intermission remains real-time during Future dilation")
	page.ledger.spawning_enabled = false
	identity = page.ledger.spawn_identity()
	page.gaps[1] = 0.1
	page.ledger.advance(0.1)
	page.ledger.advance(0.0)
	check(page.ledger.state_for(identity, 1) == &"alive", "Shrinking a gap brings an already travelling copy forward immediately")
	finish("DILATION CLOCKS")
