extends "res://tests/player_stage6_test.gd"

var gunner: CharacterBody3D
var gunner_arena: Node3D

func fresh_gunner(index: int = 0) -> void:
	await fresh_page()
	page.select_panel(index)
	gunner_arena = panels[index].arena
	for actor in gunner_arena.enemies.get_children():
		actor.position.x = 26
	gunner = load("res://scenes/ranged_enemy.tscn").instantiate()
	gunner.position = Vector3(14, 0.8, 0)
	gunner.simulation_rate = gunner_arena.simulation_rate
	gunner_arena.enemies.add_child(gunner)
	gunner_arena.enemies_alive += 1
	gunner.defeated.connect(gunner_arena.on_enemy_defeated)
	gunner.trainer.enabled = false
	gunner_arena.player.position = Vector3(6, 0.8, 0)
	await ticks(20)

func shot(offset: float = 1.2) -> Node3D:
	var bolt := Node3D.new()
	bolt.set_script(load("res://scripts/enemy_projectile.gd"))
	bolt.arena = gunner_arena
	bolt.direction = -1 if offset > 0 else 1
	bolt.position = gunner_arena.player.position + Vector3(offset, 0.08, 0)
	gunner_arena.get_node("EnemyProjectiles").add_child(bolt)
	return bolt

