extends Node3D
## Bounded hit numbers and impact typography; presentation never changes damage.

const FONT = preload("res://assets/kenney/fonts/KenneyFuture.ttf")
var burst: Sprite3D
var burst_left: float = 0.0
var caption: Label3D
var remaining: float = 0.0
var previous_hits: Dictionary = {}
const NUMBER_LIMIT := 24
var numbers: Array[Dictionary] = []
var number_cursor: int = 0
var damage_history: Array[int] = []
var previous_parries: int = 0
var arena: Node3D

func _ready() -> void:
	arena = get_parent()
	burst = preload("res://scripts/comic_effect_sprite.gd").new()
	burst.pixel_size = 0.019
	burst.visible = false
	add_child(burst)
	arena.get_node("Player").damage_taken.connect(func():
		show_burst(3, arena.player.position + Vector3(0, 0.4, 0.5))
		show_hit("KRAK!", arena.player.position + Vector3(0, 1.4, 0.4), Color(1, 0.35, 0.25)))
	caption = Label3D.new()
	caption.font = FONT
	caption.font_size = 74
	caption.pixel_size = 0.012
	caption.outline_size = 16
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.visible = false
	add_child(caption)
	for _i in range(NUMBER_LIMIT):
		var number := Label3D.new()
		number.font = FONT
		number.font_size = 86
		number.pixel_size = 0.012
		number.outline_size = 15
		number.outline_modulate = Color(0.03, 0.025, 0.045)
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.no_depth_test = true
		number.visible = false
		add_child(number)
		numbers.append({"label": number, "age": 1.0, "at": Vector3.ZERO, "direction": 1.0})

func track_enemy(enemy: CharacterBody3D) -> void:
	if enemy.has_signal("damage_received"):
		enemy.damage_received.connect(show_damage.bind(enemy))

func show_damage(amount: int, kind: StringName, enemy: CharacterBody3D) -> void:
	damage_history.append(amount)
	if damage_history.size() > 64:
		damage_history.pop_front()
	var entry: Dictionary = numbers[number_cursor]
	number_cursor = (number_cursor + 1) % NUMBER_LIMIT
	entry.age = 0.0
	entry.at = enemy.position + Vector3(0, 1.2, 0.35)
	entry.direction = 1.0 if number_cursor % 2 else -1.0
	entry.label.text = str(amount)
	entry.label.modulate = Color(0.82, 0.56, 1.0) if kind == &"reflected_shot" else Color(1, 0.9, 0.35)
	entry.label.position = entry.at
	entry.label.visible = true
	entry.label.scale = Vector3.ONE * 1.4

func _process(delta: float) -> void:
	for entry in numbers:
		entry.age += delta
		var t: float = entry.age / 0.68
		entry.label.visible = t < 1.0
		if t < 1.0:
			entry.label.position = entry.at + Vector3(entry.direction * t * 0.28, t * 0.8, 0)
			entry.label.scale = Vector3.ONE * (1.0 + 0.4 * exp(-t * 12))
			entry.label.modulate.a = 1.0 - smoothstep(0.55, 1.0, t)
	# Impact bursts use real time so inactive panels do not hold flash frames.
	burst_left = maxf(0.0, burst_left - delta)
	burst.visible = burst_left > 0.0
	if burst.visible:
		burst.frame = burst.effect_row * 4 + mini(3, int((0.22 - burst_left) / 0.055))
	delta *= arena.simulation_rate
	remaining = maxf(0.0, remaining - delta)
	caption.visible = remaining > 0.0
	if remaining > 0.0:
		caption.position.y += delta * 1.2
		caption.modulate.a = minf(1.0, remaining * 6.0)
	var live: Dictionary = {}
	for enemy in arena.enemies.get_children():
		var id: int = enemy.get_instance_id()
		live[id] = enemy.hit_count
		if not enemy.has_signal("damage_received") and enemy.hit_count > int(previous_hits.get(id, 0)):
			show_hit("WHAM!" if enemy.slamming else "HIT!", enemy.position + Vector3(0, 1.5, 0.3), Color(1, 0.87, 0.3))
	previous_hits = live
	if arena.player.parry.successes > previous_parries:
		show_burst(2, arena.player.position + Vector3(float(arena.player.facing_direction) * 0.6, 0.4, 0.5))
	previous_parries = arena.player.parry.successes

func show_hit(words: String, at: Vector3, color: Color) -> void:
	caption.text = words
	caption.position = at
	caption.modulate = color
	caption.visible = true
	remaining = 0.28

func show_burst(row: int, at: Vector3) -> void:
	burst.effect_row = row
	burst.frame = row * 4
	burst.position = at
	burst_left = 0.22
	burst.visible = true
