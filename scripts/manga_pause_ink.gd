extends Control
## Printed cover edges behind the pause spread, with a restrained ink registration offset.
@onready var card: Control = $"../Center/Card"
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var r := card.get_global_rect()
	var p := r.position - global_position
	var s := r.size
	var points := PackedVector2Array([p + Vector2(-17, -8), p + Vector2(s.x + 10, -15), p + Vector2(s.x + 17, s.y + 12), p + Vector2(-8, s.y + 19)])
	var shadow := points.duplicate()
	for i in range(shadow.size()):
		shadow[i] += Vector2(10, 10)
	draw_colored_polygon(shadow, Color(0.01, 0.01, 0.02, 0.8))
	draw_colored_polygon(points, Color(0.96, 0.93, 0.83))
	var stroke := points.duplicate()
	stroke.append(points[0])
	draw_polyline(stroke, Color(0.025, 0.025, 0.035), 4, true)
	for i in range(12):
		var y: float = p.y + s.y * 0.64 + float(i) * 8
		draw_line(Vector2(p.x - 15, y), Vector2(p.x - 5, y - 5), Color(0.07, 0.07, 0.08, 0.7), 1.0, true)
