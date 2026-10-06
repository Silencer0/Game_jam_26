extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var id: int = populate()
	var actor: CharacterBody3D = page.ledger.actor_for(id, 0)
	var feedback: Node3D = page.panels[0].arena.get_node("ComicFeedback")
	actor.health = 500
	actor.max_health = 500
	actor.receive_melee_hit(48, 1)
	check(feedback.damage_history == [48] and feedback.numbers[0].label.text == "48" and feedback.numbers[0].label.visible, "A real hit displays its exact final damage amount")
	actor.receive_melee_hit(96, 1, &"reflected_shot")
	check(feedback.damage_history == [48, 96] and feedback.numbers[1].label.text == "96", "Reflected damage has its own exact number even in the same frame")
	check(feedback.numbers[0].label.modulate != feedback.numbers[1].label.modulate, "Reflected hits use distinct violet feedback")
	actor.receive_melee_hit(1000, 1)
	check(feedback.numbers[2].label.text == "1000" and actor.dead, "Overkill shows the full attack amount instead of silently clipping it to remaining HP")
	actor.receive_melee_hit(2000, 1)
	check(feedback.damage_history.size() == 3, "Dead enemies cannot produce duplicate damage numbers")
	check(page.panels[1].arena.get_node("ComicFeedback").damage_history.is_empty(), "Automatic causal deaths do not invent player-hit damage numbers")
	await ticks(50)
	var visible := 0
	for number in feedback.numbers:
		visible += 1 if number.label.visible else 0
	check(visible == 0, "Numbers expire in real time and do not stick in inactive arenas")

	await fresh()
	id = populate()
	actor = page.ledger.actor_for(id, 0)
	feedback = page.panels[0].arena.get_node("ComicFeedback")
	var fighter: CharacterBody3D = page.panels[0].arena.player
	fighter.position = Vector3(6, 0.8, 0)
	actor.position = Vector3(7.4, 0.8, 0)
	actor.health = 1000
	actor.max_health = 1000
	page.addition = 12
	page.multiplier = 4
	await ticks(60)
	key(KEY_J, true)
	await ticks(1)
	key(KEY_J, false)
	await ticks(10)
	check(feedback.damage_history == [48] and actor.health == 952, "Actual melee input sends the same ADD/MULT damage to enemy HP and the visible number")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/qa/manga-damage.png")
	actor.health = 100000
	for i in range(80):
		actor.receive_melee_hit(i + 1, 1)
	check(feedback.numbers.size() == feedback.NUMBER_LIMIT and feedback.damage_history.size() == 64, "Repeated hits reuse a fixed label pool and bounded diagnostic history")
	page.select_panel(2)
	await ticks(50)
	visible = 0
	for number in feedback.numbers:
		visible += 1 if number.label.visible else 0
	check(visible == 0, "Switching away cannot leave persistent damage labels at inactive speed")
	finish("DAMAGE NUMBERS")
