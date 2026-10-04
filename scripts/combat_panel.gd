extends PanelContainer
## One arena, one camera, one independently simulated World3D.

const ROLE_ICONS: Dictionary = {&"Past": "«", &"Present": "●", &"Future": "»"}
const ROLE_COLORS: Dictionary = {&"Past": Color(1.0, 0.72, 0.22), &"Present": Color(0.25, 0.9, 0.45), &"Future": Color(0.85, 0.4, 1.0)}

@export var arena_id: StringName = &"A"
@export var controlled: bool = false

var damage_indicator_left: float = 0.0
var danger: bool = false
var pulse_time: float = 0.0
var frame: StyleBoxFlat

@onready var danger_tint: ColorRect = $DangerTint
@onready var viewport: SubViewport = $Margin/Column/World/Viewport
@onready var arena: Node3D = $Margin/Column/World/Viewport/Arena
@onready var header: Label = $Margin/Column/HeaderRow/Header
@onready var role_icon: Label = $Margin/Column/HeaderRow/RoleIcon
@onready var switch_hint: Label = $SwitchHint
@onready var status: Label = $Margin/Column/Status

func _ready() -> void:
	frame = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", frame)
	arena.player.damage_taken.connect(on_damage_taken)
	arena.restart_enabled = false
	arena.get_node("HUD").visible = false
	arena.set_process(false) # This panel owns the readout; gameplay still ticks.
	arena.get_node("Camera3D").mouse_enabled = false # The page routes mouse motion.

func set_controlled(value: bool, inactive_rate: float) -> void:
	controlled = value
	arena.player.set_input_enabled(controlled)
	set_simulation_rate(1.0 if controlled else inactive_rate)
	arena.get_node("Camera3D").size = 14.4 if controlled else 10.0
	var panel_number: int = {&"A": 1, &"B": 2, &"C": 3}[arena_id]
	switch_hint.text = str(panel_number)
	switch_hint.visible = not controlled

	update_frame()

func set_simulation_rate(rate: float) -> void:
	arena.set_simulation_rate(rate)
	refresh_header()

func refresh_header() -> void:
	var panel_number: int = {&"A": 1, &"B": 2, &"C": 3}[arena_id]
	header.text = "%d • %s %d%%" % [panel_number, "ACTIVE" if controlled else "SLOW", roundi(arena.simulation_rate * 100.0)]
	role_icon.text = ROLE_ICONS[arena.temporal_role]
	role_icon.tooltip_text = String(arena.temporal_role)
	role_icon.modulate = ROLE_COLORS[arena.temporal_role] if controlled else Color(0.72, 0.75, 0.8)
	update_frame()

func on_damage_taken() -> void:
	damage_indicator_left = 0.7 # Feedback uses real time, even in slow panels.
	pulse_time = 0.0
	update_frame()

func damage_indicator_needed() -> bool:
	return not controlled and damage_indicator_left > 0.0

func update_frame() -> void:
	danger = damage_indicator_needed()
	danger_tint.visible = danger
	frame.border_color = Color(1.0, 0.18, 0.14) if danger else (ROLE_COLORS[arena.temporal_role] if controlled else Color(0.42, 0.48, 0.58))
	frame.shadow_color = Color(1.0, 0.08, 0.04, 0.75) if danger else Color(0, 0, 0, 0)
	frame.shadow_size = 10 if danger else 0
	frame.set_border_width_all(6 if controlled else 3)

func _process(delta: float) -> void:
	damage_indicator_left = maxf(0.0, damage_indicator_left - delta)
	status.text = arena.status_text(false)
	if controlled and arena.result == &"fighting":
		status.text += "\n" + arena.get_node("LightBeams").status_text()
	if danger != damage_indicator_needed():
		update_frame()
	if danger:
		pulse_time += delta
		danger_tint.color = Color(1.0, 0.05, 0.02, 0.08 + 0.04 * sin(pulse_time * 6.0))
