extends SceneTree
## Checks actual imported frame regions, local clocks, and mirrored sprite assets.

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func ticks(count: int) -> void:
	for _index in range(count):
		await physics_frame
		await process_frame

func run_checks() -> void:
	var controller: Script = load("res://scripts/comic_actor.gd")
	var visible_frames := 0
	for name: String in controller.SHEETS:
		var texture: Texture2D = controller.SHEETS[name]
		var image: Image = texture.get_image()
		if image.is_compressed():
			image.decompress()
		var rows: int = controller.ROWS[name]
		check(image.get_size() == Vector2i(512, rows * 128), "%s atlas has exact frame boundaries" % name)
		for row in range(rows):
			for column in range(4):
				var frame := image.get_region(Rect2i(column * 128, row * 128, 128, 128))
				if frame.get_used_rect().has_area():
					visible_frames += 1
	check(visible_frames == 104, "All 104 imported animation cells contain transparent character art")
	var page: Control = load("res://main.tscn").instantiate()
	root.add_child(page)
	for panel in page.panels:
		for enemy in panel.arena.enemies.get_children():
			enemy.trainer.enabled = false
	await ticks(30)
	var player: CharacterBody3D = page.panels[0].arena.player
	var visual: Node3D = player.get_node("Body")
	player.velocity = Vector3.ZERO
	visual._process(0.0)
	var before: float = visual.animation_time
	player.simulation_rate = 0.1
	visual._process(0.1)
	check(is_equal_approx(visual.animation_time - before, 0.01), "Sprite animation follows local inactive speed")
	player.hit_stopped = true
	before = visual.animation_time
	visual._process(0.1)
	check(is_equal_approx(visual.animation_time, before), "Hit-stop freezes the sprite frame clock")
	player.hit_stopped = false
	var attack_frames: Array[int] = []
	for index in range(3):
		player.melee.start_attack(index, &"ground_light")
		visual._process(0.0)
		attack_frames.append(visual.sprite.frame)
	check(attack_frames == [0, 4, 8], "All three ground combo hits select different combat poses")
	player.melee.start_attack(0, &"launcher")
	visual._process(0.0)
	check(visual.sprite.frame == 16, "Launcher selects its upward-slash row")
	player.melee.start_attack(0, &"air_finisher")
	visual._process(0.0)
	check(visual.sprite.frame == 20, "Finisher selects its separate diagonal-slam row")
	player.melee.cancel_attack()
	var info: Node3D = page.panels[0].arena.get_node("TemporalInformation")
	info.refresh()
	var target: CharacterBody3D = page.panels[1].arena.enemies.get_child(0)
	var ghost: Sprite3D = info.cues[0].get_node("Mirage")
	check(ghost.texture == target.visual.sprite.texture and ghost.frame == target.visual.sprite.frame and ghost.flip_h == target.visual.sprite.flip_h, "Mirage displays the real enemy's art, current pose and facing")
	print("EMBER SPRITE CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
