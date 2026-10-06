extends "res://tests/causal_test_base.gd"

func clear_wave() -> void:
	page.ledger.advance(12.0)
	quiet()
	for id: int in page.ledger.wave_ids:
		for index in range(3):
			var actor: CharacterBody3D = page.ledger.actor_for(id, index)
			if is_instance_valid(actor) and not actor.dead:
				actor.receive_melee_hit(page.ledger.MAX_ENEMY_HEALTH, 1)
	page.ledger.spawning_enabled = true
	page.ledger.advance(0.0)

func run_checks() -> void:
	await fresh()
	var ledger: Node = page.ledger
	var id: int = ledger.wave_ids[0]
	check(ledger.wave == 1 and ledger.wave_remaining() == 1 and ledger.wave_queue.is_empty(), "Opening wave contains one complete Future-only cohort")
	page.select_panel(2)
	ledger.spawning_enabled = true
	ledger.advance(100.0)
	quiet()
	check(ledger.wave == 1 and ledger.next_id == 2, "Waiting never adds enemies continuously to an uncleared wave")
	ledger.actor_for(id, 2).receive_melee_hit(100, 1)
	ledger.advance(50.0)
	check(ledger.wave == 1 and ledger.wave_remaining() == 1, "Clearing Future cannot skip surviving earlier representations")
	ledger.actor_for(id, 1).receive_melee_hit(100, 1)
	ledger.advance(0.0)
	check(not ledger.wave_cleared, "A surviving Past representation still blocks wave completion")
	ledger.actor_for(id, 0).receive_melee_hit(100, 1)
	ledger.advance(0.0)
	check(ledger.wave_cleared and ledger.wave_remaining() == 0 and ledger.spawn_left == ledger.wave_delay(), "All copies cleared starts a fresh between-wave countdown")
	page.set_paused(true)
	ledger.advance(100.0)
	check(ledger.wave == 1 and ledger.spawn_left == ledger.wave_delay(), "Pause freezes both wave progression and its countdown")
	page.set_paused(false)
	page.select_panel(0)
	ledger.advance(0.1)
	check(absf(ledger.spawn_left - 0.5) < 0.001, "Inactive Future does not prolong the real-time wave countdown")
	page.select_panel(2)
	ledger.advance(0.4)
	check(ledger.wave == 1, "The intermission does not end before one tenth of the Future/Present gap")
	ledger.advance(0.1)
	quiet()
	check(ledger.wave == 2 and ledger.wave_ids.size() == 2 and ledger.wave_remaining() == 2, "Next wave spawns its complete two-grunt cohort")
	check(ledger.wave_profile.starting_add == 4 and ledger.wave_profile.max_health == 35, "Wave two snapshots earned ADD and applies compounded HP growth")
	for next: int in ledger.wave_ids:
		check(ledger.state_for(next, 2) == &"alive" and ledger.state_for(next, 1) == &"missing", "Every new wave identity is born only in current Future")
		check(ledger.actor_for(next, 2).health == 35 and ledger.actor_for(next, 2).wave_number == 2, "Real wave bodies receive scaled health and wave identity before ready")
	var later: int = ledger.wave_ids[0]
	var hp: int = ledger.actor_for(later, 2).health
	page.addition += 20
	ledger.advance(12.0)
	quiet()
	check(ledger.actor_for(later, 0).health == hp and ledger.actor_for(later, 1).health == hp and ledger.actor_for(later, 2).health == hp, "Later arrivals retain immutable stats despite mid-wave ADD growth")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	page.set_paused(false)
	check(ledger.wave == 2 and ledger.wave_ids.size() == 2 and ledger.actor_for(later, 2).health == hp, "Reassigning temporal roles never resets wave or enemy stats")
	for expected in range(3, 11):
		await clear_wave()
		check(ledger.wave_remaining() == 0 and ledger.wave_cleared, "Wave %d fully clears before advancing" % ledger.wave)
		ledger.advance(100.0)
		quiet()
		check(ledger.wave == expected and ledger.wave_ids.size() == ledger.wave_species(expected).size(), "Wave %d advances exactly once and spawns the planned composition" % expected)
		check(ledger.wave_ids.size() <= ledger.MAX_WAVE_SIZE and ledger.live_count(ledger.panel_for_rank(2)) <= ledger.MAX_LIVE, "Wave %d stays within density and Web population bounds" % expected)
		await ticks(2)
	check(ledger.wave_species(3) == [&"gunner"] and ledger.wave_species(4) == [&"grunt", &"gunner"], "Opening ranged and mixed waves retain the accepted introduction")
	check(ledger.wave_profile.max_health > 500 and ledger.wave_profile.movement > 1.0 and ledger.wave_profile.recovery < 1.0, "Late waves are genuinely tougher, faster and more aggressive")
	var distinct: Dictionary = {}
	for next: int in ledger.wave_ids:
		distinct[ledger.records[next].origin.x] = true
	check(distinct.size() == ledger.wave_ids.size(), "Large cohorts spawn at distinct positions rather than stacking sprites")
	var prev: Dictionary = ledger.difficulty_profile(1, 10)
	for wave in range(2, 16):
		var profile: Dictionary = ledger.difficulty_profile(wave, 10)
		check(absf(float(profile.max_health) / prev.max_health - 1.45) < 0.02, "Fixed-ADD HP compounds by 45 percent in wave %d" % wave)
		prev = profile
	var extreme: Dictionary = ledger.difficulty_profile(100000, 1000000000)
	check(extreme.max_health == ledger.MAX_ENEMY_HEALTH and extreme.movement == 1.5 and extreme.projectile == 1.5 and extreme.recovery == 0.5 and extreme.windup == 0.7, "Extreme runs have finite HP and readable capped movement, shots and attack timing")
	page.result = &"defeat"
	var old_wave: int = ledger.wave
	ledger.advance(100.0)
	check(ledger.wave == old_wave, "Defeat cannot advance or spawn another wave")

	await fresh()
	ledger = page.ledger
	id = ledger.wave_ids[0]
	ledger.actor_for(id, 2).receive_melee_hit(100, 1)
	ledger.spawning_enabled = true
	ledger.advance(0.0)
	check(not ledger.wave_cleared and ledger.wave_remaining() == 1, "Dead Future still waits for unborn earlier copies rather than skipping the wave")
	ledger.advance(12.0)
	quiet()
	check(ledger.state_for(id, 0) == &"alive" and ledger.wave == 1, "Pending earlier survivors arrive even when the Future copy was killed")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	page.set_paused(false)
	ledger.advance(0.0)
	check(ledger.wave_cleared and page.contradiction_kills == 2, "Genuine contradictions clear the cohort and retain MULT rewards")
	ledger.advance(100.0)
	quiet()
	check(ledger.wave == 2 and ledger.actor_for(ledger.wave_ids[0], 0).wave_number == 2 and ledger.state_for(ledger.wave_ids[0], 2) == &"missing", "After a role swap the next wave is born in the reassigned Future arena")

	await fresh()
	ledger = page.ledger
	var future: int = ledger.panel_for_rank(2)
	while ledger.live_count(future) < ledger.MAX_LIVE:
		ledger.spawn_identity()
	ledger.wave_queue.assign([&"grunt", &"gunner"])
	ledger.spawning_enabled = true
	ledger.advance(0.0)
	check(ledger.wave_queue.size() == 2 and not ledger.wave_cleared, "Capacity-blocked wave members remain queued and block clearance")
	ledger.actor_for(ledger.wave_ids[0], future).receive_melee_hit(100, 1)
	ledger.advance(0.0)
	quiet()
	check(ledger.wave_queue.size() == 1 and ledger.live_count(future) == ledger.MAX_LIVE, "Opening one slot retries exactly one queued wave member without exceeding cap")
	check(is_equal_approx(Engine.time_scale, 1.0), "Difficulty never changes the global or per-role time scales")
	finish("WAVE DIFFICULTY")
