extends Control
## A separate, safe training issue using the real combat and causal mechanics.
const STEPS := [
	["FIND YOUR FEET", "A / D or arrow keys: run and turn. Your attacks and parries face the direction you last moved.", 20.0, "Run both ways; cover eight metres."],
	["TAKE TO THE AIR", "SPACE jumps. Press again in the air for a double jump. Release early for a shorter hop; landing restores the extra jump.", 25.0, "Perform a ground jump and a double jump."],
	["BREAK THE DISTANCE", "SHIFT dashes in your facing direction. Dash on the ground, then jump and dash in the air. Only one air dash is available before landing.", 25.0, "Perform one ground dash and one air dash."],
	["THREE BEATS OF STEEL", "Left click chains three light attacks, followed by a short recovery. Jump or dash cancels an attack. Start on this passive target.", 30.0, "Chain light attacks with left click, cancel with movement, and defeat a target."],
	["LAUNCH. CHASE. SLAM.", "Q on the ground launches a target up and away. Chase with jump / dash; left click in the air keeps the juggle going. Q in the air sends it diagonally into the deck.", 25.0, "Hit a target with both a launcher and an air finisher."],
	["TURN THE STRIKE", "Face the enemy and right click just before contact. A successful parry flashes, staggers the enemy and restores your offensive initiative.", 25.0, "Parry a melee strike with right click. The training shield prevents defeat."],
	["RETURN TO SENDER", "This shooter fires slow practice rounds. Face the incoming bullet and right click. The reflected bullet hits enemies instead of you.", 25.0, "Reflect a bullet with right click and let it hit the shooter."],
	["THREE FRAMES. ONE LIFE.", "1 / 2 / 3 selects an arena; Tab cycles. Past runs at 85%, Present 100%, Future 115%. Inactive arenas run at 10%. Amber arrows mark hidden enemies; red borders mean a hit. Health is shared.", 25.0, "Visit Past, Present and Future. Listen to each soundtrack."],
	["BANK YOUR ADD", "Training bank reset: start at one ADD. Direct kills add one. Each row has five segments: five ADD buys one role step, ten buys two. Damage = base x ADD x MULT; waves become tougher.", 30.0, "Defeat four targets and fill the first five-ADD bank."],
	["EDIT THE CAUSE", "Enemies are born in Future, then trickle to Present and Past after gap / 10 seconds. Kill this one in Future: earlier copies survive. ESC pauses; drag its dead Future frame onto Present for five ADD. The contradiction kills a later copy and earns MULT. Earlier deaths erase later copies without extra rewards.", 30.0, "Kill in Future, then make a paid role swap that earns MULT."],
	["CLOSE THE FIRST GAP", "Hold E in Past for about 1.5 seconds to spend one MULT charge: five seconds of 30% environment flow and one second closer to Present. Your movement keeps its native speed; releasing E keeps the purchased slowdown. Training refills empty MULT: release E, then hold again.", 25.0, "Close the Past / Present gap. Watch the top-centre dots."],
	["ONE TIMELINE", "Switch to Future and hold E. Each MULT charge buys five seconds of slowdown and closes one second of the remaining gap. Training refills empty MULT; release E and hold again. Smaller gaps shorten enemy trickle and the next-wave delay. Close both gaps to reach singularity; R restarts.", 15.0, "Close the Future / Present gap and reach singularity."]
]
var session: Control
var lesson := -1
var lesson_time := 0.0
var elapsed := 0.0
var complete := false
var card: PanelContainer
var heading: Label
var body: Label
var task: Label
var progress: ProgressBar
var next_button: Button
var before_cues: Dictionary = {}
var kills := 0
var contradictions := 0
var hit_kinds: Dictionary = {}
var visited: Dictionary = {}
var faced: Dictionary = {}
var distance := 0.0
var last_x := 0.0
var last_panel := -1
var ground_dash := false
var air_dash := false
var spawn_cooldown := 0.0
var recharge_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 0)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.98, 0.96, 0.86, 0.96)
	paper.border_color = Color(0.025, 0.025, 0.04)
	paper.set_border_width_all(4)
	paper.shadow_color = Color(0.015, 0.02, 0.035, 0.6)
	paper.shadow_size = 6
	paper.content_margin_left = 18
	paper.content_margin_right = 18
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)
	heading = make_label(column, 24)
	heading.add_theme_font_override("font", preload("res://assets/kenney/fonts/KenneyFutureNarrow.ttf"))
	body = make_label(column, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 720
	task = make_label(column, 18)
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 5
	progress.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.64, 0.12)
	progress.add_theme_stylebox_override("fill", fill)
	column.add_child(progress)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	next_button = Button.new()
	next_button.text = "NEXT LESSON"
	# Space is jump: tutorial buttons must not retain keyboard focus after a click.
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(next_lesson)
	buttons.add_child(next_button)
	var exit_button := Button.new()
	exit_button.text = "SKIP TUTORIAL / PLAY"
	exit_button.focus_mode = Control.FOCUS_NONE
	exit_button.pressed.connect(leave_training)
	buttons.add_child(exit_button)
	session.ledger.copy_died.connect(on_death)

