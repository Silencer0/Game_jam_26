extends Control
## Stage 7: temporal roles multiply local activity speed; twisting preserves state.

const ROLE_NAMES: Array[StringName] = [&"Past", &"Present", &"Future"]
var native_flow_rates: Dictionary = {&"Past": 0.7, &"Present": 1.0, &"Future": 1.3}

@export_range(0.01, 1.0) var inactive_simulation_rate: float = 0.10
@export var max_health: int = 6
var health: int = 6

var active_index: int = 0
var mouse_position: Vector2 = Vector2.ZERO

@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_slots: Array[Button] = [$PauseOverlay/Center/Card/Margin/Menu/Roles/Past, $PauseOverlay/Center/Card/Margin/Menu/Roles/Present, $PauseOverlay/Center/Card/Margin/Menu/Roles/Future]
var pause_buttons: Array[Button] = []
@onready var timeline_readout: Label = $Margin/Page/Timeline
@onready var health_bar: ProgressBar = $Margin/Page/SharedHealth/Bar
@onready var health_label: Label = $Margin/Page/SharedHealth/Readout
@onready var panel_layout: Control = $Margin/Page/Panels
@onready var panels: Array[Node] = [$Margin/Page/Panels/PanelA, $Margin/Page/Panels/PanelB, $Margin/Page/Panels/PanelC]

func _ready() -> void:
	pause_buttons.resize(3)
	for slot in pause_slots:
		slot.session = self
		slot.pressed.connect(func(): select_panel(slot.panel_index))
	$PauseOverlay/Center/Card/Margin/Menu/Resume.pressed.connect(set_paused.bind(false))
	$PauseOverlay/Center/Card/Margin/Menu/Restart.pressed.connect(restart_session)
	health = max_health
	for index in range(panels.size()):
		panels[index].arena.temporal_role = ROLE_NAMES[index]
	for panel in panels:
		panel.arena.player.health_owner = self
		panel.arena.player.max_health = max_health
		panel.arena.player.health = health
	health_bar.max_value = max_health
	mouse_position = get_viewport().get_visible_rect().size * 0.5
	panel_layout.resized.connect(layout_panels)
	apply_panel_state()
	update_timeline_readout()
	layout_panels.call_deferred()

func apply_shared_damage(damage: int) -> void:
	health = maxi(0, health - damage)
	for panel in panels:
		panel.arena.player.health = health
	if health == 0:
		for panel in panels:
			panel.arena.player.finish_defeat()

func _process(_delta: float) -> void:
	health_bar.value = health
	health_label.text = "HEALTH %d / %d%s" % [health, max_health, " — DEFEATED: R to retry" if health == 0 else ""]

func _physics_process(_delta: float) -> void:
	if not get_tree().paused:
		update_simulation_rates()

func update_simulation_rates() -> void:
	for index in range(panels.size()):
		var rate: float = 1.0 if index == active_index else inactive_simulation_rate
		rate *= float(native_flow_rates[panels[index].arena.temporal_role])
		if not is_equal_approx(panels[index].arena.simulation_rate, rate):
			panels[index].set_simulation_rate(rate)

func twist_timeline(reverse: bool = false) -> void:
	if health == 0:
		return
	for panel in panels:
		var role: StringName = panel.arena.temporal_role
		if reverse:
			if role == &"Past":
				panel.arena.temporal_role = &"Future"
			elif role == &"Future":
				panel.arena.temporal_role = &"Past"
		else:
			panel.arena.temporal_role = ROLE_NAMES[(ROLE_NAMES.find(role) + 1) % ROLE_NAMES.size()]
	update_simulation_rates()
	for panel in panels:
		panel.refresh_header()
	update_timeline_readout()
	layout_panels()

func update_timeline_readout() -> void:
	var entries: PackedStringArray = []
	for role in ROLE_NAMES:
		for index in range(panels.size()):
			if panels[index].arena.temporal_role == role:
				entries.append("%s %.1f×: %d" % [String(role).to_upper(), float(native_flow_rates[role]), index + 1])
	timeline_readout.text = "   →   ".join(entries) + "    |    T: rotate roles   •   Y: swap Past/Future"
	refresh_pause_menu()

func select_panel(index: int) -> void:
	if index < 0 or index >= panels.size() or index == active_index:
		return
	panels[active_index].arena.player.set_input_enabled(false)
	panels[active_index].arena.get_node("Camera3D").mouse_tilt_target = Vector2.ZERO
	active_index = index
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
	var gap: float = 12.0
	var large_width: float = floorf((available.x - gap) * 2.0 / 3.0)
	var small_width: float = available.x - large_width - gap
	var small_height: float = floorf((available.y - gap) * 0.5)
	var side_index: int = 0
	var display_order: Array[int] = []
	for role in ROLE_NAMES:
		for index in range(panels.size()):
			if panels[index].arena.temporal_role == role:
				display_order.append(index)
	for index in display_order:
		var panel: Control = panels[index]
		if index == active_index:
			panel.position = Vector2.ZERO
			panel.size = Vector2(large_width, available.y)
		else:
			panel.position = Vector2(large_width + gap, float(side_index) * (small_height + gap))
			panel.size = Vector2(small_width, small_height)
			side_index += 1

func assign_panel_role(panel_index: int, target_role: StringName) -> void:
	if not get_tree().paused or panel_index < 0 or panel_index >= panels.size() or target_role not in ROLE_NAMES:
		return
	var old_role: StringName = panels[panel_index].arena.temporal_role
	if old_role == target_role:
		return
	for panel in panels:
		if panel.arena.temporal_role == target_role:
			panel.arena.temporal_role = old_role
			break
	panels[panel_index].arena.temporal_role = target_role
	update_simulation_rates()
	for panel in panels:
		panel.refresh_header()
	update_timeline_readout()
	layout_panels()

func refresh_pause_menu() -> void:
	for slot in pause_slots:
		for index in range(panels.size()):
			if panels[index].arena.temporal_role == slot.role:
				slot.panel_index = index
				pause_buttons[index] = slot
				slot.get_node("Preview").texture = panels[index].viewport.get_texture()
				slot.get_node("Number").text = "%d%s" % [index + 1, "  ●" if index == active_index else ""]
				slot.modulate = Color.WHITE if index == active_index else Color(0.75, 0.78, 0.85)
				slot.tooltip_text = "Panel %d%s" % [index + 1, " (selected)" if index == active_index else ""]

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_overlay.visible = value
	if value:
		refresh_pause_menu()
		$PauseOverlay/Center/Card/Margin/Menu/Resume.grab_focus()
	else:
		# Taps made in the menu must not become combat input on resume.
		panels[active_index].arena.player.set_input_enabled(true)

func restart_session() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and not event.is_echo():
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if not get_tree().paused:
			panels[active_index].arena.get_node("Camera3D").set_mouse_position(mouse_position, get_viewport().get_visible_rect().size)
	if event.is_echo():
		return
	if event.is_action_pressed("twist_rotate") or event.is_action_pressed("twist_reverse"):
		twist_timeline(event.is_action_pressed("twist_reverse"))
		get_viewport().set_input_as_handled()
		return
	for index in range(3):
		if event.is_action_pressed([&"switch_a", &"switch_b", &"switch_c"][index]):
			select_panel(index)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("switch_next"):
		select_panel((active_index + 1) % panels.size())
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		get_viewport().set_input_as_handled()
		restart_session()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_node_ready():
			mouse_position = get_viewport().get_visible_rect().size * 0.5
			for panel in panels:
				panel.arena.get_node("Camera3D").mouse_tilt_target = Vector2.ZERO
