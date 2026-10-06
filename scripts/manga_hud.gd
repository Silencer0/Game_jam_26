extends Control
## One shared, vector-drawn combat HUD. Effects never participate in scoring.
const DISPLAY_FONT = preload("res://assets/kenney/fonts/KenneyFutureNarrow.ttf")
const INK := Color(0.035, 0.035, 0.05)
const PAPER := Color(0.98, 0.96, 0.86)
const GREEN := Color(0.25, 0.92, 0.43)
const GOLD := Color(1.0, 0.73, 0.18)
const VIOLET := Color(0.78, 0.47, 1.0)
const MAX_FLIGHTS := 40
var session: Control
var health_value: int = 6
var add_value: int = 1
var mult_value: float = 1.0
var health_trail: float = 6.0
var display_add: float = 1.0
var display_mult: float = 1.0
var add_pulse: float = 0.0
var mult_pulse: float = 0.0
var hurt_pulse: float = 0.0
var clock: float = 0.0
var flights: Array[Dictionary] = []
var bursts: Array[Dictionary] = []
var emitted_add: int = 0
var emitted_mult: int = 0

func anchor() -> Vector2:
	if session == null:
		return Vector2.ZERO
	return session.panels[session.active_index].position + Vector2(28, 24)

func hud_scale() -> float:
	return clampf(size.x / 1872.0, 0.7, 1.1)

func score_target(kind: StringName) -> Vector2:
	return anchor() + Vector2(260, 101 if kind == &"combat" else 155) * hud_scale()

func launch_score(kind: StringName, from: Vector2) -> void:
	if flights.size() >= MAX_FLIGHTS:
		flights.pop_front()
	flights.append({"kind": kind, "from": from, "age": 0.0, "seed": flights.size() % 5})
	if kind == &"combat":
		emitted_add += 1
		add_pulse = 0.45
	else:
		emitted_mult += 1
		mult_pulse = 0.45

func _process(delta: float) -> void:
	if session == null or session.dilation == null:
		return
	clock += delta
	if health_value > session.health:
		hurt_pulse = 0.45
	health_value = session.health
	add_value = session.addition
	mult_value = session.multiplier
	health_trail = move_toward(health_trail, float(health_value), delta * 2.5)
	display_add = lerpf(display_add, float(add_value), 1.0 - exp(-delta * 15.0))
	display_mult = lerpf(display_mult, mult_value, 1.0 - exp(-delta * 14.0))
	add_pulse = maxf(0.0, add_pulse - delta)
	mult_pulse = maxf(0.0, mult_pulse - delta)
	hurt_pulse = maxf(0.0, hurt_pulse - delta)
	for i in range(flights.size() - 1, -1, -1):
		flights[i].age += delta
		if flights[i].age >= 0.58:
			var kind: StringName = flights[i].kind
			Sfx.play_cue(&"add_collect" if kind == &"combat" else &"mult_collect")
			bursts.append({"kind": kind, "age": 0.0})
			if kind == &"combat":
				add_pulse = 0.32
			else:
				mult_pulse = 0.32
			flights.remove_at(i)
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i].age += delta
		if bursts[i].age > 0.32:
			bursts.remove_at(i)
	if bursts.size() > MAX_FLIGHTS:
		bursts = bursts.slice(bursts.size() - MAX_FLIGHTS)
	queue_redraw()

func quad(at: Vector2, width: float, height: float, slant: float = 12.0) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(slant, 0), at + Vector2(width, 0), at + Vector2(width - slant, height), at + Vector2(0, height)])

func fill_quad(points: PackedVector2Array, color: Color, stroke: float = 3.0) -> void:
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, INK, stroke, true)

func label(at: Vector2, text: String, pixels: int, color: Color = PAPER, width: float = -1) -> void:
	draw_string_outline(DISPLAY_FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, pixels, 5, INK)
	draw_string(DISPLAY_FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, pixels, color)

