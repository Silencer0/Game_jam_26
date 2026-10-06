extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var id: int = populate()
	check(page.scaled_damage(1) == 1 and page.scaled_damage(2) == 2, "Initial ADD and MULT preserve base melee damage")
	page.ledger.actor_for(id, 1).receive_melee_hit(100, 1)
	check(page.addition == 2 and page.regular_kills == 1 and page.multiplier == 1.0, "One direct kill adds ADD; automatic Future death earns nothing")
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(1, &"Past")
	page.assign_panel_role(1, &"Past")
	check(page.panels[1].arena.temporal_role == &"Present", "Role swapping is rejected outside pause")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(1, &"Past")
	page.assign_panel_role(1, &"Past")
	check(page.ledger.state_for(id, 0) == &"dead" and page.contradiction_kills == 1 and page.multiplier == 2.0, "Moving a Present death to Past contradicts and kills the surviving copy")
	check(page.scaled_damage(1) == 4 and page.scaled_damage(2) == 8, "Damage scales with ADD × MULT and preserves heavy-hit weight")
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(1, &"Present")
	page.assign_panel_role(1, &"Present")
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(1, &"Past")
	page.assign_panel_role(1, &"Past")
	check(page.contradiction_kills == 1 and page.addition == 2, "Repeated swaps of tombstones cannot farm points")
	page.set_paused(false)

	await fresh()
	id = page.ledger.records.keys()[0]
	var actor: CharacterBody3D = page.ledger.actor_for(id, 2)
	var before := actor.position
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	check(page.ledger.state_for(id, 0) == &"alive" and page.ledger.state_for(id, 1) == &"alive", "Future-only survivor moved into Past creates copies in all later roles")
	check(actor.position == before and page.ledger.actor_for(id, 2) == actor, "Swaps preserve the original body and position")
	check(page.regular_kills == 0 and page.contradiction_kills == 0, "Creating missing representations earns no kill score")
	page.set_paused(false)

	await fresh()
	var ids: Array[int] = [populate()]
	for _i in range(3):
		ids.append(page.ledger.spawn_identity())
	page.ledger.advance(12.0)
	quiet()
	for enemy_id in ids:
		page.ledger.actor_for(enemy_id, 2).receive_melee_hit(100, 1)
	check(page.addition == 5 and page.multiplier == 1.0, "Future kills earn ADD without harming earlier instances")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	check(page.contradiction_kills == 8 and page.multiplier == page.MAX_MULT, "A dead Future moved to Past kills both later copies and fills bounded MULT")
	check(page.ledger.pending_count() == 0, "Fully contradicted identities have no phantom pending arrivals")
	page.set_paused(false)

	for first in range(3):
		for second in range(3):
			if first == second:
				continue
			await fresh()
			id = populate()
			page.ledger.actor_for(id, first).receive_melee_hit(100, 1)
			page.set_paused(true)
			# Fund this role-law fixture; exact spending is tested separately.
			if paused:
				page.addition += page.frame_shift_cost(first, page.ROLE_NAMES[second])
			page.assign_panel_role(first, page.ROLE_NAMES[second])
			var dead_seen := false
			var valid := true
			for rank in range(3):
				var state: StringName = page.ledger.state_for(id, page.ledger.panel_for_rank(rank))
				if state == &"dead":
					dead_seen = true
				if dead_seen and state == &"alive":
					valid = false
			check(valid, "Role permutation %d↔%d satisfies forward death laws" % [first, second])
			page.set_paused(false)
	await fresh()
	id = page.ledger.records.keys()[0]
	page.ledger.advance(0.2)
	var travel: float = page.ledger.records[id].travel
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(0, &"Present")
	page.assign_panel_role(0, &"Present")
	check(page.ledger.state_for(id, 2) == &"alive" and page.ledger.records[id].travel == travel and page.multiplier == 1.0, "An unrelated Future-only birth retains its clock and state when Past/Present swap")
	page.set_paused(false)
	page.ledger.advance(0.4)
	check(page.ledger.state_for(id, 0) == &"alive" and page.ledger.state_for(id, 1) == &"missing", "Pending arrival follows the new Present role after an unrelated swap")
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	page.set_paused(false)
	var born: int = page.ledger.spawn_identity()
	var future_index: int = page.ledger.panel_for_rank(2)
	check(page.ledger.records[born].states.size() == 1 and page.ledger.state_for(born, future_index) == &"alive", "New identities originate in the current Future after role reordering")
	check(is_equal_approx(Engine.time_scale, 1.0), "Swaps and scoring never change Engine.time_scale")
	finish("CAUSAL SWAP / SCORE")
