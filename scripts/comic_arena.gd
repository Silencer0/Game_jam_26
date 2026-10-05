extends Node3D
## A layered, noncolliding workshop. Static geometry is batched by material.

const GEOMETRY = preload("res://scripts/comic_geometry.gd")
const RAIL = preload("res://assets/kenney/station/balcony-rail-center.fbx")
const CONSOLE = preload("res://assets/kenney/station/computer-system.fbx")
const CRATE = preload("res://assets/kenney/station/container-flat.fbx")
const FONT = preload("res://assets/kenney/fonts/KenneyFuture.ttf")
const INK = Color(0.12, 0.13, 0.19)
const STEEL = Color(0.47, 0.52, 0.57)
const SILVER = Color(0.26, 0.30, 0.36)
const YELLOW = Color(0.95, 0.76, 0.29)
const TEAL = Color(0.15, 0.66, 0.59)
const RED = Color(0.78, 0.30, 0.27)
const CREAM = Color(0.88, 0.85, 0.69)
const LIGHT = Color(0.40, 0.42, 0.43)
var materials: Dictionary = {}
var batches: Dictionary = {}
var screen_material: ShaderMaterial
var scenery_time: float = 0.0
var skyline: MeshInstance3D
var skyline_mesh: QuadMesh
var backdrop_camera: Camera3D

func _ready() -> void:
	# Open rooftop: high detail is at the edges, while the lane stays quiet.
	backdrop_camera = get_parent().get_node("Camera3D")
	# Camera-relative distant backdrop preserves the whole skyline as panels resize.
	var sky := MeshInstance3D.new()
	var sky_plane := QuadMesh.new()
	sky_plane.size = Vector2(200, 200)
	sky.mesh = sky_plane
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://shaders/toon_sky.gdshader")
	sky.material_override = sky_material
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backdrop_camera.add_child(sky)
	sky.position.z = -90.0
	skyline = MeshInstance3D.new()
	skyline_mesh = QuadMesh.new()
	skyline.mesh = skyline_mesh
	var city_material := StandardMaterial3D.new()
	city_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	city_material.albedo_texture = preload("res://assets/environment/comic_city.png")
	city_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	skyline.material_override = city_material
	skyline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backdrop_camera.add_child(skyline)
	skyline.position.z = -85.0
	fit_skyline()
	# Original atmospheric comic city: one shared texture, no extra simulation.
	# Red service buildings sit below the horizon behind a low parapet.
	for x in [5.0, 27.0]:
		box(Vector3(x, 0.5, -8), Vector3(7, 4, 4), RED)
		box(Vector3(x, 2.55, -8), Vector3(7.3, 0.25, 4.3), CREAM)
		box(Vector3(x, 2.72, -8), Vector3(6.5, 0.10, 3.4), TEAL)
		for offset in ([-1.7, 1.7] if x < 16 else [-1.7]):
			box(Vector3(x + offset, 3.15, -8), Vector3(1.1, 0.7, 1.4), CREAM)
			cylinder(Vector3(x + offset, 3.53, -8), 0.34, 0.07, INK)
			cylinder(Vector3(x + offset, 3.58, -8), 0.24, 0.03, STEEL)
		cylinder(Vector3(x - 2.6, 0.7, -5.8), 0.20, 3.8, TEAL)
		for y in [-0.6, 1.6]:
			cylinder(Vector3(x - 2.6, y, -5.8), 0.28, 0.14, CREAM)
		service_wall(x, "01" if x < 16 else "02")
	# Cream/teal deck edges and a low rear railing frame the fight.
	box(Vector3(16, -0.4, 3.1), Vector3(32, 0.5, 0.25), CREAM)
	box(Vector3(16, -0.2, 3.27), Vector3(32, 0.12, 0.1), RED)
	for z in [-2.7, 2.7]:
		box(Vector3(16, 0.025, z), Vector3(30, 0.05, 0.22), TEAL)
		box(Vector3(16, 0.03, z - 0.18), Vector3(30, 0.05, 0.06), YELLOW)
	box(Vector3(16, 0.28, -3.0), Vector3(30, 0.45, 0.25), CREAM)
	box(Vector3(16, 0.58, -3.0), Vector3(30, 0.10, 0.30), INK)
	for x in range(2, 32, 5):
		box(Vector3(x, 0.3, -2.83), Vector3(0.30, 0.3, 0.09), TEAL)
	# Cargo/service side versus rooftop utility side: deliberately different silhouettes.
	prop(CONSOLE, Vector3(2.8, 0, -3.8), 1.1, CREAM)
	prop(CRATE, Vector3(3.9, 0, -4.1), 0.65, YELLOW)
	prop(CRATE, Vector3(4.2, 0.65, -4.1), 0.42, STEEL)
	prop(CONSOLE, Vector3(29.2, 0, -2.2), 0.85, TEAL)
	cylinder(Vector3(28.5, 3.64, -8.4), 0.61, 1.74, TEAL)
	for y in [2.86, 4.39]:
		cylinder(Vector3(28.5, y, -8.4), 0.65, 0.12, CREAM)
	world_details()
	build_batches()