func run_checks() -> void:
	await fresh_gunner()
	gunner.trainer.enabled = true
	gunner.trainer.rest_left = 0.0
	await ticks(2)
	check(gunner.trainer.windup_left > 0.75 and gunner.trainer.shots_fired == 0 and gunner.trainer.strike_visual.visible, "Gunner telegraphs before shooting")
	var locked: int = gunner.trainer.strike_direction
	gunner_arena.player.position.x = 20
	await ticks(55)
	check(gunner.trainer.shots_fired == 1 and locked == -1 and gunner.trainer.strike_direction == locked, "Gunner fires once in the committed direction even after the player crosses behind")
	check(gunner.trainer.rest_left > 1.6, "A shot starts a generous reload cooldown")

	await fresh_gunner()
	gunner.trainer.enabled = true
	gunner_arena.player.position.x = 12
	var start: float = gunner.position.x
	await ticks(8)
	check(gunner.position.x > start, "Gunner retreats when the player approaches")
	gunner.position.x = 24
	gunner_arena.player.position.x = 6
	start = gunner.position.x
	await ticks(8)
	check(gunner.position.x < start, "Gunner approaches when outside firing range")

	await fresh_gunner()
	var bolt: Node3D = shot()
	bolt._physics_process(0.25)
	check(page.health == 5 and bolt.is_queued_for_deletion(), "Unparried projectile contact removes exactly one shared HP and consumes the shot")
	await ticks(2)
	bolt = shot()
	bolt._physics_process(0.25)
	check(page.health == 4, "A separate shot damages during damage feedback flashing")

	await fresh_gunner()
	var player: CharacterBody3D = gunner_arena.player
	player.facing_direction = 1
	player.parry.window_left = 0.12
	bolt = shot()
	bolt._physics_process(0.25)
	check(page.health == 6 and player.parry.successes == 1 and bolt.reflected and bolt.direction == 1, "Timed facing parry reflects a shot and prevents damage")
	await ticks(140)
	check(gunner.health == 4 and not is_instance_valid(bolt), "Reflected shot returns toward the gunner, deals two damage once, and disappears")

	await fresh_gunner()
	player = gunner_arena.player
	player.facing_direction = -1
	player.parry.window_left = 0.12
	bolt = shot()
	bolt._physics_process(0.25)
	check(page.health == 5 and player.parry.successes == 0, "Wrong-facing parry takes projectile damage")

	await fresh_gunner()
	bolt = shot(2.0)
	player = gunner_arena.player
	player.position.y = 4
	await ticks(10)
	check(page.health == 6, "Jumping above a committed horizontal projectile dodges it")

	await fresh_gunner()
	gunner.trainer.enabled = true
	gunner.trainer.rest_left = 0.0
	await ticks(2)
	gunner.receive_melee_hit(2, 1, &"launcher")
	await ticks(30)
	check(gunner.health == 4 and gunner.trainer.shots_fired == 0 and gunner.trainer.windup_left == 0.0 and not gunner.is_on_floor(), "Launcher interrupts firing and suspends the gunner")
	gunner.receive_melee_hit(2, 1, &"air_finisher")
	await ticks(50)
	check(gunner.health == 2 and gunner.is_on_floor() and not gunner.slamming, "Gunner supports the existing aerial finisher and landing recovery")

	await fresh_gunner()
	gunner.trainer.enabled = true
	gunner.trainer.rest_left = 0.0
	await ticks(2)
	gunner.on_parried()
	await ticks(10)
	check(gunner.trainer.stagger_left > 0.8 and gunner.trainer.shots_fired == 0, "Existing enemy parry interruption staggers gunner and cancels firing")

	await fresh_gunner()
	bolt = shot(3.0)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 3, 2)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = gunner_arena.player.position + Vector3(1.5, 0, 0)
	gunner_arena.add_child(wall)
	await ticks(2)
	await ticks(40)
	check(page.health == 6 and not is_instance_valid(bolt), "Wall blocks hostile projectile before player damage")

	await fresh_gunner(1)
	gunner.trainer.enabled = true
	gunner.trainer.windup_left = 0.85
	page.select_panel(0)
	bolt = shot(4.0)
	var x: float = bolt.position.x
	await ticks(6)
	check(absf(bolt.position.x - x + 0.04) < 0.01 and absf(gunner.trainer.windup_left - 0.84) < 0.01, "Inactive projectile movement and firing windup both use fixed 10% time")
	page.set_paused(true)
	x = bolt.position.x
	var windup: float = gunner.trainer.windup_left
	await ticks(20)
	check(bolt.position.x == x and gunner.trainer.windup_left == windup, "Pause freezes gunner and projectile simulation")
	page.set_paused(false)
	page.select_panel(1)
	x = bolt.position.x
	await ticks(6)
	check(absf(bolt.position.x - x + 0.4) < 0.03, "Selecting arena immediately resumes native projectile motion")

	await fresh_page()
	for actor in panels[0].arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(panels[0].arena.wave == 2 and panels[0].arena.enemies_alive == 2 and panels[0].arena.enemies.get_child(0).get_script() == load("res://scripts/melee_grunt.gd") and panels[0].arena.enemies.get_child(1).get_script() == load("res://scripts/melee_grunt.gd"), "Wave 2 has exactly two regular enemies")
	for actor in panels[0].arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(panels[0].arena.wave == 3 and panels[0].arena.enemies_alive == 1 and panels[0].arena.enemies.get_child(0).get_script() == load("res://scripts/ranged_enemy.gd"), "Wave 3 contains only one shooter")

	for actor in panels[0].arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(panels[0].arena.wave == 4 and panels[0].arena.enemies_alive == 2 and panels[0].arena.enemies.get_child(0).get_script() == load("res://scripts/melee_grunt.gd") and panels[0].arena.enemies.get_child(1).get_script() == load("res://scripts/ranged_enemy.gd"), "Wave 4 has one regular enemy and one shooter")
	for actor in panels[0].arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(panels[0].arena.result == &"victory" and panels[0].arena.defeated_count == 6, "Clearing the fourth wave ends the six-enemy encounter")

	await fresh_gunner(1)
	var info: Node3D = panels[0].arena.get_node("TemporalInformation")
	info.refresh()
	var found: bool = false
	for mirage in info.displayed:
		found = found or mirage.enemy_id == gunner.get_instance_id()
	check(found, "Gunner appears as an exact next-role shootable mirage")
	page.select_panel(0)
	gunner.position.x = 8
	panels[0].arena.player.position.x = 6
	panels[1].arena.enemies.get_child(0).position.x = 20
	await ticks(2)
	panels[0].arena.get_node("LightBeams").fire()
	await ticks(15)
	check(gunner.health == 4, "Visible light beam hitting gunner mirage damages its real body")

	await fresh_gunner()
	for i in range(12):
		gunner.trainer.shoot()
	check(gunner_arena.get_node("EnemyProjectiles").get_child_count() == 8, "Hostile projectile population is bounded per arena")
	gunner_arena.player.receive_damage(100)
	await ticks(2)
	check(gunner_arena.get_node("EnemyProjectiles").get_child_count() == 0, "Defeat removes all hostile projectiles")
	await key(KEY_R)
	await ticks(80)
	page = current_scene
	panels = page.panels
	check(page.health == 6 and panels[0].arena.wave == 1 and panels[0].arena.get_node("EnemyProjectiles").get_child_count() == 0, "Restart restores the original first wave and clean projectile state")
	check(is_equal_approx(Engine.time_scale, 1.0), "Ranged combat never changes global time scale")
	await fresh_gunner()
	gunner.trainer.enabled = true
	gunner.trainer.rest_left = 0.0
	await ticks(180)
	check(gunner.trainer.shots_fired == 1 and page.health == 5, "Real gunner windup, emission, flight, and player collision cost exactly one HP")
	await fresh_gunner(1)
	page.select_panel(0)
	bolt = shot()
	check(not panels[1].danger, "Hostile projectile before contact gives no red damage indicator")
	for tick in range(180):
		if page.health < 6:
			break
		await ticks(1)
	check(page.health == 5 and panels[1].danger and not panels[0].danger and not panels[2].danger, "Inactive projectile hit reduces shared health and flashes only the damaged panel")
	await fresh_gunner()
	gunner_arena.player.facing_direction = 1
	await tap("parry")
	await ticks(10)
	bolt = shot()
	bolt._physics_process(0.25)
	check(bolt.reflected and page.health == 6, "The wider parry catches a bullet more than 120 ms after the actual input")
	print("RANGED ENEMY CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
