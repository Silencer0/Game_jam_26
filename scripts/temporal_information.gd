extends Node3D
## Shootable mirages mirror live enemies in the next temporal role exactly.
## These meshes have no collision or simulation of their own.

const MAX_CUES: int = 6
var session: Control
var arena: Node3D
var cues: Array[Node3D] = []
var displayed: Array[Dictionary] = []
var ghost_mesh := BoxMesh.new()
var gold := StandardMaterial3D.new()
var violet := StandardMaterial3D.new()

func _ready() -> void:
	arena = get_parent()
	ghost_mesh.size = Vector3(0.9, 1.5, 0.9)
	for material in [gold, violet]:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.albedo_color = Color(1.0, 0.8, 0.25, 0.38)
	violet.albedo_color = Color(0.9, 0.35, 1.0, 0.38)
	for index in range(MAX_CUES):
		var cue := Node3D.new()
		cue.visible = false
		add_child(cue)
		var visual := MeshInstance3D.new()
		visual.name = "Mirage"
		visual.mesh = null
		for part_index in range(6):
			var piece := MeshInstance3D.new()
			var box := BoxMesh.new()
			var positions: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 0.55, 0), Vector3(-0.22, -0.48, 0), Vector3(0.22, -0.48, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0)]
			box.size = Vector3(0.62, 0.58, 0.5) if part_index == 0 else (Vector3(0.5, 0.38, 0.5) if part_index == 1 else Vector3(0.22, 0.42, 0.3))
			piece.mesh = box
			piece.position = positions[part_index]
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			visual.add_child(piece)
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
		for piece in cue.get_node("Mirage").get_children():
			piece.material_override = gold if arena.temporal_role == &"Past" else violet
		cue.get_node("Source").text = str(mirage.source_panel)
