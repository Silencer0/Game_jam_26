extends Button
## A fixed role slot containing one draggable, numbered arena preview.

@export var role: StringName = &"Past"
var panel_index: int = 0
var session: Control
var preview_tween: Tween

func set_preview(texture: Texture2D) -> void:
	if $Preview.texture == texture:
		return
	var had_preview: bool = $Preview.texture != null
	$Preview.texture = texture
	if not had_preview:
		return
	if preview_tween != null and preview_tween.is_valid():
		preview_tween.kill()
	$Preview.modulate.a = 0.15
	preview_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	preview_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	preview_tween.tween_property($Preview, "modulate:a", 1.0, 0.22).set_delay(0.16)

func _get_drag_data(_position: Vector2) -> Variant:
	if not get_tree().paused:
		return null
	Sfx.play_cue(&"drag_pickup")
	var preview := VBoxContainer.new()
	preview.rotation = -0.04
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := TextureRect.new()
	image.texture = $Preview.texture
	image.custom_minimum_size = Vector2(200, 110)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(image)
	var number := Label.new()
	number.text = str(panel_index + 1)
	number.add_theme_font_size_override("font_size", 30)
	number.modulate = Color(1, 0.82, 0.32)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(number)
	set_drag_preview(preview)
	preview.modulate.a = 0.45
	preview.scale = Vector2.ONE * 0.92
	var pickup := preview.create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pickup.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pickup.tween_property(preview, "modulate:a", 0.9, 0.14)
	pickup.tween_property(preview, "scale", Vector2.ONE, 0.14)
	return {"panel_session": session.get_instance_id(), "panel_index": panel_index}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return get_tree().paused and data is Dictionary and data.get("panel_session") == session.get_instance_id() and data.get("panel_index") is int and session.can_shift_frame(data.panel_index, role)

func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_position, data):
		session.assign_panel_role(data.panel_index, role)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not get_viewport().gui_is_drag_successful():
		Sfx.play_cue(&"ui_error")
