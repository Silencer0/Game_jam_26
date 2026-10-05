extends PanelContainer
## One arena, one camera, one independently simulated World3D.

const ROLE_ICONS: Dictionary = {&"Past": "«", &"Present": "●", &"Future": "»"}
const ROLE_COLORS: Dictionary = {&"Past": Color(1.0, 0.72, 0.22), &"Present": Color(0.25, 0.9, 0.45), &"Future": Color(0.85, 0.4, 1.0)}

@export var arena_id: StringName = &"A"
@export var controlled: bool = false

var damage_indicator_left: float = 0.0
var danger: bool = false
var pulse_time: float = 0.0
var impact_left: float = 0.0
var impact: ColorRect
var impact_material: ShaderMaterial
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
	impact = ColorRect.new()
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_material = ShaderMaterial.new()
	impact_material.shader = preload("res://shaders/damage_impact.gdshader")
	impact.material = impact_material
	impact.visible = false
	impact.z_index = 10
	add_child(impact)
	arena.player.damage_taken.connect(on_damage_taken)
	arena.restart_enabled = false
	arena.get_node("HUD").visible = false
	arena.set_process(false) # This panel owns the readout; gameplay still ticks.
	arena.get_node("Camera3D").mouse_enabled = false # The page routes mouse motion.

func set_controlled(value: bool, inactive_rate: float) -> void:
	controlled = value
	arena.player.set_input_enabled(controlled)
	set_simulation_rate(1.0 if controlled else inactive_rate)
	arena.get_node("Camera3D").size = 10.5 if controlled else 5.8
	arena.get_node("Camera3D").threat_focus = not controlled
	var panel_number: int = {&"A": 1, &"B": 2, &"C": 3}[arena_id]
	switch_hint.text = str(panel_number)
	switch_hint.visible = not controlled

	update_frame()

func set_simulation_rate(rate: float) -> void:
	arena.set_simulation_rate(rate)
	refresh_header()

func refresh_header() -> void:
	var panel_number: int = {&"A": 1, &"B": 2, &"C": 3}[arena_id]
	header.text = "%02d  /  %s" % [panel_number, "LIVE" if controlled else "WATCH"]
	role_icon.text = ROLE_ICONS[arena.temporal_role]
	role_icon.tooltip_text = String(arena.temporal_role)
	role_icon.modulate = ROLE_COLORS[arena.temporal_role] if controlled else Color(0.72, 0.75, 0.8)
	update_frame()

func on_damage_taken() -> void:
	impact_left = 0.12
	damage_indicator_left = 1.6 # Feedback uses real time, even in slow panels.
	pulse_time = 0.0
	update_frame()

func damage_indicator_needed() -> bool:
	return not controlled and damage_indicator_left > 0.0

func update_frame() -> void:
	danger = damage_indicator_needed()
	danger_tint.visible = danger
	frame.border_color = Color(1.0, 0.18, 0.14) if danger else (ROLE_COLORS[arena.temporal_role] if controlled else Color(0.07, 0.075, 0.10))
	frame.shadow_color = Color(1.0, 0.08, 0.04, 0.75) if danger else Color(0.02, 0.025, 0.035, 0.8)
	frame.shadow_size = 10 if danger else (4 if controlled else 0)
	frame.set_border_width_all(8 if danger else (6 if controlled else 5))
	queue_redraw()

func _draw() -> void:
	# Ink corner accents read as a printed manga frame rather than a window.
	var ink := Color(0.035, 0.04, 0.06)
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]:
		var inward := Vector2(1 if corner.x == 0 else -1, 1 if corner.y == 0 else -1)
		draw_line(corner + inward * 2.0, corner + Vector2(inward.x * 30.0, inward.y * 2.0), ink, 3.0)
		draw_line(corner + inward * 2.0, corner + Vector2(inward.x * 2.0, inward.y * 24.0), ink, 3.0)
	# An inset red stroke reinforces the frame at small panel sizes.
	if danger:
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(1, 0.12, 0.08), false, 6.0)

func _process(delta: float) -> void:
	impact_left = maxf(0.0, impact_left - delta)
	impact.visible = impact_left > 0.0
	impact_material.set_shader_parameter("strength", minf(1.0, impact_left / 0.04))
	impact_material.set_shader_parameter("phase", 1.0 - impact_left / 0.12)
	damage_indicator_left = maxf(0.0, damage_indicator_left - delta)
	status.text = "WAVE %02d  /  %d THREATS" % [arena.wave, arena.enemies_alive] if arena.result == &"fighting" else arena.status_text(false)
	if controlled and arena.result == &"fighting":
		status.tooltip_text = arena.get_node("LightBeams").status_text()
	if danger != damage_indicator_needed():
		update_frame()
	if danger:
		pulse_time += delta
		danger_tint.color = Color(1.0, 0.05, 0.02, 0.13 + 0.03 * sin(pulse_time * 6.0))
