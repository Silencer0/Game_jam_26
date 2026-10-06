extends Control
## Causal combat session and animated manga page; presentation never changes local clocks.

const ROLE_NAMES: Array[StringName] = [&"Past", &"Present", &"Future"]
var native_flow_rates: Dictionary = {&"Past": 0.85, &"Present": 1.0, &"Future": 1.15}

@export_range(0.01, 1.0) var inactive_simulation_rate: float = 0.10
@export var max_health: int = 6
@export var tutorial_mode: bool = false
var tutorial: Control
var health: int = 6
var gaps: Array[float] = [6.0, 6.0]
var dilation: Node
var ledger: Node
var addition: int = 1
var multiplier: float = 1.0
const MAX_MULT: float = 4.0
const SHIFT_COST_PER_ROLE := 5
var regular_kills: int = 0
var contradiction_kills: int = 0

var result: StringName = &"fighting"
var active_index: int = 0
var mouse_position: Vector2 = Vector2.ZERO

@onready var causality_board: Control = $PauseOverlay/Center/Card/Margin/Menu/Links/Board
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_slots: Array[Button] = [$PauseOverlay/Center/Card/Margin/Menu/Roles/Past, $PauseOverlay/Center/Card/Margin/Menu/Roles/Present, $PauseOverlay/Center/Card/Margin/Menu/Roles/Future]
var pause_buttons: Array[Button] = []
@onready var hud: Control = $Margin/Page/Panels/CombatHUD
var page_tween: Tween
var page_laid_out: bool = false
var pause_page: StringName = &"timeline"
@onready var panel_layout: Control = $Margin/Page/Panels
@onready var panels: Array[Node] = [$Margin/Page/Panels/PanelA, $Margin/Page/Panels/PanelB, $Margin/Page/Panels/PanelC]

func _ready() -> void:
	causality_board.session = self
	hud.session = self
	for slot in pause_slots:
		slot.get_node("Number").add_theme_font_override("font", ThemeDB.fallback_font)
	pause_buttons.resize(3)
	for slot in pause_slots:
		slot.session = self
		slot.pressed.connect(func(): select_panel(slot.panel_index))
	$PauseOverlay/Center/Card/Margin/Menu/Resume.pressed.connect(set_paused.bind(false))
	$PauseOverlay/Center/Card/Margin/Menu/Restart.pressed.connect(restart_session)
	$PauseOverlay/Center/Card/Margin/Menu/Tutorial.pressed.connect(start_tutorial)
	health = max_health
	for index in range(panels.size()):
		panels[index].arena.temporal_role = ROLE_NAMES[index]
	for panel in panels:
		panel.arena.player.health_owner = self
		panel.arena.player.max_health = max_health
		panel.arena.player.health = health
	ledger = preload("res://scripts/causal_timeline.gd").new()
	add_child(ledger)
	for index in range(panels.size()):
		panels[index].arena.causal_ledger = ledger
		panels[index].arena.panel_index = index
	ledger.copy_died.connect(on_causal_death)
	ledger.setup(self, not tutorial_mode)
	dilation = preload("res://scripts/time_dilation.gd").new()
	dilation.session = self
	add_child(dilation)
	dilation.converged.connect(finish_singularity)
	var menu: Control = $PauseOverlay/Center/Card/Margin/Menu
	menu.get_node("Tabs/Timeline").pressed.connect(set_pause_page.bind(&"timeline"))
	menu.get_node("Tabs/Controls").pressed.connect(set_pause_page.bind(&"controls"))
	mouse_position = get_viewport().get_visible_rect().size * 0.5
	panel_layout.resized.connect(layout_panels)
	apply_panel_state()
	Music.begin_run(panels[active_index].arena.temporal_role)
	update_timeline_readout()
	layout_panels.call_deferred()
	if tutorial_mode:
		tutorial = preload("res://scripts/guided_tutorial.gd").new()
		tutorial.session = self
		panel_layout.add_child(tutorial)
		tutorial.begin.call_deferred()

func apply_shared_damage(damage: int) -> void:
	health = maxi(0, health - damage)
	if tutorial_mode:
		health = maxi(1, health)
	for panel in panels:
		panel.arena.player.health = health
	if health == 0:
		result = &"defeat"
		Sfx.play_cue(&"defeat")
		dilation.reset(true)
		for panel in panels:
			panel.arena.player.finish_defeat()

func _physics_process(delta: float) -> void:
	if not get_tree().paused and result == &"fighting":
		update_simulation_rates()
		dilation.handle_input(delta)
		ledger.advance(delta)

