extends Control
## Independently simulated world clipped into an inked polygon on the comic page.
const ROLE_ICONS: Dictionary = {&"Past": "<<", &"Present": "", &"Future": ">>"}
const ROLE_COLORS: Dictionary = {&"Past": Color(1.0, 0.72, 0.22), &"Present": Color(0.25, 0.9, 0.45), &"Future": Color(0.85, 0.4, 1.0)}
@export var arena_id: StringName = &"A"
@export var controlled: bool = false
var damage_indicator_left: float = 0.0
var danger: bool = false
var pulse_time: float = 0.0
var impact_left: float = 0.0
var impact: TextureRect
var impact_material: ShaderMaterial
var frame: StyleBoxFlat
var ink: Control
var edges := Vector4(0, 1, 0, 1)
var switch_flash: float = 0.0
var resize_left: float = 0.0
var world_material: ShaderMaterial
@onready var danger_tint: ColorRect = $DangerTint
@onready var viewport: SubViewport = $Margin/Column/World/Viewport
@onready var world: TextureRect = $Margin/Column/World
@onready var arena: Node3D = $Margin/Column/World/Viewport/Arena
@onready var header: Label = $Margin/Column/HeaderRow/Header
@onready var role_icon: Label = $Margin/Column/HeaderRow/RoleIcon
@onready var switch_hint: Label = $SwitchHint
@onready var status: Label = $Margin/Column/Status

func _ready() -> void:
	role_icon.add_theme_font_override("font", ThemeDB.fallback_font)
	frame = get_theme_stylebox("panel").duplicate()
	world.texture = viewport.get_texture()
	world_material = ShaderMaterial.new()
	world_material.shader = preload("res://shaders/manga_panel.gdshader")
	world.material = world_material
	impact = TextureRect.new()
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact.texture = viewport.get_texture()
	impact.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	impact_material = ShaderMaterial.new()
	impact_material.shader = preload("res://shaders/damage_impact.gdshader")
	impact.material = impact_material
	impact.visible = false
	impact.z_index = 10
	# The ink overlay contains impact treatment; avoid rectangular flashes outside polygons.
	add_child(impact)
	ink = preload("res://scripts/manga_panel_ink.gd").new()
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink.panel = self
	ink.z_index = 11
	add_child(ink)
	arena.player.damage_taken.connect(on_damage_taken)
	arena.restart_enabled = false
	arena.get_node("HUD").visible = false
	arena.set_process(false)
	arena.get_node("Camera3D").mouse_enabled = false
	resized.connect(on_resize)
	on_resize()
	resize_viewport()

func polygon() -> PackedVector2Array:
	var inset := 4.0
	return PackedVector2Array([Vector2(edges.x * size.x + inset, inset), Vector2(edges.y * size.x - inset, inset), Vector2(edges.w * size.x - inset, size.y - inset), Vector2(edges.z * size.x + inset, size.y - inset)])

func set_edges(value: Vector4) -> void:
	edges = value
	if world_material != null:
		world_material.set_shader_parameter("edges", edges)
	position_labels()
	if ink != null:
		ink.queue_redraw()

func on_resize() -> void:
	resize_left = 0.08
	position_labels()
	if ink != null:
		ink.size = size
		ink.queue_redraw()

func resize_viewport() -> void:
	if size.x < 10 or size.y < 10:
		return
	# Render below full canvas size; three worlds remain cheaper than 1080p each.
	var ratio: float = minf(0.78, 1440.0 / size.x)
	viewport.size = Vector2i(maxi(64, roundi(size.x * ratio)), maxi(64, roundi(size.y * ratio)))
	arena.get_node("Camera3D").update_follow()

func position_labels() -> void:
	if not is_node_ready():
		return
	var left: float = edges.x * size.x + 24.0
	var right: float = edges.y * size.x - 24.0
	header.position = Vector2(left, 16)
	header.visible = not controlled
	role_icon.position = Vector2(right - 56, 14)
	status.position = Vector2(edges.z * size.x + 24, size.y - 40)
	switch_hint.position = Vector2((edges.x + edges.y + edges.z + edges.w) * size.x * 0.25 - 90, size.y * 0.5 - 90)
	switch_hint.size = Vector2(180, 180)
	if ink != null:
		ink.size = size

