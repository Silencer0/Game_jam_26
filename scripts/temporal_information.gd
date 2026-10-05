extends Node3D
## Shootable mirages mirror live enemies in the next temporal role exactly.
## These sprites have no collision or simulation of their own.

const MAX_CUES: int = 6
var session: Control
var arena: Node3D
var cues: Array[Node3D] = []
var displayed: Array[Dictionary] = []

func _ready() -> void:
	arena = get_parent()
	for index in range(MAX_CUES):
		var cue := Node3D.new()
		cue.visible = false
		add_child(cue)
		var visual := Sprite3D.new()
		visual.name = "Mirage"
		visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		visual.shaded = false
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cue.add_child(visual)
		var label := Label3D.new()
		label.name = "Source"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 28
		label.pixel_size = 0.007
		label.outline_size = 5
		label.position = Vector3(0, 1.1, 0)
		cue.add_child(label)
		cues.append(cue)

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	var tint := Color(1.0, 0.85, 0.5, 0.55) if arena.temporal_role == &"Past" else Color(0.95, 0.6, 1.0, 0.55)
	displayed.clear()
	if is_instance_valid(session) and arena.result == &"fighting" and arena.temporal_role != &"Future":
		var target_role: StringName = &"Present" if arena.temporal_role == &"Past" else &"Future"
		for index in range(session.panels.size()):
			var target: Node3D = session.panels[index].arena
			if target.temporal_role != target_role or target.result != &"fighting":
				continue
			for enemy in target.enemies.get_children():
				if not enemy.dead and displayed.size() < MAX_CUES:
					displayed.append({"enemy_id": enemy.get_instance_id(), "position": enemy.position, "source_panel": index + 1})
	for index in range(cues.size()):
		var cue: Node3D = cues[index]
		cue.visible = index < displayed.size()
		if not cue.visible:
			continue
		var mirage: Dictionary = displayed[index]
		cue.position = mirage.position
		cue.get_node("Source").text = str(mirage.source_panel)
		var enemy: Node3D = instance_from_id(mirage.enemy_id) as Node3D
		if not is_instance_valid(enemy):
			cue.visible = false
			continue
		var source: Sprite3D = enemy.visual.sprite
		var visual: Sprite3D = cue.get_node("Mirage")
		visual.frame = 0
		visual.texture = source.texture
		visual.hframes = source.hframes
		visual.vframes = source.vframes
		visual.frame = source.frame
		visual.flip_h = source.flip_h
		visual.pixel_size = source.pixel_size
		visual.position = source.position
		visual.scale = enemy.visual.scale
		visual.modulate = tint