func update_simulation_rates() -> void:
	for index in range(panels.size()):
		var rate: float = float(native_flow_rates[panels[index].arena.temporal_role]) if index == active_index else inactive_simulation_rate
		var environment_rate: float = rate * dilation.ENVIRONMENT_FLOW if dilation != null and dilation.remaining_for(index) > 0.0 else rate
		if not is_equal_approx(panels[index].arena.simulation_rate, environment_rate) or not is_equal_approx(panels[index].arena.player.simulation_rate, rate):
			panels[index].set_simulation_rate(environment_rate, rate)

func update_timeline_readout() -> void:
	refresh_pause_menu()

func select_panel(index: int) -> void:
	if result != &"fighting" or index < 0 or index >= panels.size() or index == active_index:
		return
	dilation.stop(Input.is_action_pressed("dilate"))
	panels[active_index].arena.player.set_input_enabled(false)
	panels[active_index].arena.get_node("Camera3D").mouse_tilt_target = Vector2.ZERO
	active_index = index
	Music.set_role(panels[active_index].arena.temporal_role)
	Sfx.play_cue(&"panel_switch")
	apply_panel_state()
	panels[active_index].arena.get_node("Camera3D").set_mouse_position(mouse_position, get_viewport().get_visible_rect().size)
	layout_panels()
	refresh_pause_menu()

func apply_panel_state() -> void:
	for index in range(panels.size()):
		panels[index].set_controlled(index == active_index, inactive_simulation_rate)
	update_simulation_rates()

func layout_panels() -> void:
	var available: Vector2 = panel_layout.size
	if available.x < 10 or available.y < 10:
		return
	if page_tween != null and page_tween.is_valid():
		page_tween.kill()
	page_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	page_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var duration := 0.34 if page_laid_out and result == &"fighting" else 0.0
	var gap := 20.0
	var upper_height: float = floorf(available.y * 0.65)
	var lower_y: float = upper_height + gap
	var lower_height: float = available.y - lower_y
	var small_order: Array[int] = []
	for role in ROLE_NAMES:
		for index in range(panels.size()):
			if index != active_index and panels[index].arena.temporal_role == role:
				small_order.append(index)
	for index in range(panels.size()):
		var panel: Control = panels[index]
		var at := Vector2.ZERO
		var extent := Vector2(available.x, upper_height)
		var mask := Vector4(0, 1, 0, 1)
		if result == &"singularity":
			extent = available
		elif index != active_index:
			var side: int = small_order.find(index)
			if side == 0:
				at = Vector2(0, lower_y)
				extent = Vector2(available.x * 0.59 - gap * 0.5, lower_height)
				mask = Vector4(0, 1, 0, (available.x * 0.45 - gap * 0.5) / extent.x)
			else:
				at = Vector2(available.x * 0.45 + gap * 0.5, lower_y)
				extent = Vector2(available.x - at.x, lower_height)
				mask = Vector4((available.x * 0.59 + gap * 0.5 - at.x) / extent.x, 1, 0, 1)
		if duration <= 0:
			panel.position = at
			panel.size = extent
			panel.set_edges(mask)
			panel.resize_viewport()
		else:
			page_tween.tween_property(panel, "position", at, duration)
			page_tween.tween_property(panel, "size", extent, duration)
			page_tween.tween_method(panel.set_edges, panel.edges, mask, duration)
		panel.z_index = 2 if index == active_index else 0
	if duration > 0:
		page_tween.chain().tween_callback(func():
			for panel in panels:
				panel.resize_viewport())
	else:
		page_tween.kill()
	page_laid_out = true

func frame_shift_cost(panel_index: int, target_role: StringName) -> int:
	if panel_index < 0 or panel_index >= panels.size() or target_role not in ROLE_NAMES:
		return 0
	return absi(ROLE_NAMES.find(panels[panel_index].arena.temporal_role) - ROLE_NAMES.find(target_role)) * SHIFT_COST_PER_ROLE

func can_shift_frame(panel_index: int, target_role: StringName) -> bool:
	return result == &"fighting" and get_tree().paused and panel_index >= 0 and panel_index < panels.size() and target_role in ROLE_NAMES and addition >= frame_shift_cost(panel_index, target_role)

func animate_role_exchange(first: int, second: int) -> void:
	# Both existing frames glide into their destination before the new preview settles.
	for pair in [[first, second], [second, first]]:
		var source: TextureRect = pause_buttons[pair[0]].get_node("Preview")
		var destination: TextureRect = pause_buttons[pair[1]].get_node("Preview")
		var flying := TextureRect.new()
		flying.texture = source.texture
		flying.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flying.stretch_mode = source.stretch_mode
		flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flying.z_index = 3
		pause_overlay.add_child(flying)
		flying.global_position = source.global_position
		flying.size = source.size
		var motion := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		motion.tween_property(flying, "global_position", destination.global_position, 0.34)
		motion.tween_property(flying, "size", destination.size, 0.34)
		motion.tween_property(flying, "modulate:a", 0.0, 0.12).set_delay(0.26)
		motion.chain().tween_callback(flying.queue_free)