func set_controlled(value: bool, inactive_rate: float) -> void:
	if controlled != value:
		switch_flash = 0.34
	controlled = value
	arena.player.set_input_enabled(controlled)
	set_simulation_rate(1.0 if controlled else inactive_rate)
	arena.get_node("Camera3D").zoom_target = 10.5 if controlled else 5.8
	arena.get_node("Camera3D").threat_focus = not controlled
	switch_hint.text = str({&"A": 1, &"B": 2, &"C": 3}[arena_id])
	switch_hint.visible = not controlled
	position_labels()
	update_frame()

func set_simulation_rate(rate: float, player_rate: float = -1.0) -> void:
	arena.set_simulation_rate(rate, player_rate)
	refresh_header()

func refresh_header() -> void:
	header.text = "%02d / %s" % [{&"A": 1, &"B": 2, &"C": 3}[arena_id], String(arena.temporal_role).to_upper()]
	role_icon.text = ROLE_ICONS[arena.temporal_role]
	role_icon.tooltip_text = String(arena.temporal_role)
	role_icon.modulate = ROLE_COLORS[arena.temporal_role] if controlled else Color(0.78, 0.79, 0.77)
	switch_hint.add_theme_color_override("font_color", Color(ROLE_COLORS[arena.temporal_role], 0.48))
	update_frame()

func on_damage_taken() -> void:
	impact_left = 0.12
	damage_indicator_left = 1.6
	pulse_time = 0.0
	update_frame()

func damage_indicator_needed() -> bool:
	return not controlled and damage_indicator_left > 0.0

func update_frame() -> void:
	danger = damage_indicator_needed()
	danger_tint.visible = danger
	frame.border_color = Color(1.0, 0.18, 0.14) if danger else (ROLE_COLORS[arena.temporal_role] if controlled else Color(0.035, 0.035, 0.045))
	frame.shadow_color = Color(1.0, 0.08, 0.04, 0.75) if danger else Color(0.02, 0.025, 0.035, 0.8)
	frame.shadow_size = 10 if danger else (4 if controlled else 0)
	frame.set_border_width_all(8 if danger else (6 if controlled else 5))
	if ink != null:
		ink.queue_redraw()

func draw_ink(canvas: Control) -> void:
	var points := polygon()
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, Color(0.02, 0.02, 0.03), 10.0, true)
	if controlled or danger:
		canvas.draw_polyline(closed, frame.border_color, 3.0 if controlled else 7.0, true)
	if danger:
		canvas.draw_colored_polygon(points, Color(1, 0.06, 0.035, 0.06 + 0.025 * sin(pulse_time * 10.0)))
	if impact_left > 0.0:
		canvas.draw_colored_polygon(points, Color(1, 0.96, 0.83, 0.55 * impact_left / 0.12))
		for i in range(8):
			var x: float = lerpf(points[0].x, points[1].x, float(i) / 8.0)
			canvas.draw_line(Vector2(x, 8), Vector2(x + 80, 90), Color(0.03, 0.03, 0.04, impact_left * 3.0), 2.0, true)
	if arena.temporal_role == &"Present":
		canvas.draw_circle(role_icon.position + Vector2(27, 22), 10.0, role_icon.modulate)
	if not controlled:
		var sides := offscreen_enemy_sides()
		for side in range(2):
			if not sides[side]:
				continue
			var y := size.y * 0.56
			var edge: float = lerpf(edges.x if side == 0 else edges.y, edges.z if side == 0 else edges.w, y / size.y) * size.x
			var inward := 1.0 if side == 0 else -1.0
			var tip := Vector2(edge + inward * 22, y)
			var arrow := PackedVector2Array([tip, tip + Vector2(inward * 44, -30), tip + Vector2(inward * 44, 30)])
			canvas.draw_colored_polygon(arrow, Color(1.0, 0.78, 0.25, 0.94))
			var outline := arrow.duplicate()
			outline.append(arrow[0])
			canvas.draw_polyline(outline, Color(0.025, 0.025, 0.035), 5, true)
			var mark := tip + Vector2(inward * 31, 0)
			canvas.draw_line(mark + Vector2(0, -12), mark + Vector2(0, 4), Color(0.025, 0.025, 0.035), 5, true)
			canvas.draw_circle(mark + Vector2(0, 12), 3, Color(0.025, 0.025, 0.035))
	if switch_flash > 0.0:
		# Thin kinetic strokes preserve visibility throughout a page turn.
		var alpha: float = switch_flash / 0.34
		for i in range(7):
			var y: float = 50.0 + float(i) * 15.0
			var x: float = lerpf(edges.x, edges.z, y / maxf(1.0, size.y)) * size.x
			canvas.draw_line(Vector2(x + 12, y), Vector2(x + 150 * alpha, y - 18), Color(1, 0.97, 0.87, alpha * 0.75), 3.0, true)

