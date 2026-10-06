extends Camera3D
## Orthographic side view with slight elevation to expose placeholder depth.

@export var base_elevation: float = 5.2
@export var threat_focus: bool = false
@export var mouse_enabled: bool = true
@export var arena_width: float = 48.0
@export var target_path: NodePath = NodePath("../Player")
@export var mouse_yaw_degrees: float = 7.0
@export var mouse_pitch_degrees: float = 4.5
@export var mouse_tilt_response: float = 8.0

var zoom_target: float = -1.0
var mouse_tilt_target: Vector2 = Vector2.ZERO
var mouse_tilt: Vector2 = Vector2.ZERO
@onready var target: Node3D = get_node(target_path)

func _ready() -> void:
	update_follow()

func _input(event: InputEvent) -> void:
	if mouse_enabled and event is InputEventMouseMotion:
		set_mouse_position(event.position, get_viewport().get_visible_rect().size)

func set_mouse_position(pointer: Vector2, viewport_size: Vector2) -> void:
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		var normalized: Vector2 = pointer / viewport_size * 2.0 - Vector2.ONE
		mouse_tilt_target = normalized.clamp(-Vector2.ONE, Vector2.ONE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_tilt_target = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Frame-rate independent easing; no pointer capture or gameplay-plane rotation.
	if zoom_target > 0.0:
		size = lerpf(size, zoom_target, 1.0 - exp(-10.0 * delta))
	mouse_tilt = mouse_tilt.lerp(mouse_tilt_target, 1.0 - exp(-mouse_tilt_response * delta))
	update_follow()

func update_follow() -> void:
	# Orthographic size is viewport height; adjust limits for browser aspect ratio.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_width: float = size * viewport_size.x / maxf(1.0, viewport_size.y) * 0.5
	var margin: float = minf(half_width, arena_width * 0.5)
	var focus: Vector3 = Vector3(
		clampf(target.position.x, margin, arena_width - margin),
		clampf(target.position.y + 2.3, 3.6, 6.5),
		0.0
	)
	if threat_focus:
		focus = Vector3(target.position.x, maxf(1.7, target.position.y + 0.65), 0.0)
	var offset: Vector3 = Vector3(0.0, base_elevation, 20.0)
	offset = offset.rotated(Vector3.RIGHT, deg_to_rad(mouse_tilt.y * mouse_pitch_degrees))
	offset = offset.rotated(Vector3.UP, deg_to_rad(mouse_tilt.x * mouse_yaw_degrees))
	position = focus + offset
	look_at(focus, Vector3.UP)