func assign_panel_role(panel_index: int, target_role: StringName) -> void:
	if result != &"fighting" or not get_tree().paused or panel_index < 0 or panel_index >= panels.size() or target_role not in ROLE_NAMES:
		return
	var old_role: StringName = panels[panel_index].arena.temporal_role
	if old_role == target_role:
		return
	if not can_shift_frame(panel_index, target_role):
		Sfx.play_cue(&"ui_error")
		return
	addition -= frame_shift_cost(panel_index, target_role)
	Sfx.play_cue(&"frame_shift")
	var swapped: Array[int] = [panel_index]
	for index in range(panels.size()):
		var panel: Node = panels[index]
		if panel.arena.temporal_role == target_role:
			animate_role_exchange(panel_index, index)
			panel.arena.temporal_role = old_role
			swapped.append(index)
			break
	panels[panel_index].arena.temporal_role = target_role
	Music.set_role(panels[active_index].arena.temporal_role)
	ledger.reconcile_swapped(swapped)
	update_simulation_rates()
	for panel in panels:
		panel.refresh_header()
	update_timeline_readout()
	layout_panels()

func refresh_pause_menu() -> void:
	causality_board.refresh()
	for slot in pause_slots:
		for index in range(panels.size()):
			if panels[index].arena.temporal_role == slot.role:
				slot.panel_index = index
				pause_buttons[index] = slot
				slot.set_preview(panels[index].viewport.get_texture())
				slot.get_node("Number").text = "%d%s" % [index + 1, "  [LIVE]" if index == active_index else ""]
				slot.modulate = Color.WHITE if index == active_index else Color(0.75, 0.78, 0.85)
				slot.tooltip_text = "Frame shift: 5 ADD per role crossed (10 ADD Past / Future). Available: %d ADD." % addition

func set_paused(value: bool) -> void:
	Sfx.play_cue(&"pause_open" if value else &"pause_close")
	if value:
		dilation.stop(true)
	get_tree().paused = value
	pause_overlay.visible = value
	if value:
		set_pause_page(&"timeline")
		refresh_pause_menu()
		var card: Control = $PauseOverlay/Center/Card
		card.modulate.a = 0.0
		create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(card, "modulate:a", 1.0, 0.15)
		$PauseOverlay/Center/Card/Margin/Menu/Resume.grab_focus()
	else:
		# Taps made in the menu must not become combat input on resume.
		panels[active_index].arena.player.set_input_enabled(true)

func set_pause_page(which: StringName) -> void:
	pause_page = which
	var menu: Control = $PauseOverlay/Center/Card/Margin/Menu
	for name in ["Hint", "Roles", "LinksHint", "Links"]:
		menu.get_node(name).visible = which == &"timeline" and result != &"singularity"
	menu.get_node("ControlsPage").visible = which == &"controls"
	menu.get_node("Fullscreen").visible = which == &"controls"
	menu.get_node("Title").text = "FIELD MANUAL" if which == &"controls" else ("SINGULARITY ACHIEVED" if result == &"singularity" else "TIMELINE EDITOR")
	menu.get_node("Tabs/Timeline").modulate = Color(1, 0.83, 0.4) if which == &"timeline" else Color.WHITE
	menu.get_node("Tabs/Controls").modulate = Color(1, 0.83, 0.4) if which == &"controls" else Color.WHITE

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func restart_session() -> void:
	Sfx.play_cue(&"restart")
	get_tree().paused = false
	get_tree().reload_current_scene()

func start_tutorial() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	# Browser fullscreen must be requested directly inside a genuine input event.
	if get_tree().paused and pause_page == &"controls":
		var fullscreen_button: Button = $PauseOverlay/Center/Card/Margin/Menu/Fullscreen
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and fullscreen_button.get_global_rect().has_point(event.position)) or (event.is_action_pressed("ui_accept") and fullscreen_button.has_focus()):
			toggle_fullscreen()
	if event.is_action_pressed("pause_menu") and not event.is_echo():
		if get_tree().paused and pause_page == &"controls":
			set_pause_page(&"timeline")
		else:
			set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if not get_tree().paused:
			panels[active_index].arena.get_node("Camera3D").set_mouse_position(mouse_position, get_viewport().get_visible_rect().size)
	if event.is_echo():
		return
	if get_tree().paused and pause_page == &"controls":
		return
	for index in range(3):
		if event.is_action_pressed([&"switch_a", &"switch_b", &"switch_c"][index]):
			select_panel(index)
			get_viewport().set_input_as_handled()
			return
	if not get_tree().paused and event.is_action_pressed("switch_next"):
		select_panel((active_index + 1) % panels.size())
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		get_viewport().set_input_as_handled()
		restart_session()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_node_ready():
			dilation.stop(true)
			mouse_position = get_viewport().get_visible_rect().size * 0.5
			for panel in panels:
				panel.arena.get_node("Camera3D").mouse_tilt_target = Vector2.ZERO

