extends Node
## Stable enemy identities, independent copies, and durable death records.
signal copy_died(enemy_id: int, panel_index: int, cause: StringName)
signal changed
const MAX_LIVE := 12
const MAX_PENDING := 36
const ARCHIVE_LIMIT := 48
const GAP_DELAY_RATIO := 0.1
const MAX_WAVE_SIZE := 8
const MAX_ENEMY_HEALTH := 1_000_000_000
var session: Control
var records: Dictionary = {}
var next_id: int = 1
var spawn_left: float = 0.0
var spawning_enabled: bool = true
var chronal_time: float = 0.0
var wave: int = 0
var wave_ids: Array[int] = []
var wave_profile: Dictionary = {}
var wave_queue: Array[StringName] = []
var wave_cleared: bool = false

func setup(owner_session: Control, start_immediately: bool = true) -> void:
	session = owner_session
	spawning_enabled = start_immediately
	if start_immediately:
		start_wave()

func difficulty_profile(number: int, starting_add: int) -> Dictionary:
	# Snapshot once. Earning ADD/MULT never heals or toughens existing copies.
	var tier := maxi(0, number - 1)
	var health_factor := pow(1.45, mini(tier, 100))
	return {
		"wave": number,
		"starting_add": maxi(1, starting_add),
		"max_health": int(ceil(minf(float(MAX_ENEMY_HEALTH), 6.0 * maxi(1, starting_add) * health_factor))),
		"movement": minf(1.5, pow(1.08, mini(tier, 100))),
		"recovery": maxf(0.5, pow(1.1, -mini(tier, 100))),
		"windup": maxf(0.7, pow(1.04, -mini(tier, 100))),
		"projectile": minf(1.5, pow(1.05, mini(tier, 100)))
	}

func wave_species(number: int) -> Array[StringName]:
	if number == 1:
		return [&"grunt"]
	if number == 2:
		return [&"grunt", &"grunt"]
	if number == 3:
		return [&"gunner"]
	if number == 4:
		return [&"grunt", &"gunner"]
	var species: Array[StringName] = []
	var count := mini(MAX_WAVE_SIZE, number - 2)
	for index in range(count):
		species.append(&"gunner" if index % 3 == 2 else &"grunt")
	return species

func start_wave() -> void:
	wave += 1
	Sfx.play_cue(&"wave_start")
	wave_ids.clear()
	wave_profile = difficulty_profile(wave, session.addition)
	wave_queue = wave_species(wave)
	wave_cleared = false
	spawn_left = wave_delay()
	spawn_wave_members()

func spawn_wave_members() -> void:
	while not wave_queue.is_empty():
		var id := spawn_identity(wave_queue[0], wave_profile)
		if id < 0:
			break # Capacity pressure defers a member instead of losing it.
		wave_ids.append(id)
		wave_queue.pop_front()

func wave_remaining() -> int:
	var count := wave_queue.size()
	for id in wave_ids:
		if not records.has(id):
			continue # Only completely retired identities may leave the archive.
		var record: Dictionary = records[id]
		var remaining := false
		for rank in range(record.next_rank + 1):
			remaining = remaining or state_for(id, panel_for_rank(rank)) == &"missing"
		for state: Dictionary in record.states.values():
			remaining = remaining or state.status == &"alive"
		count += 1 if remaining else 0
	return count

func wave_status() -> String:
	if wave_cleared:
		return "WAVE %d CLEAR / NEXT IN %.1fs" % [wave, spawn_left]
	return "WAVE %d / %d LINKED" % [wave, wave_remaining()]

func advance_waves(delta: float) -> void:
	spawn_wave_members()
	if wave_remaining() > 0:
		return
	if not wave_cleared:
		wave_cleared = true
		Sfx.play_cue(&"wave_clear")
		spawn_left = wave_delay()
		return # Start the break after clearance, never before the final death.
	# Real seconds: an inactive Future must not stretch the intermission tenfold.
	spawn_left = maxf(0.0, minf(spawn_left, wave_delay()) - delta)
	if spawn_left <= 0.00001:
		start_wave()