func _process(delta: float) -> void:
	fit_skyline()
	# Screens inherit pause and arena-local flow, including inactive panel slowdown.
	scenery_time += delta * get_parent().simulation_rate
	if screen_material != null:
		screen_material.set_shader_parameter("local_time", scenery_time)

func world_details() -> void:
	# Continuous rails across the rear edge, bolted directly to the fight deck.
	for y in [0.58, 1.16]:
		box(Vector3(16, y, -2.72), Vector3(29.4, 0.07, 0.07), YELLOW)
	for index in range(21):
		var x: float = 1.3 + float(index) * 1.47
		box(Vector3(x, 0.65, -2.72), Vector3(0.075, 1.3, 0.075), STEEL)
		box(Vector3(x, 0.04, -2.72), Vector3(0.20, 0.08, 0.20), SILVER)
	# A solid apron joins the left service props to the actual deck (rear edge z=-3).
	# Its top is y=0, matching the feet of the signal, kiosk and cargo.
	box(Vector3(5.7, -0.8, -4.65), Vector3(10.8, 1.6, 3.5), STEEL)
	box(Vector3(5.7, -0.12, -6.36), Vector3(10.8, 0.22, 0.12), CREAM)
	# Street lamps stand on the visible floor in front of the combat plane.
	# Plinth, mast, arm and lantern overlap into one continuous structure.
	for anchor: Vector3 in [Vector3(1.6, 0, 0.45), Vector3(30.0, 0, 0.45)]:
		var left := anchor.x < 16.0
		var arm_direction := 1.0 if left else -1.0
		var height := 3.7 if left else 2.85
		cylinder(anchor + Vector3(0, 0.012, 0), 0.70, 0.024, Color(0.28, 0.31, 0.28))
		box(anchor + Vector3(0, 0.14, 0), Vector3(1.12, 0.28, 0.96), STEEL)
		box(anchor + Vector3(0, 0.52, 0), Vector3(0.70, 0.76, 0.62), CREAM)
		box(anchor + Vector3(0, (height + 0.50) * 0.5, 0), Vector3(0.48, height - 0.50, 0.44), STEEL, true)
		box(anchor + Vector3(arm_direction * 0.47, height - 0.09, 0), Vector3(1.15, 0.18, 0.36), STEEL)
		var lamp_color := Color(1.0, 0.73, 0.42) if left else Color(0.52, 0.67, 1.0)
		# A hanging street-lamp lantern has visible luminous front/side faces.
		# Its x offset keeps the arm and fixture distinct in the side camera.
		var head := anchor + Vector3(arm_direction * 0.96, 0, 0)
		box(head + Vector3(0, height - 0.10, 0), Vector3(0.78, 0.16, 0.64), SILVER)
		box(head + Vector3(0, height - 0.34, 0), Vector3(0.56, 0.38, 0.46), lamp_color.lightened(0.25), true)
		box(head + Vector3(0, height - 0.55, 0), Vector3(0.65, 0.07, 0.55), SILVER)
		for corner in [-1.0, 1.0]:
			box(head + Vector3(corner * 0.29, height - 0.34, 0.25), Vector3(0.045, 0.40, 0.045), SILVER)
		for offset in [-0.37, 0.37]:
			cylinder(anchor + Vector3(offset, 0.30, 0.25), 0.045, 0.045, SILVER)
		pool_light(head + Vector3(0, height - 0.60, 0),
			anchor + Vector3(arm_direction * 1.4, 0, 0.6), lamp_color, 3.6 if left else 3.0)
		if left:
			box(anchor + Vector3(0, 2.6, 0.17), Vector3(0.34, 0.85, 0.24), SILVER)
			for index in range(3):
				cylinder(anchor + Vector3(0, 2.85 - index * 0.25, 0.33), 0.09, 0.04,
					[Color(0.40, 0.22, 0.22), Color(0.56, 0.44, 0.21), Color(0.34, 0.65, 0.48)][index], Vector3(90, 0, 0))
	# Screens are floor-mounted on the service apron, with visible posts and bases.
	screen_material = ShaderMaterial.new()
	screen_material.shader = preload("res://shaders/comic_screen.gdshader")
	for anchor: Vector3 in [Vector3(10.5, 1.48, -5.8)]:
		box(Vector3(anchor.x, 0.04, anchor.z), Vector3(0.90, 0.08, 0.70), SILVER)
		box(Vector3(anchor.x, 0.52, anchor.z), Vector3(0.18, 1.04, 0.18), STEEL)
		box(anchor + Vector3(0, 0, -0.12), Vector3(2.36, 1.55, 0.26), STEEL)
		box(anchor, Vector3(2.12, 1.35, 0.18), SILVER)
		box(anchor + Vector3(0, 0.74, 0), Vector3(2.28, 0.09, 0.24), CREAM)
		for offset in [-0.84, 0.84]:
			box(anchor + Vector3(offset, -0.82, -0.11), Vector3(0.20, 0.24, 0.36), CREAM)
		var screen := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.85, 1.15)
		screen.mesh = quad
		screen.position = anchor + Vector3(0, 0, 0.10)
		screen.material_override = screen_material
		screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(screen)
	var screen_spill := OmniLight3D.new()
	screen_spill.name = "UtilityScreenSpill"
	screen_spill.position = Vector3(10.5, 1.48, -5.55)
	screen_spill.light_color = Color(0.40, 0.82, 0.72)
	screen_spill.light_energy = 0.65
	screen_spill.omni_range = 3.2
	screen_spill.shadow_enabled = false
	add_child(screen_spill)
	# Painted wayfinding on the edge of the deck, away from player feet.
	for x in [5.0, 26.0]:
		for offset in [-0.35, 0.0, 0.35]:
			var mark := QuadMesh.new()
			mark.size = Vector2(0.38, 0.085)
			for side in [-1.0, 1.0]:
				append(mark, Vector3(x + offset, 0.052, -2.1 + side * 0.12), CREAM, true,
					Vector3(-PI / 2, side * PI / 5, 0))
	# Small hand-painted lightning tags on parapet faces, not bright billboards.
	for x in [8.0, 24.5]:
		for index in range(3):
			var stroke := QuadMesh.new()
			stroke.size = Vector2(0.29, 0.045)
			append(stroke, Vector3(x + index * 0.10, 0.39 - index * 0.09, -2.866), TEAL, true,
				Vector3(0, 0, -0.55 if index != 1 else 0.6))
	# Foreground is genuinely in front of the z=0 combat plane. Short tufts at
	# the deck lip give parallax without masking bodies or introducing collision.
	for x in [2.2, 8.4, 10.8, 24.1]:
		for index in range(7):
			var blade := SurfaceTool.new()
			blade.begin(Mesh.PRIMITIVE_TRIANGLES)
			var height := 0.19 + float(index % 3) * 0.085
			GEOMETRY.face(blade, [Vector3(-0.045, 0, 0), Vector3(0.045, 0, 0),
				Vector3((index % 3 - 1) * 0.09, height, -0.045)], Vector3(0, 0, 1))
			append(blade.commit(), Vector3(x + (index - 3) * 0.09, 0.015, 2.5 + (index % 2) * 0.15),
				Color(0.40, 0.49, 0.28) if index % 2 == 0 else Color(0.54, 0.59, 0.34), true, Vector3.ZERO)
		for index in range(2):
			var stone := SphereMesh.new()
			stone.radius = 0.12 + index * 0.05
			stone.height = 0.13 + index * 0.04
			stone.radial_segments = 7
			stone.rings = 3
			append(stone, Vector3(x + 0.42 + index * 0.24, 0.06, 2.55), STEEL, false, Vector3(0, index, 0))

