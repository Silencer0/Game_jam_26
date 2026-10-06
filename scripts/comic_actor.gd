extends Node3D
## Original ember sprites, animated on each arena's local clock.
## Entries: sheet, row, first column, frame count, loop.

@export_enum("Player", "Grunt", "Gunner") var identity: int = 1
const CELL := 128
const COLS := 4
const SHEETS := {
	"movement": preload("res://assets/characters/ember/movement.png"),
	"combat": preload("res://assets/characters/ember/combat.png"),
	"grunt": preload("res://assets/characters/ember/grunt.png"),
	"gunner": preload("res://assets/characters/ember/gunner.png"),
}
const ROWS := {"movement": 8, "combat": 6, "grunt": 6, "gunner": 6}
## Measured idle body height and foot baseline in each normalized sheet.
const ALIGNMENT := {
	"movement": Vector2i(118, 122), "combat": Vector2i(90, 121),
	"grunt": Vector2i(107, 120), "gunner": Vector2i(113, 128),
}
const PLAYER_ANIMATIONS := {
	"idle": ["movement", 0, 0, 4, true],
	"run": ["movement", 1, 0, 4, true],
	"jump_start": ["movement", 2, 0, 2, false],
	"jump_on_air": ["movement", 2, 2, 1, false],
	"jump_fall": ["movement", 2, 3, 1, false],
	"dash": ["movement", 3, 0, 4, false],
	"parry": ["movement", 4, 0, 2, false],
	"parry_hit": ["movement", 4, 2, 2, false],
	"hurt": ["movement", 5, 0, 4, false],
	"death": ["movement", 6, 0, 4, false],
	"attack": ["combat", 0, 0, 4, false],
	"attack_2": ["combat", 1, 0, 4, false],
	"attack_3": ["combat", 2, 0, 4, false],
	"air_light": ["combat", 3, 0, 4, false],
	"launcher": ["combat", 4, 0, 4, false],
	"air_finisher": ["combat", 5, 0, 4, false],
}
const ENEMY_ROWS := {"idle": 0, "run": 1, "attack": 2, "shoot": 2, "hurt": 3, "launched": 4, "death": 5}

var actor: CharacterBody3D
var sprite: Sprite3D
var ground_shadow: MeshInstance3D
var shadow_material: ShaderMaterial
var health_fill: MeshInstance3D
var current_animation := ""
var animation_time := 0.0
var ascent_time := 0.0
var last_velocity_y := 0.0
var attack_visual_left := 0.0
var last_enemy_shots := 0

func _ready() -> void:
	actor = get_parent() as CharacterBody3D
	sprite = Sprite3D.new()
	sprite.name = "AnimatedSprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.hframes = COLS
	add_child(sprite)
	ground_shadow = MeshInstance3D.new()
	ground_shadow.name = "GroundShadow"
	var shadow_mesh := QuadMesh.new()
	shadow_mesh.size = Vector2(1.25, 0.58)
	ground_shadow.mesh = shadow_mesh
	ground_shadow.rotation.x = -PI * 0.5
	shadow_material = ShaderMaterial.new()
	shadow_material.shader = preload("res://shaders/character_shadow.gdshader")
	ground_shadow.material_override = shadow_material
	ground_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	actor.add_child.call_deferred(ground_shadow)
	set_animation("idle")
	if identity != 0 and actor.has_signal("defeated"):
		actor.get_node("Readout").visible = false
		if actor.temporal_id > 0:
			var identity_label := Label3D.new()
			identity_label.text = "#%02d" % actor.temporal_id
			identity_label.font_size = 24
			identity_label.pixel_size = 0.012
			identity_label.position.y = 1.3
			identity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			identity_label.outline_size = 6
			add_child(identity_label)
		health_fill = MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.6, 0.035, 0.03)
		health_fill.mesh = bar
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.95, 0.35, 0.18) if identity == 1 else Color(0.6, 0.9, 0.3)
		health_fill.material_override = material
		health_fill.position = Vector3(0, 1.1, 0)
		add_child(health_fill)

func animation_data(name: String) -> Array:
	if identity == 0:
		return PLAYER_ANIMATIONS[name]
	return ["gunner" if identity == 2 else "grunt", ENEMY_ROWS[name], 0, 4, name in ["idle", "run"]]

func set_animation(name: String) -> void:
	if name == current_animation:
		return
	current_animation = name
	animation_time = 0.0
	var data: Array = animation_data(name)
	var sheet: String = data[0]
	sprite.frame = 0
	sprite.texture = SHEETS[sheet]
	sprite.vframes = ROWS[sheet]
	var layout: Vector2i = ALIGNMENT[sheet]
	sprite.pixel_size = (1.4 if identity == 0 else 1.6) / float(layout.x)
	# CharacterBody origin is the collider center, not its feet.
	sprite.position.y = float(layout.y - CELL / 2) * sprite.pixel_size - (0.52 if identity == 0 else 0.75)
	sprite.frame = int(data[1]) * COLS + int(data[2])

