extends Node
## Hold to purchase fixed-duration local slowdowns with whole MULT charges.
signal converged
const DRAIN_RATE := 0.65
const HOLD_SECONDS := 1.0 / DRAIN_RATE
const ENVIRONMENT_FLOW := 0.30
const BURST_SECONDS := 5.0
const GAP_PER_UNIT := 1.0
var session: Control
var active: bool:
	get:
		return not bursts.is_empty()
var charging := false
var panel_index := -1
var gap_index := -1
var charge_elapsed := 0.0
var input_blocked := false
var activations := 0
var spent_total := 0.0
var bursts: Dictionary = {}

func remaining_for(index: int) -> float:
	return float(bursts.get(index, 0.0))

func begin() -> bool:
	# The base x1 remains; each filled diamond above it is one spendable charge.
	if session.result != &"fighting" or charging or input_blocked or get_tree().paused or session.health <= 0 or session.multiplier < 2.0 - 0.00001:
		return false
	var rank: int = session.ROLE_NAMES.find(session.panels[session.active_index].arena.temporal_role)
	if rank == 1:
		return false
	var gap := 0 if rank == 0 else 1
	if session.gaps[gap] <= 0.0:
		return false
	panel_index = session.active_index
	gap_index = gap
	charging = true
	charge_elapsed = 0.0
	return true

func stop(block_held_input: bool = false) -> void:
	# Cancel an unfinished purchase. Purchased seconds remain in that arena.
	charging = false
	charge_elapsed = 0.0
	panel_index = -1
	gap_index = -1
	if block_held_input:
		input_blocked = true

func reset(block_held_input: bool = false) -> void:
	if active:
		Sfx.play_cue(&"dilate_end")
	stop(block_held_input)
	bursts.clear()
	if is_instance_valid(session):
		session.update_simulation_rates()

func advance_bursts(delta: float) -> void:
	var expired := false
	for index: int in bursts.keys():
		bursts[index] = maxf(0.0, float(bursts[index]) - delta)
		if bursts[index] <= 0.00001:
			bursts.erase(index)
			expired = true
	if expired:
		Sfx.play_cue(&"dilate_end")
		session.update_simulation_rates()

func step(delta: float) -> void:
	if get_tree().paused:
		return
	if session.health <= 0 or session.result != &"fighting":
		reset(true)
		return
	var left := maxf(0.0, delta)
	while left > 0.000001:
		if charging and (session.active_index != panel_index or session.multiplier < 2.0 - 0.00001 or session.gaps[gap_index] <= 0.0):
			stop(true)
		if not charging:
			advance_bursts(left)
			return
		# Split at purchase boundaries, so large and small physics steps agree.
		var slice := minf(left, maxf(0.0, HOLD_SECONDS - charge_elapsed))
		advance_bursts(slice)
		left -= slice
		charge_elapsed += slice
		if charge_elapsed + 0.000001 < HOLD_SECONDS:
			continue
		charge_elapsed = 0.0
		session.multiplier = maxf(1.0, session.multiplier - 1.0)
		session.gaps[gap_index] = maxf(0.0, session.gaps[gap_index] - GAP_PER_UNIT)
		bursts[panel_index] = remaining_for(panel_index) + BURST_SECONDS
		spent_total += 1.0
		activations += 1
		Sfx.play_cue(&"dilate_start")
		session.update_simulation_rates()
		if session.gaps[0] <= 0.0 and session.gaps[1] <= 0.0:
			stop(true)
			converged.emit()
			return
		if session.multiplier < 2.0 - 0.00001 or session.gaps[gap_index] <= 0.0:
			stop(true)

func handle_input(delta: float) -> void:
	if not Input.is_action_pressed("dilate"):
		input_blocked = false
		if charging:
			stop()
	elif not get_tree().paused and not charging and Input.is_action_just_pressed("dilate"):
		begin()
	step(delta)