func make_label(parent: Control, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.035, 0.035, 0.05))
	parent.add_child(label)
	return label

func begin() -> void:
	enter_lesson(0)

func clear_drill() -> void:
	for panel in session.panels:
		for enemy in panel.arena.enemies.get_children():
			enemy.trainer.enabled = false
			enemy.queue_free()
		panel.arena.enemies_alive = 0
		for shot in panel.arena.get_node("EnemyProjectiles").get_children():
			shot.queue_free()
		panel.arena.player.position = Vector3(12, 0.8, 0)
		panel.arena.player.velocity = Vector3.ZERO
	session.ledger.records.clear()
	session.ledger.wave_ids.clear()
	session.ledger.wave_queue.clear()
	session.ledger.wave_cleared = false
	session.ledger.wave = 1
	session.health = session.max_health
	for panel in session.panels:
		panel.arena.player.health = session.health

func enter_lesson(index: int) -> void:
	if index >= STEPS.size():
		finish_training()
		return
	session.dilation.reset(true)
	clear_drill()
	lesson = index
	lesson_time = 0.0
	kills = 0
	contradictions = 0
	hit_kinds.clear()
	visited.clear()
	faced.clear()
	distance = 0.0
	ground_dash = false
	air_dash = false
	spawn_cooldown = 1.0
	recharge_time = 0.0
	before_cues = Sfx.played_counts.duplicate()
	if lesson == 9:
		# The ADD lesson earns the actual cost; skip gets clearly labelled practice funds.
		if session.addition < 5:
			session.addition = 5
		session.select_panel(session.ledger.panel_for_rank(2))
	elif lesson == 11:
		# Skipping the first ultimate drill still leaves only the second gap to teach.
		session.gaps[0] = 0.0
		session.gaps[1] = 6.0
		session.multiplier = session.MAX_MULT
		session.select_panel(session.ledger.panel_for_rank(2))
	else:
		session.select_panel(session.ledger.panel_for_rank(0))
	if lesson == 8:
		session.addition = 1
	if lesson == 10:
		session.gaps.assign([6.0, 6.0])
		session.multiplier = session.MAX_MULT
	if lesson in [10, 11]:
		Sfx.play_cue(&"mult_ready")
	last_panel = session.active_index
	last_x = session.panels[last_panel].arena.player.position.x
	heading.text = "TRAINING %02d / 12  //  %s" % [lesson + 1, STEPS[lesson][0]]
	body.text = STEPS[lesson][1]
	if lesson == 9 and session.addition == 5:
		body.text += " Practice funds available: 5 ADD."
	if lesson >= 3:
		spawn_target()
	session.refresh_pause_menu()

func spawn_target() -> void:
	var role_index: int = session.ledger.panel_for_rank(2)
	var player: CharacterBody3D = session.panels[role_index].arena.player
	# Gentle, immutable practice profile; normal exponential waves stay untouched.
	var profile := {"wave": 1, "starting_add": session.addition,
		"max_health": maxi(3, session.scaled_damage(1) * 3),
		"movement": 0.55, "windup": 1.5, "recovery": 1.6, "projectile": 0.55}
	var id: int = session.ledger.spawn_identity(&"gunner" if lesson == 6 else &"grunt", profile)
	if id < 0:
		return
	# Position all copies close enough for the current drill, without overlapping the hero.
	session.ledger.records[id].origin = Vector3(clampf(player.position.x + 3.7, 2.0, 30.0), 0.8, 0)
	var enemy: CharacterBody3D = session.ledger.actor_for(id, role_index)
	enemy.position = session.ledger.records[id].origin
	connect_target(enemy)
	if lesson == 7:
		# One extra identity introduces side threats without flooding the page.
		if session.ledger.pending_count() < 2:
			spawn_cooldown = 6.0