func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	if actor.get("hit_stopped") == true:
		delta = 0.0
	else:
		delta *= float(actor.get("simulation_rate"))
	animation_time += delta
	attack_visual_left = maxf(0.0, attack_visual_left - delta)
	if not actor.is_on_floor() and actor.velocity.y > 0.0:
		if actor.velocity.y > last_velocity_y + 2.0:
			ascent_time = 0.0
		ascent_time += delta
	else:
		ascent_time = 0.0
	last_velocity_y = actor.velocity.y
	if identity != 0:
		var trainer: Node3D = actor.get_node("Trainer")
		if trainer.active_left > 0.0:
			attack_visual_left = 0.18
		if identity == 2 and trainer.shots_fired != last_enemy_shots:
			last_enemy_shots = trainer.shots_fired
			attack_visual_left = 0.18
	set_animation(choose_animation())
	var data: Array = animation_data(current_animation)
	var count: int = int(data[3])
	var fps := 12.0 if current_animation != "idle" else 6.0
	if current_animation == "hurt":
		fps = 32.0
	elif current_animation == "death":
		fps = 8.0
	var index := int(animation_time * fps)
	if data[4]:
		index %= count
	if identity == 0:
		var melee: Node3D = actor.get_node("Melee")
		if melee.attacking and current_animation in ["attack", "attack_2", "attack_3", "air_light", "launcher", "air_finisher"]:
			var duration: float = melee.startup_time() + melee.active_time() + melee.recovery_time()
			index = int(float(melee.attack_elapsed) / maxf(duration, 0.01) * count)
		elif current_animation == "dash":
			index = int((1.0 - actor.dash_time_left / actor.dash_duration) * count)
		sprite.flip_h = int(actor.get("facing_direction")) < 0
	else:
		var trainer: Node3D = actor.get_node("Trainer")
		if current_animation in ["attack", "shoot"] and trainer.windup_left > 0.0:
			index = 0 if trainer.windup_left > 0.16 else 1
		elif current_animation in ["attack", "shoot"]:
			index = 2 if trainer.active_left > 0.0 or attack_visual_left > 0.08 else 3
		var direction: float = float(trainer.strike_direction) if trainer.windup_left > 0.0 or attack_visual_left > 0.0 else signf(trainer.player.global_position.x - actor.global_position.x)
		if direction != 0.0:
			sprite.flip_h = direction < 0.0
	sprite.frame = int(data[1]) * COLS + int(data[2]) + clampi(index, 0, count - 1)
	if is_instance_valid(health_fill):
		health_fill.scale.x = maxf(0.01, float(actor.get("health")) / float(actor.get("max_health")))

func choose_animation() -> String:
	if actor.get("dead") == true:
		return "death"
	if identity == 0:
		if float(actor.get("damage_flash_left")) > 0.48:
			return "hurt"
		var parry: Node3D = actor.get_node("Parry")
		if parry.success_visual_left > 0.0:
			return "parry_hit"
		if parry.window_left > 0.0:
			return "parry"
		var melee: Node3D = actor.get_node("Melee")
		if melee.attacking:
			if melee.attack_kind != &"ground_light":
				return String(melee.attack_kind)
			return ["attack", "attack_2", "attack_3"][mini(melee.combo_index, 2)]
		if float(actor.get("dash_time_left")) > 0.0:
			return "dash"
	else:
		if float(actor.get("feedback_time_left")) > 0.0:
			return "hurt"
		if not actor.is_on_floor():
			return "launched"
		var trainer: Node3D = actor.get_node("Trainer")
		if trainer.windup_left > 0.0 or attack_visual_left > 0.0:
			return "shoot" if identity == 2 else "attack"
	if not actor.is_on_floor():
		if actor.velocity.y > 0.0:
			return "jump_start" if ascent_time < 0.16 else "jump_on_air"
		return "jump_fall"
	return "run" if absf(actor.velocity.x) > 0.35 else "idle"

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(actor) or not ground_shadow.is_inside_tree():
		return
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3(0, 0.1, 0), actor.global_position - Vector3(0, 30, 0), 1)
	var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
	ground_shadow.visible = not hit.is_empty() and actor.visible
	if hit.is_empty():
		return
	ground_shadow.global_position = hit.position + Vector3(0, 0.018, 0.12)
	var elevation: float = maxf(0.0, actor.global_position.y - hit.position.y - (0.52 if identity == 0 else 0.75))
	var spread: float = 1.0 + minf(elevation, 5.0) * 0.09
	ground_shadow.scale = Vector3(spread, spread, spread)
	shadow_material.set_shader_parameter("opacity", 0.48 / (1.0 + elevation * 0.22))