func pool_light(at: Vector3, target: Vector3, color: Color, energy: float) -> void:
	# Two localized practical lights; the sun remains the only shadow-map light.
	var light := SpotLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.spot_range = 7.0
	light.spot_angle = 52.0
	light.spot_attenuation = 0.7
	light.shadow_enabled = false
	add_child(light)
	light.look_at(to_global(target), Vector3.UP)

func service_wall(x: float, unit: String) -> void:
	# Printed marks have no hull outline or extra shadow. Relief is reserved
	# for the actual equipment so fine ink does not turn into heavy black bars.
	var wall := MeshInstance3D.new()
	var face := QuadMesh.new()
	face.size = Vector2(6.92, 3.92)
	wall.mesh = face
	wall.position = Vector3(x, 0.5, -5.97)
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/comic_wall.gdshader")
	wall.material_override = paint
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wall)
	# One inset louver and one maintenance hatch, separated by quiet red paint.
	box(Vector3(x - 0.35, 1.05, -5.91), Vector3(1.65, 1.12, 0.12), CREAM)
	box(Vector3(x - 0.35, 1.05, -5.82), Vector3(1.43, 0.91, 0.08), SILVER)
	for row in range(5):
		box(Vector3(x - 0.35, 0.70 + row * 0.175, -5.72), Vector3(1.32, 0.055, 0.18), STEEL)
	box(Vector3(x + 1.95, 0.65, -5.9), Vector3(1.23, 1.65, 0.14), SILVER)
	box(Vector3(x + 1.95, 0.65, -5.8), Vector3(1.10, 1.51, 0.09), TEAL)
	box(Vector3(x + 2.30, 0.64, -5.69), Vector3(0.075, 0.32, 0.11), CREAM)
	for y in [0.16, 1.14]:
		box(Vector3(x + 1.42, y, -5.72), Vector3(0.15, 0.12, 0.08), STEEL)
	# Short exposed conduit with clamps, deliberately away from the central lane.
	cylinder(Vector3(x + 2.89, 0.7, -5.75), 0.045, 2.5, STEEL)
	for y in [-0.25, 1.55]:
		box(Vector3(x + 2.89, y, -5.69), Vector3(0.18, 0.075, 0.09), CREAM)
	# Painted stencils: two large identifiers, no paragraphs of tiny signage.
	label(unit, Vector3(x - 1.73, 1.27, -5.88), 64, CREAM)
	for row in range(3):
		print_mark(Vector3(x - 1.70, 0.63 - row * 0.13, -5.89), Vector2(0.66 - row * 0.12, 0.035), CREAM)
	print_mark(Vector3(x + 1.95, 1.14, -5.73), Vector2(0.54, 0.12), YELLOW)
	# Roof joints and fan spokes make the HVAC units read as working equipment.
	for offset in ([-1.7, 1.7] if x < 16 else [-1.7]):
		box(Vector3(x + offset, 3.61, -8), Vector3(0.48, 0.025, 0.045), CREAM)
		# The batched mesh transform supplies rotation around the fan's vertical axis.
		append(GEOMETRY.bevel_box(Vector3(0.48, 0.025, 0.045)), Vector3(x + offset, 3.61, -8), CREAM, false, Vector3(0, PI * 0.5, 0))
		cylinder(Vector3(x + offset, 3.64, -8), 0.075, 0.045, STEEL)
		for row in range(3):
			print_mark(Vector3(x + offset, 3.02 + row * 0.12, -7.289), Vector2(0.65, 0.035), SILVER)
	for offset in [-2.5, 0.0, 2.5]:
		box(Vector3(x + offset, 2.78, -8), Vector3(0.045, 0.025, 3.1), STEEL)

