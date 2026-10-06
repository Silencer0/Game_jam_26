extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var id: int = populate()
	var arena: Node3D = page.panels[0].arena
	var player: CharacterBody3D = arena.player
	var enemy: CharacterBody3D = page.ledger.actor_for(id, 0)
	player.position = Vector3(6, 0.8, 0)
	enemy.position = Vector3(7.4, 0.8, 0)
	enemy.health = 50
	page.addition = 2
	page.multiplier = 3.0
	await ticks(35)
	player.melee.start_attack(0)
	await ticks(12)
	check(enemy.health == 44 and enemy.hit_count == 1, "Actual melee collision applies ADD × MULT exactly once per swing")
	player.melee.cancel_attack()
	await ticks(10)
	player.melee.start_attack(0, &"launcher")
	await ticks(16)
	check(enemy.health == 32 and enemy.velocity.x > 0.0, "Scaled launcher damage retains upward/away launch behavior")

	await fresh()
	id = populate()
	arena = page.panels[0].arena
	player = arena.player
	enemy = page.ledger.actor_for(id, 0)
	page.addition = 2
	page.multiplier = 2.0
	enemy.health = 40
	enemy.position = Vector3(9, 0.8, 0)
	await ticks(35)
	var shot := Node3D.new()
	shot.set_script(load("res://scripts/enemy_projectile.gd"))
	shot.arena = arena
	shot.reflected = true
	shot.direction = 1
	shot.position = Vector3(7, enemy.position.y, 0)
	arena.get_node("EnemyProjectiles").add_child(shot)
	await ticks(50)
	check(enemy.health == 32 and enemy.hit_count == 1, "Actual reflected bullet uses scaled player damage and hits once")
	check(page.health == page.max_health, "Reflected bullet cannot damage the shared player pool")
	player.receive_damage(1)
	check(page.health == 5 and page.panels[1].arena.player.health == 5, "Shared health still updates all arenas")
	finish("CAUSAL DAMAGE")
