extends SceneTree
## Exercise the actual Stage 4 scene, enemy physics, collision strikes, and loop.

var arena: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var trainer: Node3D
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func fresh_arena() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "light_attack", "heavy_attack", "parry", "restart"]:
		Input.action_release(action)
	if is_instance_valid(arena):
		arena.queue_free()
		await ticks(2)
	arena = load("res://scenes/combat_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	player = arena.get_node("Player")
	await ticks(45)
	enemy = arena.enemies.get_child(0)
	trainer = enemy.get_node("Trainer")

func close_range() -> void:
	trainer.enabled = false
	trainer.interrupt()
	player.position = Vector3(6.5, 0.8, 0.0)
	player.velocity = Vector3.ZERO
	player.facing_direction = 1
	enemy.position = Vector3(8.0, 0.8, 0.0)
	enemy.velocity = Vector3.ZERO
	await ticks(20)

func tap(action: String) -> void:
	Input.action_press(action)
	await ticks(1)
	Input.action_release(action)

func wait_for_hit(count: int) -> void:
	for i in range(50):
		if enemy.hit_count >= count:
			return
		await ticks(1)

func windup() -> void:
	trainer.enabled = true
	trainer.rest_left = 0.0
	await ticks(1)
	for i in range(50):
		if trainer.windup_left > 0.0 and trainer.windup_left <= 0.06:
			return
		await ticks(1)

func run_checks() -> void:
	await fresh_arena()
	check(arena.wave == 1 and arena.enemies_alive == 1, "Encounter starts with one real grunt")
	var spawn_x: float = enemy.position.x
	var saw_windup: bool = false
	for i in range(220):
		saw_windup = saw_windup or trainer.windup_left > 0.0
		if player.health < player.max_health:
			break
		await ticks(1)
	check(enemy.position.x < spawn_x - 2.0, "Grunt approaches the player instead of remaining a training dummy")
	check(saw_windup and player.health == player.max_health - 1, "Telegraphed collision strike deals one point of real damage")
	await ticks(5)
	check(player.health == player.max_health - 1, "One overlapping strike cannot repeatedly damage the player")
	check(player.receive_damage(1) and player.health == player.max_health - 2, "A distinct hit still damages during the feedback flash")
	Input.action_press("move_right")
	var before_move: float = player.position.x
	await ticks(10)
	Input.action_release("move_right")
	check(player.position.x > before_move, "Movement resumes immediately after damage hit-stop")

	await fresh_arena()
	await close_range()
	await windup()
	await tap("parry")
	await ticks(10)
	check(player.parry.successes == 1 and player.health == player.max_health, "Timed facing parry prevents grunt damage")
	check(trainer.stagger_left > 0.7, "Parry staggers the real enemy and creates a counterattack opening")
	await tap("light_attack")
	await wait_for_hit(1)
	check(enemy.health == 5, "Immediate parry counterattack damages enemy health")

	await fresh_arena()
	await close_range()
	await windup()
	player.facing_direction = -1
	await tap("parry")
	await ticks(10)
	check(player.parry.successes == 0 and player.health == 5, "Wrong-facing parry takes real damage")

	await fresh_arena()
	await close_range()
	trainer.enabled = true
	trainer.rest_left = 0.0
	await ticks(2)
	var locked_direction: int = trainer.strike_direction
	player.position.x = 9.5
	await ticks(36)
	check(trainer.strike_direction == locked_direction and player.health == 6, "Telegraphed attack commits its direction and can be crossed safely")

	await fresh_arena()
	await close_range()
	enemy.health = 12
	enemy.max_health = 12
	await tap("heavy_attack")
	await wait_for_hit(1)
	check(enemy.health == 10 and enemy.velocity.x > 0.0 and enemy.velocity.y > 10.0, "Real grunt can be launched upward and away")
	trainer.enabled = true
	await tap("jump")
	Input.action_press("move_right")
	await ticks(18)
	Input.action_release("move_right")
	await tap("light_attack")
	await wait_for_hit(2)
	await tap("light_attack")
	await wait_for_hit(3)
	await tap("heavy_attack")
	await wait_for_hit(4)
	check(enemy.hit_count == 4 and enemy.health == 6 and enemy.velocity.x > 0.0 and enemy.velocity.y < -17.0, "Real enemy supports the full two-light aerial chain and diagonal slam")
	check(trainer.active_left == 0.0, "Launched enemy cannot attack while airborne")
	await ticks(100)
	check(enemy.is_on_floor() and not enemy.slamming and is_zero_approx(enemy.position.z), "Grunt recovers from slam on the 2.5D plane")

	await fresh_arena()
	await close_range()
	enemy.position.y = 3.0
	enemy.health = 2
	var slam_start: Vector3 = enemy.position
	enemy.receive_melee_hit(2, 1, &"air_finisher")
	enemy.apply_hit_stop(0.06)
	check(enemy.dead and not enemy.is_queued_for_deletion(), "Lethal air finisher keeps the defeated body until ground impact")
	await ticks(8)
	check(enemy.position.x > slam_start.x and enemy.position.y < slam_start.y and enemy.get_node("Hurtbox").collision_layer == 0, "Defeated body slams diagonally without retaining a live hurtbox")
	await ticks(25)
	check(not is_instance_valid(enemy) and arena.defeated_count == 1, "Lethal slam removes the body on landing and counts one defeat")

	await fresh_arena()
	await close_range()
	# Finish the first enemy through real input; damage needs three two-point launchers.
	for i in range(3):
		enemy.position = Vector3(8.0, 0.8, 0.0)
		enemy.velocity = Vector3.ZERO
		await ticks(30)
		await tap("heavy_attack")
		await ticks(40)
	check(arena.defeated_count == 1 and arena.enemies_alive == 0, "Real attacks kill and remove an enemy exactly once")
	await ticks(65)
	check(arena.wave == 2 and arena.enemies_alive == 2, "Clearing the first wave starts a two-enemy wave")
	for actor in arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(arena.wave == 3 and arena.enemies_alive == 3, "Second clear starts the final three-enemy wave")
	var count_before: int = arena.defeated_count
	var last_enemy: CharacterBody3D = arena.enemies.get_child(0)
	last_enemy.receive_melee_hit(100, 1)
	last_enemy.receive_melee_hit(100, 1)
	check(arena.defeated_count == count_before + 1, "Repeated contacts on a dying enemy cannot double-count a defeat")
	for actor in arena.enemies.get_children():
		actor.receive_melee_hit(100, 1)
	await ticks(65)
	check(arena.result == &"victory" and arena.defeated_count == 6 and arena.enemies_alive == 0, "Six defeated grunts end the finite encounter in victory")
	await tap("light_attack")
	check(not player.melee.attacking, "Victory stops further combat")
	await ticks(120)
	check(arena.enemies_alive == 0 and arena.result == &"victory", "Victory cannot spawn further waves")

	await fresh_arena()
	player.receive_damage(player.max_health)
	check(player.dead and arena.result == &"defeat", "Zero player health ends the encounter in defeat")
	var death_position: Vector3 = player.position
	await tap("jump")
	await tap("dash")
	await tap("light_attack")
	await ticks(30)
	check(player.position.is_equal_approx(death_position) and not player.melee.attacking and trainer.active_left == 0.0, "Defeat stops player actions and enemy strikes")
	var old_arena_id: int = arena.get_instance_id()
	var restart_event: InputEventKey = InputEventKey.new()
	restart_event.physical_keycode = KEY_R
	restart_event.pressed = true
	Input.parse_input_event(restart_event)
	await ticks(2)
	restart_event = InputEventKey.new()
	restart_event.physical_keycode = KEY_R
	restart_event.pressed = false
	Input.parse_input_event(restart_event)
	await ticks(45)
	arena = current_scene
	player = arena.get_node("Player")
	check(arena.get_instance_id() != old_arena_id and arena.result == &"fighting" and arena.wave == 1 and arena.enemies_alive == 1 and player.health == player.max_health and not player.dead, "R reloads a fresh encounter with full health and clean state")
	check(is_equal_approx(Engine.time_scale, 1.0), "Combat never changes global time scale")
	print("STAGE 4 CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