func on_causal_death(id: int, index: int, cause: StringName) -> void:
	var old_add := addition
	var old_mult := multiplier
	if cause == &"combat":
		addition += 1
		regular_kills += 1
	elif cause == &"contradiction":
		multiplier = minf(MAX_MULT, multiplier + 1.0)
		contradiction_kills += 1
	if floori(float(addition) / SHIFT_COST_PER_ROLE) > floori(float(old_add) / SHIFT_COST_PER_ROLE):
		Sfx.play_cue(&"add_ready")
	if multiplier >= MAX_MULT and old_mult < MAX_MULT:
		Sfx.play_cue(&"mult_ready")
	if cause in [&"combat", &"contradiction"] and ledger.records.has(id):
		var at: Vector3 = ledger.records[id].states[index].position + Vector3(0, 0.8, 0)
		var source: Vector2 = panels[index].world_to_page(at)
		if get_tree().paused:
			source = pause_slots[ledger.rank_of(index)].get_node("Preview").get_global_rect().get_center() - panel_layout.global_position
		hud.launch_score(cause, source)

func scaled_damage(base_damage: int) -> int:
	return maxi(1, roundi(float(base_damage * addition) * maxf(1.0, multiplier)))

func finish_singularity() -> void:
	if result != &"fighting" or gaps[0] > 0.0 or gaps[1] > 0.0:
		return
	Sfx.play_cue(&"victory")
	var final_index: int = ledger.panel_for_rank(1)
	var final_arena: Node3D = panels[final_index].arena
	var player_position: Vector3 = panels[active_index].arena.player.position
	var survivors: Array[Dictionary] = []
	for id: int in ledger.records:
		var record: Dictionary = ledger.records[id]
		var dead_record := false
		var chosen: CharacterBody3D = null
		for rank in [1, 0, 2]:
			var index: int = ledger.panel_for_rank(rank)
			dead_record = dead_record or ledger.state_for(id, index) == &"dead"
			if chosen == null and ledger.state_for(id, index) == &"alive":
				chosen = ledger.actor_for(id, index)
		if not dead_record and is_instance_valid(chosen):
			survivors.append({"id": id, "species": record.species, "position": chosen.position, "health": chosen.health, "difficulty": record.difficulty})
	# Consolidation is terminal: no extra rewards and no resurrected identities.
	result = &"singularity"
	ledger.spawning_enabled = false
	dilation.reset(true)
	for panel in panels:
		for enemy in panel.arena.enemies.get_children():
			enemy.queue_free()
		panel.arena.enemies_alive = 0
		for shot in panel.arena.get_node("EnemyProjectiles").get_children():
			shot.queue_free()
		panel.arena.player.set_input_enabled(false)
		panel.arena.player.combat_enabled = false
		panel.arena.player.velocity = Vector3.ZERO
		panel.arena.result = &"victory"
		panel.visible = false
		panel.arena.process_mode = Node.PROCESS_MODE_DISABLED
	for survivor in survivors:
		var enemy: CharacterBody3D = final_arena.add_enemy(survivor.id, survivor.species, survivor.position, survivor.difficulty)
		enemy.health = survivor.health
		enemy.trainer.enabled = false
		enemy.velocity = Vector3.ZERO
	active_index = final_index
	Music.set_role(final_arena.temporal_role)
	final_arena.player.position = player_position
	final_arena.player.dash_time_left = 0.0
	final_arena.player.damage_flash_left = 0.0
	final_arena.player.get_node("Body").visible = true
	panels[final_index].visible = true
	panels[final_index].controlled = true
	panels[final_index].switch_hint.visible = false
	final_arena.get_node("Camera3D").threat_focus = false
	final_arena.get_node("Camera3D").size = 10.5
	final_arena.get_node("Camera3D").zoom_target = 10.5
	final_arena.get_node("Camera3D").update_follow()
	panels[final_index].refresh_header()
	final_arena.get_node("ComicSet").fit_skyline()
	layout_panels()
