extends Button
## A fixed role slot containing one draggable, numbered arena preview.

@export var role: StringName = &"Past"
var panel_index: int = 0
var session: Control

func _get_drag_data(_position: Vector2) -> Variant:
	if not get_tree().paused:
		return null
	var preview := VBoxContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := TextureRect.new()
	image.texture = $Preview.texture
	image.custom_minimum_size = Vector2(200, 110)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(image)
	var number := Label.new()
	number.text = str(panel_index + 1)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(number)
	set_drag_preview(preview)
	return {"panel_session": session.get_instance_id(), "panel_index": panel_index}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return get_tree().paused and data is Dictionary and data.get("panel_session") == session.get_instance_id() and data.get("panel_index") is int and data.panel_index >= 0 and data.panel_index < session.panels.size()

func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_position, data):
		session.assign_panel_role(data.panel_index, role)