func print_mark(at: Vector3, dimensions: Vector2, color: Color) -> void:
	var quad := QuadMesh.new()
	quad.size = dimensions
	append(quad, at, color, true, Vector3.ZERO)

func material(color: Color, glow: bool = false) -> Material:
	var key := str(color) + str(glow)
	if not materials.has(key):
		var value: Material
		if glow:
			var flat := StandardMaterial3D.new()
			flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			flat.albedo_color = color
			value = flat
		else:
			var cel := ShaderMaterial.new()
			cel.shader = preload("res://shaders/toon_environment.gdshader")
			cel.set_shader_parameter("paint", color)
			var outline := ShaderMaterial.new()
			outline.shader = preload("res://shaders/anime_outline.gdshader")
			outline.set_shader_parameter("width", 0.018)
			cel.next_pass = outline
			value = cel
		materials[key] = value
	return materials[key]

func append(mesh: Mesh, at: Vector3, color: Color, glow: bool, rotation: Vector3) -> void:
	var value := material(color, glow)
	if not batches.has(value):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[value] = surface
	var transform := Transform3D(Basis.from_euler(rotation), at)
	batches[value].append_from(mesh, 0, transform)

func box(at: Vector3, dimensions: Vector3, color: Color, glow: bool = false, angle: float = 0.0) -> void:
	append(GEOMETRY.bevel_box(dimensions, 0.035), at, color, glow, Vector3(0, 0, deg_to_rad(angle)))