func connect_target(enemy: CharacterBody3D) -> void:
	if not enemy.has_meta("tutorial_target"):
		enemy.set_meta("tutorial_target", true)
		enemy.damage_received.connect(func(_amount: int, kind: StringName): hit_kinds[kind] = true)
	enemy.trainer.enabled = lesson in [5, 6, 7] and enemy.get_parent().get_parent().panel_index == session.active_index

func on_death(_id: int, _panel_index: int, cause: StringName) -> void:
	if cause == &"combat":
		kills += 1
	elif cause == &"contradiction":
		contradictions += 1

func cue_count(cue: StringName) -> int:
	return int(Sfx.played_counts.get(cue, 0)) - int(before_cues.get(cue, 0))

func objective_met() -> bool:
	match lesson:
		0: return distance >= 8.0 and faced.size() == 2
		1: return cue_count(&"jump") > 0 and cue_count(&"double_jump") > 0
		2: return ground_dash and air_dash
		3: return kills > 0 and cue_count(&"swing_alt") > 0 and (cue_count(&"dash") > 0 or cue_count(&"jump") > 0)
		4: return hit_kinds.has(&"launcher") and hit_kinds.has(&"air_finisher")
		5: return cue_count(&"parry_success") > 0
		6: return hit_kinds.has(&"reflected_shot")
		7: return visited.size() == 3
		8: return session.addition >= 5 and kills >= 4
		9: return contradictions > 0
		10: return session.gaps[0] <= 0.0
		11: return session.result == &"singularity"
	return false

func _process(delta: float) -> void:
	if session == null or lesson < 0:
		return
	var active_panel: Control = session.panels[session.active_index]
	var scale_factor: float = clampf(session.panel_layout.size.x / 1872.0, 0.65, 1.0)
	card.scale = Vector2.ONE * scale_factor
	card.position = active_panel.position + Vector2((active_panel.size.x - 760 * scale_factor) * 0.5, 92 * scale_factor)
	visible = not get_tree().paused
	if get_tree().paused or complete:
		return
	lesson_time += delta
	elapsed += delta
	if lesson in [10, 11] and session.result == &"fighting" and session.multiplier <= 1.00001:
		recharge_time += delta
		if recharge_time >= 1.0:
			session.multiplier = session.MAX_MULT
			recharge_time = 0.0
			Sfx.play_cue(&"mult_ready")
	else:
		recharge_time = 0.0
	var fighter: CharacterBody3D = active_panel.arena.player
	if last_panel == session.active_index:
		distance += absf(fighter.position.x - last_x)
	last_x = fighter.position.x
	last_panel = session.active_index
	faced[fighter.facing_direction] = true
	visited[active_panel.arena.temporal_role] = true
	if fighter.dash_time_left > 0:
		if fighter.is_on_floor():
			ground_dash = true
		else:
			air_dash = true
	for panel in session.panels:
		for enemy in panel.arena.enemies.get_children():
			if not enemy.dead and not enemy.is_queued_for_deletion():
				connect_target(enemy)
	spawn_cooldown = maxf(0.0, spawn_cooldown - delta)
	if lesson in [3, 4, 5, 6, 8] and session.ledger.pending_count() == 0 and spawn_cooldown <= 0.0:
		spawn_target()
		spawn_cooldown = 4.0
	elif lesson == 7 and session.ledger.pending_count() < 2 and spawn_cooldown <= 0.0:
		spawn_target()
		spawn_cooldown = 8.0
	var done := objective_met()
	var duration: float = STEPS[lesson][2]
	progress.value = minf(100.0, lesson_time / duration * 100.0)
	task.text = ("CHECK / " if done else "TRY / ") + STEPS[lesson][3]
	if done:
		task.text += "  Click NEXT LESSON when ready."
	elif lesson_time >= duration:
		task.text += "  Keep practising, or click NEXT LESSON."

func finish_training() -> void:
	complete = true
	heading.text = "TRAINING COMPLETE // YOUR NEXT ISSUE"
	body.text = "You know movement, combat, parries, causal frame shifts and singularity. Enter the main issue for full waves and exponential enemy growth. Training protection and practice charges end there."
	task.text = "PLAY MAIN ISSUE to begin. ESC opens controls; R restarts."
	progress.value = 100
	next_button.text = "PLAY MAIN ISSUE"
	Sfx.play_cue(&"victory")

func next_lesson() -> void:
	if complete:
		leave_training()
	else:
		enter_lesson(lesson + 1)

func leave_training() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
