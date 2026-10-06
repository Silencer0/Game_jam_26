extends Control
const FONT = preload("res://assets/kenney/fonts/KenneyFutureNarrow.ttf")
const BINDINGS := [
	["A / D", "MOVE", "Arrow keys also work"],
	["SPACE", "JUMP", "Press again for a double jump"],
	["SHIFT", "DASH", "Ground dash / one air dash"],
	["LEFT CLICK", "ATTACK", "Three-hit combo / aerial lights"],
	["Q", "LAUNCH / SLAM", "Launch on ground, finish in air"],
	["RIGHT CLICK", "PARRY", "Face the attack / reflect bullets"],
	["1 / 2 / 3", "SWITCH PANEL", "Tab cycles the panels"],
	["HOLD E", "TIME DILATION", "Spend one MULT charge in Past or Future"],
	["ESC", "PAUSE / TWIST", "Drag roles: 5 ADD per step, 10 across two"],
	["R", "RESTART", "Begin a fresh timeline"]
]
func _ready() -> void:
	resized.connect(queue_redraw)
func _draw() -> void:
	var half: float = size.x * 0.5
	for i in range(BINDINGS.size()):
		var data: Array = BINDINGS[i]
		var at := Vector2(floorf(float(i) / 5.0) * half + 10, (i % 5) * 73 + 14)
		var box := PackedVector2Array([at + Vector2(6, 0), at + Vector2(134, 0), at + Vector2(128, 38), at + Vector2(0, 38)])
		draw_colored_polygon(box, Color(0.95, 0.77, 0.32))
		draw_string(FONT, at + Vector2(14, 27), data[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.035, 0.035, 0.05))
		draw_string(FONT, at + Vector2(145, 26), data[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.98, 0.96, 0.87))
		draw_string(ThemeDB.fallback_font, at + Vector2(6, 59), data[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.68, 0.72, 0.75))
	draw_line(Vector2(10, 382), Vector2(size.x - 10, 382), Color(0.95, 0.77, 0.32), 2)
	draw_string(ThemeDB.fallback_font, Vector2(14, 410), "Direct kills build ADD. Time contradictions build MULT. Damage = base x ADD x MULT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.98, 0.96, 0.87))
	draw_string(ThemeDB.fallback_font, Vector2(14, 436), "Each MULT charge: 5 seconds at 30% environment speed, plus 1 second closer to Present.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.68, 0.72, 0.75))