func cylinder(at: Vector3, radius: float, height: float, color: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	append(mesh, at, color, false, rotation * PI / 180.0)

func build_batches() -> void:
	for value in batches:
		var visual := MeshInstance3D.new()
		visual.mesh = batches[value].commit()
		visual.material_override = value
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if value is ShaderMaterial else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)
	batches.clear()

func prop(scene: PackedScene, at: Vector3, height: float, color: Color = Color.TRANSPARENT, yaw_degrees: float = 0.0) -> void:
	var value: Node3D = scene.instantiate()
	add_child(value)
	var bounds := AABB()
	var first := true
	for visual: MeshInstance3D in value.find_children("*", "MeshInstance3D", true, false):
		if visual.mesh == null:
			continue
		var local_bounds: AABB = (value.global_transform.affine_inverse() * visual.global_transform) * visual.mesh.get_aabb()
		bounds = local_bounds if first else bounds.merge(local_bounds)
		first = false
		if color != Color.TRANSPARENT:
			visual.material_override = material(color)
		else:
			for surface in range(visual.mesh.get_surface_count()):
				var original := visual.get_active_material(surface)
				if original is StandardMaterial3D:
					var lit: StandardMaterial3D = original.duplicate()
					lit.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					lit.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
					lit.roughness = 0.7
					visual.set_surface_override_material(surface, lit)
	if first or bounds.size.y < 0.001:
		value.queue_free()
		return
	var factor := height / bounds.size.y
	value.scale = Vector3.ONE * factor
	value.rotation.y = deg_to_rad(yaw_degrees)
	value.position = at - value.basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor

func label(text: String, at: Vector3, size: int, color: Color) -> void:
	var sign := Label3D.new()
	sign.text = text
	sign.font = FONT
	sign.font_size = size
	sign.pixel_size = 0.012
	sign.position = at
	sign.modulate = color
	sign.outline_size = 0
	add_child(sign)

func fit_skyline() -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var view_height: float = backdrop_camera.size
	var view_width: float = view_height * view_size.x / maxf(1.0, view_size.y)
	# Fill both axes rather than letterboxing wide active panels. The complete
	# panorama remains visible; a small bleed prevents exposed edges on resizing.
	skyline_mesh.size = Vector2(view_width, view_height) * 1.16
	# Distant city drifts less than the stage; pointer tilt adds a small second layer.
	var drift: float = clampf((backdrop_camera.target.position.x - 16.0) * 0.025, -0.45, 0.45)
	skyline.position.x = -drift - backdrop_camera.mouse_tilt.x * 0.18
	skyline.position.y = -backdrop_camera.mouse_tilt.y * 0.10