func wave_delay() -> float:
	return maxf(0.0, session.gaps[1]) * GAP_DELAY_RATIO

func panel_for_rank(rank: int) -> int:
	for index in range(session.panels.size()):
		if session.panels[index].arena.temporal_role == session.ROLE_NAMES[rank]:
			return index
	return -1

func rank_of(index: int) -> int:
	return session.ROLE_NAMES.find(session.panels[index].arena.temporal_role)

func live_count(index: int) -> int:
	return session.panels[index].arena.enemies_alive

func pending_count() -> int:
	var count := 0
	for record: Dictionary in records.values():
		var live := false
		for state: Dictionary in record.states.values():
			live = live or state.status == &"alive"
		if live or record.next_rank >= 0:
			count += 1
	return count

func spawn_identity(species: StringName = &"grunt", profile: Dictionary = {}) -> int:
	var future: int = panel_for_rank(2)
	if future < 0 or live_count(future) >= MAX_LIVE or pending_count() >= MAX_PENDING or session.health <= 0 or session.result != &"fighting":
		return -1
	var id := next_id
	next_id += 1
	var arena: Node3D = session.panels[future].arena
	var side := 1.0 if id % 2 == 1 else -1.0
	var x: float = clampf(arena.player.position.x + side * 8.0, 2.0, 30.0)
	if absf(x - arena.player.position.x) < 4.0:
		x = clampf(arena.player.position.x - side * 8.0, 2.0, 30.0)
	x = spaced_spawn_x(arena, x)
	records[id] = {"id": id, "species": species, "origin": Vector3(x, 0.8, 0), "states": {}, "next_rank": 1, "travel": 0.0, "difficulty": profile.duplicate(true)}
	create_copy(id, future)
	prune_archive()
	return id

func spawn_clearance(arena: Node3D, x: float) -> float:
	var clearance: float = absf(x - arena.player.position.x) - 2.0
	for enemy in arena.enemies.get_children():
		if not enemy.dead:
			clearance = minf(clearance, absf(x - enemy.position.x))
	return clearance

func spaced_spawn_x(arena: Node3D, preferred: float) -> float:
	# Cohorts need distinct silhouettes instead of stacking at two birth points.
	if spawn_clearance(arena, preferred) >= 2.0:
		return preferred
	var best := preferred
	var best_score := -INF
	for candidate in range(2, 31, 2):
		var score: float = minf(2.0, spawn_clearance(arena, float(candidate))) - absf(candidate - preferred) * 0.01
		if score > best_score:
			best_score = score
			best = float(candidate)
	return best

func create_copy(id: int, index: int) -> bool:
	var record: Dictionary = records[id]
	if record.states.has(index) or live_count(index) >= MAX_LIVE:
		return false
	var arena: Node3D = session.panels[index].arena
	var at: Vector3 = record.origin
	if absf(at.x - arena.player.position.x) < 3.0:
		at.x = clampf(arena.player.position.x + (6.0 if arena.player.position.x < 16.0 else -6.0), 2.0, 30.0)
	var enemy: CharacterBody3D = arena.add_enemy(id, record.species, at, record.difficulty)
	record.states[index] = {"status": &"alive", "actor": weakref(enemy), "position": enemy.position, "cause": &""}
	changed.emit()
	return true

func actor_for(id: int, index: int) -> CharacterBody3D:
	if not records.has(id) or not records[id].states.has(index):
		return null
	var state: Dictionary = records[id].states[index]
	return state.actor.get_ref() as CharacterBody3D if state.has("actor") else null

func state_for(id: int, index: int) -> StringName:
	if not records.has(id) or not records[id].states.has(index):
		return &"missing"
	return records[id].states[index].status

