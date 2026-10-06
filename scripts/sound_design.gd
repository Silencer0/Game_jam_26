extends Node
## Short, event-triggered cues. A fixed pool and throttles keep three arenas readable.
const VOICES := 24
# file, level dB, priority, global cooldown ms. All samples are peak-balanced.
const CUES := {
	&"ui_hover": ["ui_hover", -20.0, 3, 90], &"ui_click": ["ui_click", -12.0, 3, 45],
	&"pause_open": ["pause_open", -10.0, 3, 80], &"pause_close": ["pause_close", -10.0, 3, 80],
	&"ui_error": ["ui_error", -10.0, 3, 180], &"drag_pickup": ["drag_pickup", -12.0, 3, 80],
	&"frame_shift": ["frame_shift", -8.0, 3, 80], &"panel_switch": ["panel_switch", -10.0, 3, 70],
	&"jump": ["double_jump", -12.0, 2, 35], &"double_jump": ["double_jump", -12.0, 2, 35],
	&"dash": ["dash", -10.0, 2, 35],
	&"footstep": ["footstep_1", -21.0, 0, 65], &"enemy_step": ["footstep_2", -26.0, 0, 120],
	&"landing": ["landing", -18.0, 1, 65],
	&"swing": ["swing_1", -12.0, 2, 30], &"swing_alt": ["swing_2", -12.0, 2, 30],
	&"heavy_swing": ["heavy_swing", -10.0, 2, 50],
	&"hit": ["hit", -9.0, 2, 28], &"heavy_hit": ["heavy_hit", -8.0, 2, 40],
	&"slam": ["slam", -9.0, 2, 60],
	&"parry_start": ["parry_start", -14.0, 2, 60], &"parry_success": ["parry_success", -6.0, 3, 55],
	&"enemy_windup": ["enemy_windup", -23.0, 1, 180],
	&"enemy_swing": ["enemy_swing", -15.0, 1, 65], &"enemy_shot": ["enemy_shot", -13.0, 2, 65],
	&"hurt": ["hurt", -7.0, 3, 45], &"enemy_death": ["enemy_death", -13.0, 2, 75],
	&"add_collect": ["add_collect", -18.0, 1, 80], &"add_ready": ["add_ready", -12.0, 2, 180],
	&"mult_collect": ["mult_collect", -15.0, 1, 80], &"mult_ready": ["mult_ready", -9.0, 3, 180],
	&"dilate_start": ["dilate_start", -10.0, 3, 100], &"dilate_end": ["dilate_end", -14.0, 2, 100],
	&"wave_start": ["wave_start", -13.0, 2, 150], &"wave_clear": ["wave_clear", -12.0, 2, 150],
	&"defeat": ["defeat", -8.0, 3, 300], &"victory": ["victory", -8.0, 3, 300],
	&"restart": ["restart", -12.0, 3, 100]
}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}
var history: Array[StringName] = []
var played_counts: Dictionary = {}
var was_paused := false

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Combat", "Interface"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	# Catch layered transient peaks without distorting ordinary single hits.
	var master := AudioEffectLimiter.new()
	master.threshold_db = -1.0
	AudioServer.add_bus_effect(0, master)
	for name in CUES:
		streams[name] = load("res://assets/audio/%s.ogg" % CUES[name][0])
	for _i in range(VOICES):
		var voice := AudioStreamPlayer.new()
		voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(voice)
		voices.append(voice)
	get_tree().node_added.connect(hook_button)

func hook_button(node: Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(func():
			if node.is_visible_in_tree() and not node.disabled:
				play_cue(&"ui_hover"))
		node.focus_entered.connect(func(): play_cue(&"ui_hover"))
		node.pressed.connect(func(): play_cue(&"ui_click"))

func arena_for(source: Node) -> Node:
	var node := source
	while is_instance_valid(node):
		if node.has_method("add_enemy") and node.get_node_or_null("Player") != null:
			return node
		node = node.get_parent()
	return null

func source_gain(source: Node, cue: StringName) -> float:
	if source == null or cue == &"hurt":
		return 0.0
	var arena := arena_for(source)
	if arena != null and arena.player.health_owner != null:
		if arena.panel_index != arena.player.health_owner.active_index:
			return -18.0
	return 0.0

func play_cue(cue: StringName, source: Node = null, pitch: float = 1.0) -> bool:
	if not CUES.has(cue):
		return false
	var interface: bool = cue.begins_with("ui_") or cue in [&"pause_open", &"pause_close", &"drag_pickup", &"frame_shift", &"panel_switch", &"restart", &"mult_collect", &"mult_ready", &"add_collect", &"add_ready", &"victory", &"defeat"]
	if get_tree().paused and not interface:
		return false
	var now := Time.get_ticks_msec()
	var config: Array = CUES[cue]
	if now - int(last_played.get(cue, -10000)) < int(config[3]):
		return false
	var voice: AudioStreamPlayer = null
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		for candidate in voices:
			if int(candidate.get_meta("priority", 0)) <= int(config[2]):
				if voice == null or int(candidate.get_meta("priority", 0)) < int(voice.get_meta("priority", 0)):
					voice = candidate
	if voice == null or streams[cue] == null:
		return false
	voice.stop()
	voice.stream = streams[cue]
	voice.bus = "Interface" if interface else "Combat"
	voice.volume_db = float(config[1]) + source_gain(source, cue)
	var variation := randf_range(0.96, 1.04) if int(config[2]) < 3 else 1.0
	voice.pitch_scale = clampf(pitch * variation, 0.75, 1.3)
	voice.set_meta("priority", config[2])
	# Headless QA has no audio device; validate cue routing without starting a decoder.
	# Dummy audio cannot flush outstanding streaming playbacks during immediate quit.
	if DisplayServer.get_name() != "headless":
		voice.play()
	last_played[cue] = now
	played_counts[cue] = int(played_counts.get(cue, 0)) + 1
	history.append(cue)
	if history.size() > 128:
		history.pop_front()
	return true

func _process(_delta: float) -> void:
	if get_tree().paused and not was_paused:
		for voice in voices:
			if voice.bus == &"Combat":
				voice.stop()
	was_paused = get_tree().paused
