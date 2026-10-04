extends PanelContainer
## One arena, one camera, one independently simulated World3D.

@export var arena_id: StringName = &"A"
@export var controlled: bool = false

var damage_indicator_left: float = 0.0
var danger: bool = false
var pulse_time: float = 0.0
var frame: StyleBoxFlat

@onready var danger_tint: ColorRect = $DangerTint
@onready var viewport: SubViewport = $Margin/Column/World/Viewport
@onready var arena: Node3D = $Margin/Column/World/Viewport/Arena
@onready var header: Label = $Margin/Column/Header
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
	header.text = "%d — %s • %s %d%%" % [panel_number, String(arena.temporal_role).to_upper(), "ACTIVE" if controlled else "SLOW", roundi(arena.simulation_rate * 100.0)]

func on_damage_taken() -> void:
	damage_indicator_left = 0.7 # Feedback uses real time, even in slow panels.
	pulse_time = 0.0
	update_frame()

func damage_indicator_needed() -> bool:
	return not controlled and damage_indicator_left > 0.0

func update_frame() -> void:
	danger = damage_indicator_needed()
	danger_tint.visible = danger
	frame.border_color = Color(1.0, 0.18, 0.14) if danger else (Color(0.15, 0.85, 0.95) if controlled else Color(0.42, 0.48, 0.58))
	frame.shadow_color = Color(1.0, 0.08, 0.04, 0.75) if danger else Color(0, 0, 0, 0)
	frame.shadow_size = 10 if danger else 0

func _process(delta: float) -> void:
	damage_indicator_left = maxf(0.0, damage_indicator_left - delta)
	status.text = arena.status_text(false)
	if danger != damage_indicator_needed():
		update_frame()
	if danger:
		pulse_time += delta
		danger_tint.color = Color(1.0, 0.05, 0.02, 0.08 + 0.04 * sin(pulse_time * 6.0))
