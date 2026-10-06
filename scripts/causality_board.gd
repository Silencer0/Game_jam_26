extends Control
## A compact enemy ledger: lines join real counterparts, X marks tombstones.
const GRUNT = preload("res://assets/characters/ember/grunt.png")
const GUNNER = preload("res://assets/characters/ember/gunner.png")
const ROW_HEIGHT := 60.0
var session: Control
var rows: Array[Dictionary] = []

func refresh() -> void:
	rows.clear()
	if not is_instance_valid(session) or session.ledger == null:
		return
	for id: int in session.ledger.records:
		var record: Dictionary = session.ledger.records[id]
		var cells: Array[StringName] = []
		for rank in range(3):
			cells.append(session.ledger.state_for(id, session.ledger.panel_for_rank(rank)))
		rows.append({"id": id, "species": record.species, "cells": cells})
	custom_minimum_size.y = maxf(60, rows.size() * ROW_HEIGHT)
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if rows.is_empty():
		draw_string(font, Vector2(20, 30), "No enemy links yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		return
	var column_width: float = size.x / 3.0
	for row_index in range(rows.size()):
		var row: Dictionary = rows[row_index]
		var y: float = row_index * ROW_HEIGHT
		draw_rect(Rect2(0, y, size.x, ROW_HEIGHT), Color(0.10, 0.12, 0.16, 0.9) if row_index % 2 == 0 else Color(0.06, 0.08, 0.11, 0.9))
		var previous := -1
		for rank in range(3):
			if row.cells[rank] != &"missing":
				if previous >= 0:
					draw_line(Vector2((previous + 0.5) * column_width + 20, y + 36), Vector2((rank + 0.5) * column_width - 20, y + 36), Color(0.76, 0.72, 0.54), 2.0, true)
				previous = rank
		for rank in range(3):
			var x: float = (rank + 0.5) * column_width
			var dead: bool = row.cells[rank] == &"dead"
			if row.cells[rank] == &"missing":
				draw_string(font, Vector2(x - 23, y + 36), "—", HORIZONTAL_ALIGNMENT_CENTER, 46, 18, Color(0.4, 0.44, 0.5))
				continue
			var texture: Texture2D = GUNNER if row.species == &"gunner" else GRUNT
			draw_texture_rect_region(texture, Rect2(x - 24, y + 5, 48, 48), Rect2(0, 0, 128, 128), Color(1, 1, 1, 0.28 if dead else 1.0))
			draw_string(font, Vector2(x + 29, y + 36), "#%02d" % row.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.68, 0.72, 0.8))
			if dead:
				draw_line(Vector2(x - 13, y + 15), Vector2(x + 13, y + 45), Color(1, 0.25, 0.18), 3.0, true)
				draw_line(Vector2(x + 13, y + 15), Vector2(x - 13, y + 45), Color(1, 0.25, 0.18), 3.0, true)