func offscreen_enemy_sides() -> Array[bool]:
	var sides: Array[bool] = [false, false]
	if controlled or size.x <= 0 or size.y <= 0:
		return sides
	var camera: Camera3D = arena.get_node("Camera3D")
	var visible_polygon := polygon()
	var middle: float = (edges.x + edges.y + edges.z + edges.w) * size.x * 0.25
	for enemy in arena.enemies.get_children():
		if enemy.dead:
			continue
		var visible := false
		# Include silhouette corners so partly visible enemies do not get an arrow.
		for offset in [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 1.8, 0), Vector3(0.5, 1.8, 0), Vector3(0, 0.9, 0)]:
			var at: Vector3 = enemy.global_position + offset
			var projected := camera.unproject_position(at) / Vector2(viewport.size) * size
			if not camera.is_position_behind(at) and Geometry2D.is_point_in_polygon(projected, visible_polygon):
				visible = true
				break
		if not visible:
			var projected := camera.unproject_position(enemy.global_position + Vector3(0, 0.9, 0)) / Vector2(viewport.size) * size
			sides[0 if projected.x < middle else 1] = true
	return sides

func world_to_page(at: Vector3) -> Vector2:
	var camera: Camera3D = arena.get_node("Camera3D")
	var projected := camera.unproject_position(at)
	var local := projected / Vector2(viewport.size) * size
	if camera.is_position_behind(at) or not Geometry2D.is_point_in_polygon(local, polygon()):
		local = Vector2(size.x * 0.5, size.y * 0.55)
	return position + local

func _process(delta: float) -> void:
	resize_left = maxf(0.0, resize_left - delta)
	if resize_left == 0.0 and size.x > 10:
		var ratio: float = minf(0.78, 1440.0 / size.x)
		if viewport.size != Vector2i(roundi(size.x * ratio), roundi(size.y * ratio)):
			resize_viewport()
	impact_left = maxf(0.0, impact_left - delta)
	impact.visible = false
	damage_indicator_left = maxf(0.0, damage_indicator_left - delta)
	switch_flash = maxf(0.0, switch_flash - delta)
	if arena.temporal_managed and arena.causal_ledger != null and arena.result == &"fighting":
		status.text = "WAVE %02d" % arena.causal_ledger.wave
		if arena.causal_ledger.wave_cleared:
			status.text = "WAVE %02d CLEAR / NEXT %.1fs" % [arena.causal_ledger.wave, arena.causal_ledger.spawn_left]
	elif arena.temporal_managed:
		status.text = ""
	else:
		status.text = arena.status_text(false)
	if arena.result == &"victory" and arena.temporal_managed:
		status.text = ""
	if arena.player.health_owner != null and arena.player.health_owner.tutorial_mode:
		status.text = ""
	if danger != damage_indicator_needed():
		update_frame()
	if danger:
		pulse_time += delta
	if not controlled or danger or impact_left > 0.0 or switch_flash > 0.0:
		ink.queue_redraw()