func on_enemy_died(enemy: CharacterBody3D, index: int) -> void:
	var id: int = enemy.temporal_id
	if not records.has(id) or state_for(id, index) != &"alive":
		return
	mark_dead(id, index, enemy.death_cause, enemy.position)
	# Direct deaths erase every later representation, never earlier ones.
	for rank in range(rank_of(index) + 1, 3):
		kill_copy(id, panel_for_rank(rank), &"causal")

func mark_dead(id: int, index: int, cause: StringName, at: Vector3) -> void:
	var record: Dictionary = records[id]
	var state: Dictionary = record.states.get(index, {})
	state.status = &"dead"
	state.position = at
	state.cause = cause
	record.states[index] = state
	copy_died.emit(id, index, cause)
	changed.emit()

func kill_copy(id: int, index: int, cause: StringName) -> bool:
	if index < 0 or state_for(id, index) == &"dead":
		return false
	var enemy: CharacterBody3D = actor_for(id, index)
	var alive: bool = state_for(id, index) == &"alive"
	if alive and is_instance_valid(enemy):
		# Mark first so the synchronous defeated signal cannot recursively award.
		mark_dead(id, index, cause, enemy.position)
		enemy.die(cause)
	else:
		# Causal suppression is a tombstone, not an award for an unborn enemy.
		records[id].states[index] = {"status": &"dead", "position": records[id].origin, "cause": cause}
		changed.emit()
	return alive

func advance(delta: float) -> void:
	if get_tree().paused or session.health <= 0 or session.result != &"fighting":
		return
	chronal_time += delta
	for id: int in records.keys():
		var record: Dictionary = records[id]
		for rank in range(3):
			if state_for(id, panel_for_rank(rank)) != &"alive":
				continue
			for later in range(rank + 1, 3):
				if state_for(id, panel_for_rank(later)) == &"missing":
					create_copy(id, panel_for_rank(later))
		record.travel += delta
		while record.next_rank >= 0:
			var rank: int = record.next_rank
			var gap: float = session.gaps[rank] * GAP_DELAY_RATIO
			if record.travel + 0.00001 < gap:
				break
			var index := panel_for_rank(rank)
			if state_for(id, index) == &"missing" and not create_copy(id, index):
				break # A full arena delays arrival; it never discards the identity.
			record.travel = maxf(0.0, record.travel - gap)
			record.next_rank -= 1
	if spawning_enabled:
		advance_waves(delta)
	prune_archive()

func prune_archive() -> void:
	if records.size() <= ARCHIVE_LIMIT:
		return
	for id: int in records.keys():
		var record: Dictionary = records[id]
		var retired: bool = record.next_rank < 0
		for state: Dictionary in record.states.values():
			retired = retired and state.status == &"dead"
		if retired:
			records.erase(id)
		if records.size() <= ARCHIVE_LIMIT:
			break

func reconcile_swapped(swapped: Array[int]) -> int:
	var contradictions := 0
	for id: int in records.keys():
		var record: Dictionary = records[id]
		var affected := false
		for index in swapped:
			affected = affected or record.states.has(index)
		if not affected:
			continue
		var earliest_dead := 3
		var earliest_record := 3
		for index: int in record.states:
			var rank := rank_of(index)
			earliest_record = mini(earliest_record, rank)
			if record.states[index].status == &"dead":
				earliest_dead = mini(earliest_dead, rank)
		# Contradictions resolve before any creation: death can never resurrect.
		for rank in range(earliest_dead + 1, 3):
			if kill_copy(id, panel_for_rank(rank), &"contradiction"):
				contradictions += 1
		for rank in range(3):
			var index := panel_for_rank(rank)
			if state_for(id, index) != &"alive":
				continue
			for later in range(rank + 1, 3):
				if later < earliest_dead:
					create_copy(id, panel_for_rank(later))
		# Reordered histories may still trickle to earlier missing roles.
		record.next_rank = earliest_record - 1
		record.travel = 0.0
	changed.emit()
	return contradictions
