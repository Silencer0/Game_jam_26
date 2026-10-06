extends Node
## Three continuously running versions of the same musical timeline.
const ROLES: Array[StringName] = [&"Past", &"Present", &"Future"]
const LEVEL_DB := -10.0
const FADE_SECONDS := 0.22
var players: Array[AudioStreamPlayer] = []
var weights: Array[float] = [1.0, 0.0, 0.0]
var target_role: StringName = &"Past"
var running := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Music")
		AudioServer.set_bus_send(bus, "Master")
	for role in ROLES:
		var voice := AudioStreamPlayer.new()
		var track: AudioStreamOggVorbis = load("res://assets/audio/music/%s.ogg" % String(role).to_lower())
		track.loop = true
		track.loop_offset = 0.0
		voice.stream = track
		voice.bus = &"Music"
		voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		voice.volume_db = -80.0
		add_child(voice)
		players.append(voice)

func begin_run(role: StringName) -> void:
	target_role = role
	for i in range(players.size()):
		players[i].stop()
		players[i].stream_paused = false
		weights[i] = 1.0 if ROLES[i] == role else 0.0
		players[i].volume_db = LEVEL_DB if weights[i] > 0 else -80.0
		if DisplayServer.get_name() != "headless":
			players[i].play(0.0)
	running = true

func set_role(role: StringName) -> void:
	if role in ROLES:
		target_role = role

func transport_seconds() -> float:
	if players.is_empty() or not running:
		return 0.0
	# These players start on the same mix frame and never restart on role changes.
	return maxf(0.0, players[0].get_playback_position())

func _process(delta: float) -> void:
	if not running:
		return
	for i in range(players.size()):
		players[i].stream_paused = get_tree().paused
		weights[i] = move_toward(weights[i], 1.0 if ROLES[i] == target_role else 0.0, delta / FADE_SECONDS)
		players[i].volume_db = LEVEL_DB + linear_to_db(sqrt(weights[i])) if weights[i] > 0.0001 else -80.0

func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
