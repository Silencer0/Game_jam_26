extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	page.gaps.assign([0.0, 0.0])
	var max_records := 0
	for cycle in range(65):
		var id: int = page.ledger.spawn_identity(&"gunner" if cycle % 4 == 0 else &"grunt")
		page.ledger.advance(0.0)
		quiet()
		if id > 0:
			page.ledger.actor_for(id, 0).receive_melee_hit(100, 1)
		max_records = maxi(max_records, page.ledger.records.size())
		# This checks ledger retirement; animation/physics lifetimes have separate tests.
		for panel in page.panels:
			for enemy in panel.arena.enemies.get_children():
				if enemy.dead:
					enemy.queue_free()
		await ticks(2)
	check(max_records <= page.ledger.ARCHIVE_LIMIT and page.ledger.next_id > 65, "Long encounters retain a bounded tombstone archive without reusing IDs")
	check(page.regular_kills == 65 and page.contradiction_kills == 0, "Long causal kill chains award exactly one ADD per direct kill")
	check(page.ledger.pending_count() == 1, "Retired identities do not consume the pending-spawn budget")

	await fresh()
	page.ledger.advance(12.0)
	quiet()
	# Fill Present; a Future-only survivor moved into Past must defer its new Present copy.
	for _i in range(11):
		var id: int = page.ledger.spawn_identity()
		page.ledger.create_copy(id, 1)
	var extra: int = page.ledger.records.keys()[-1]
	page.set_paused(true)
	# Fund this role-law fixture; exact spending is tested separately.
	if paused:
		page.addition += page.frame_shift_cost(2, &"Past")
	page.assign_panel_role(2, &"Past")
	page.set_paused(false)
	check(page.ledger.live_count(1) <= page.ledger.MAX_LIVE, "Role-swapped forward creation cannot exceed the arena live cap")
	# A missing later representation will be retried after capacity opens.
	var missing := -1
	for id: int in page.ledger.records:
		if page.ledger.state_for(id, 1) == &"missing":
			missing = id
	if missing >= 0:
		var victim: CharacterBody3D = page.panels[1].arena.enemies.get_child(0)
		victim.receive_melee_hit(100, 1)
		page.ledger.advance(0.0)
		check(page.ledger.state_for(missing, 1) == &"alive", "Capacity-delayed forward copy arrives when a slot opens")
	else:
		check(page.ledger.live_count(1) == page.ledger.MAX_LIVE, "Full Present retains its lawful existing copies")
	finish("CAUSAL BOUNDS")