func draw_bars() -> void:
	# An inked crest, health blade and two attached score ribbons share one silhouette.
	fill_quad(quad(Vector2(0, 0), 344, 52, 20), INK)
	for i in range(session.max_health):
		var x: float = 57.0 + i * 44.0
		fill_quad(quad(Vector2(x, 11), 43, 29, 8), Color(0.13, 0.18, 0.17), 1.5)
		if health_trail > i:
			draw_colored_polygon(quad(Vector2(x + 1, 12), 40, 27, 7), Color(0.93, 0.94, 0.64, 0.6))
		if health_value > i:
			draw_colored_polygon(quad(Vector2(x + 1, 12), 40, 27, 7), GREEN)
			draw_line(Vector2(x + 10, 14), Vector2(x + 33, 14), Color(0.71, 1, 0.76), 2)
	# Heart graphic uses circles and a triangle; no platform-dependent glyphs.
	draw_circle(Vector2(23, 22), 8, GREEN)
	draw_circle(Vector2(36, 22), 8, GREEN)
	draw_colored_polygon(PackedVector2Array([Vector2(15, 23), Vector2(44, 23), Vector2(29, 39)]), GREEN)
	if hurt_pulse > 0:
		draw_polyline(PackedVector2Array([Vector2(0, 51), Vector2(325, 51), Vector2(347, 0)]), Color(1, 0.32, 0.2, hurt_pulse * 2), 5, true)

	var add_y := 65.0 - sin(add_pulse * 14.0) * add_pulse * 4.0
	fill_quad(quad(Vector2(0, add_y), 344, 52, 20), INK)
	# Two banks of five: one full bank buys an adjacent shift, two buy Past/Future.
	for bank in range(2):
		for slot in range(5):
			var at := Vector2(112 + slot * 22, add_y + 7 + bank * 21)
			fill_quad(quad(at, 20, 16, 4), Color(0.28, 0.22, 0.11), 1)
			var fill := add_segment_fill(bank * 5 + slot)
			if fill > 0.01:
				draw_colored_polygon(quad(at + Vector2(1, 1), 18 * fill, 14, minf(3, 4 * fill)), GOLD)
		if add_value >= (bank + 1) * 5:
			draw_line(Vector2(112, add_y + 25 + bank * 21), Vector2(219, add_y + 25 + bank * 21), GOLD, 2)
	label(Vector2(24, add_y + 35), "ADD", 22)
	var add_text := "+%d" % roundi(display_add)
	var add_font_size := 26
	while add_font_size > 12 and DISPLAY_FONT.get_string_size(add_text, HORIZONTAL_ALIGNMENT_LEFT, -1, add_font_size).x > 94:
		add_font_size -= 1
	label(Vector2(230, add_y + 35), add_text, add_font_size)
	for i in range(8):
		draw_line(Vector2(330 + i * 4, add_y + 8), Vector2(324 + i * 4, add_y + 29), Color(0.02, 0.025, 0.04, 0.45), 1.2)

	var mult_y := 122.0 - sin(mult_pulse * 14.0) * mult_pulse * 4.0
	fill_quad(quad(Vector2(0, mult_y), 344, 52, 20), INK)
	label(Vector2(24, mult_y + 35), "MULT", 22)
	for i in range(3):
		var at := Vector2(126 + i * 38, mult_y + 26)
		var diamond := PackedVector2Array([at + Vector2(0, -16), at + Vector2(16, 0), at + Vector2(0, 16), at + Vector2(-16, 0)])
		fill_quad(diamond, Color(0.22, 0.17, 0.31), 2)
		var charge: float = clampf(display_mult - 1.0 - i, 0, 1)
		if charge > 0.02:
			var charged := diamond.duplicate()
			for j in range(charged.size()):
				charged[j] = at + (charged[j] - at) * (0.4 + 0.55 * charge)
			draw_colored_polygon(charged, VIOLET.lerp(PAPER, charge * 0.15))
	var mult_text := "x%.2f" % display_mult
	var mult_font_size := 20
	while mult_font_size > 12 and DISPLAY_FONT.get_string_size(mult_text, HORIZONTAL_ALIGNMENT_LEFT, -1, mult_font_size).x > 92:
		mult_font_size -= 1
	var mult_text_width := DISPLAY_FONT.get_string_size(mult_text, HORIZONTAL_ALIGNMENT_LEFT, -1, mult_font_size).x
	label(Vector2(324 - mult_text_width, mult_y + 35), mult_text, mult_font_size)
	var slow_left: float = session.dilation.remaining_for(session.active_index)
	if session.dilation.charging:
		label(Vector2(359, mult_y + 31), "HOLD %.1fs" % maxf(0, session.dilation.HOLD_SECONDS - session.dilation.charge_elapsed), 16, VIOLET)
	elif slow_left > 0:
		label(Vector2(359, mult_y + 31), "SLOW %.1fs" % slow_left, 16, VIOLET)
	elif mult_value >= 2.0 - 0.00001:
		var pulse: float = 0.55 + 0.15 * sin(clock * 5)
		draw_polyline(PackedVector2Array([Vector2(0, mult_y + 52), Vector2(324, mult_y + 52), Vector2(344, mult_y)]), Color(VIOLET, pulse), 3.0, true)
		fill_quad(quad(Vector2(357, mult_y + 4), 93, 38, 11), VIOLET)
		var rank: int = session.ROLE_NAMES.find(session.panels[session.active_index].arena.temporal_role)
		var eligible: bool = rank != 1 and session.gaps[0 if rank == 0 else 1] > 0
		label(Vector2(364, mult_y + 29), "READY" if eligible else "CHARGED", 16)

func add_segment_fill(index: int) -> float:
	return clampf(display_add - index, 0.0, 1.0)

func draw_timeline() -> void:
	# Center the three role dots above the action, independently of the meters.
	var y := 0.0
	for i in range(3):
		var x: float = 26 + i * 144
		var role: StringName = session.ROLE_NAMES[i]
		draw_circle(Vector2(x, y), 10, session.panels[0].ROLE_COLORS[role])
		if i < 2:
			draw_line(Vector2(x + 13, y), Vector2(x + 127, y), Color(PAPER, 0.7), 2)
			label(Vector2(x + 32, y - 8), "%.1fs" % session.gaps[i], 20)
		if role == session.panels[session.active_index].arena.temporal_role:
			draw_arc(Vector2(x, y), 15, 0, TAU, 24, PAPER, 2.0, true)

func _draw() -> void:
	if session == null or session.dilation == null:
		return
	var origin := anchor()
	var scale_factor := hud_scale()
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	draw_bars()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var panel: Control = session.panels[session.active_index]
	var timeline_scale := scale_factor * 1.25
	draw_set_transform(panel.position + Vector2(panel.size.x * 0.5 - 170 * timeline_scale, 57 * scale_factor), 0, Vector2.ONE * timeline_scale)
	draw_timeline()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var brand_at: Vector2 = panel.position + Vector2(panel.size.x - 330 * scale_factor, 53 * scale_factor)
	draw_string_outline(DISPLAY_FONT, brand_at, "FRAME//SHIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(26 * scale_factor), 5, INK)
	draw_string(DISPLAY_FONT, brand_at, "FRAME//SHIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(26 * scale_factor), PAPER)
	for flight in flights:
		var t: float = clampf(flight.age / 0.58, 0, 1)
		var target := score_target(flight.kind)
		var control: Vector2 = flight.from.lerp(target, 0.5) + Vector2(45 + flight.seed * 10, -90)
		var at: Vector2 = pow(1.0 - t, 2) * flight.from + 2.0 * (1.0 - t) * t * control + t * t * target
		var color := GOLD if flight.kind == &"combat" else VIOLET
		for i in range(3):
			var offset := Vector2(12 + i * 6, 8 + i * 4)
			draw_line(at + offset, at + offset * 2, Color(color, 0.6 - i * 0.15), 2, true)
		fill_quad(PackedVector2Array([at + Vector2(0, -10), at + Vector2(10, 0), at + Vector2(0, 10), at + Vector2(-10, 0)]), color, 2)
		label(at + Vector2(10, -8), "+1", 22, color)
	for burst in bursts:
		var target := score_target(burst.kind)
		var color := GOLD if burst.kind == &"combat" else VIOLET
		var radius: float = 12 + burst.age * 140
		for i in range(8):
			var direction := Vector2.from_angle(i * TAU / 8)
			draw_line(target + direction * radius * 0.65, target + direction * radius, Color(color, 1.0 - burst.age / 0.32), 3, true)
	if session.result != &"fighting":
		var center: Vector2 = panel.position + panel.size * 0.5
		var won: bool = session.result == &"singularity"
		draw_set_transform(center - Vector2(370, 60), -0.035 if won else 0.0)
		fill_quad(quad(Vector2.ZERO, 740, 120, 35), PAPER)
		if won:
			label(Vector2(40, 58), "SINGULARITY!", 46, VIOLET)
			label(Vector2(43, 95), "ONE FRAME. ONE TIMELINE.", 22, PAPER)
		else:
			var title := "Time Line lost"
			var title_width := DISPLAY_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
			var baseline := 60.0 + (DISPLAY_FONT.get_ascent(46) - DISPLAY_FONT.get_descent(46)) * 0.5
			label(Vector2((740 - title_width) * 0.5, baseline), title, 46, Color(1, 0.38, 0.23))
		draw_set_transform(Vector2.ZERO, 0)
