extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var ledger: Node = page.ledger
	var id: int = ledger.records.keys()[0]
	check(ledger.state_for(id, 2) == &"alive" and ledger.state_for(id, 1) == &"missing" and ledger.state_for(id, 0) == &"missing", "New identity exists only in Future")
	ledger.advance(0.58)
	check(ledger.state_for(id, 1) == &"missing", "Gap delays arrival in Present")
	ledger.advance(0.02)
	check(ledger.state_for(id, 1) == &"alive" and ledger.state_for(id, 0) == &"missing", "Future trickles to Present first")
	ledger.advance(0.6)
	check(ledger.state_for(id, 0) == &"alive", "Present trickles to Past after the second gap")
	for index in range(3):
		check(ledger.actor_for(id, index).temporal_id == id and ledger.actor_for(id, index).health == 6, "Copies share identity and retain independent health")
	ledger.actor_for(id, 2).receive_melee_hit(1, 1)
	check(ledger.actor_for(id, 1).health == 6, "Nonlethal health is independent across copies")
	ledger.actor_for(id, 1).receive_melee_hit(100, 1)
	check(ledger.state_for(id, 0) == &"alive" and ledger.state_for(id, 1) == &"dead" and ledger.state_for(id, 2) == &"dead", "Present death kills Future but preserves Past")
	check(page.panels[1].arena.enemies_alive == 0 and page.panels[2].arena.enemies_alive == 0, "Causal deaths update actual arena populations")
	ledger.actor_for(id, 0).receive_melee_hit(100, 1)
	check(ledger.state_for(id, 0) == &"dead", "Past death clears the remaining earliest copy")
	ledger.advance(50.0)
	check(ledger.state_for(id, 0) == &"dead" and ledger.state_for(id, 2) == &"dead", "Durable tombstones cannot resurrect")

	await fresh()
	id = populate()
	ledger = page.ledger
	ledger.actor_for(id, 2).receive_melee_hit(100, 1)
	check(ledger.state_for(id, 0) == &"alive" and ledger.state_for(id, 1) == &"alive", "Future death never erases earlier live copies")
	await fresh()
	ledger = page.ledger
	id = ledger.records.keys()[0]
	ledger.actor_for(id, 2).receive_melee_hit(100, 1)
	ledger.advance(12.0)
	check(ledger.state_for(id, 0) == &"alive" and ledger.state_for(id, 1) == &"alive" and ledger.state_for(id, 2) == &"dead", "Future death does not suppress unborn earlier copies")

	await fresh()
	ledger = page.ledger
	page.gaps.assign([0.0, 0.0])
	var gunner: int = ledger.spawn_identity(&"gunner")
	ledger.advance(0.0)
	for index in range(3):
		check(ledger.actor_for(gunner, index).get_script().resource_path.ends_with("ranged_enemy.gd") and absf(ledger.actor_for(gunner, index).position.z) < 0.001, "Trickle preserves gunner species and gameplay plane")
	page.set_paused(true)
	var time: float = ledger.chronal_time
	ledger.advance(100.0)
	check(ledger.chronal_time == time, "Pause freezes migration clocks")
	page.set_paused(false)
	while ledger.spawn_identity() > 0:
		pass
	check(ledger.live_count(2) == ledger.MAX_LIVE, "Future population is bounded")
	ledger.advance(0.0)
	check(ledger.live_count(0) <= ledger.MAX_LIVE and ledger.live_count(1) <= ledger.MAX_LIVE, "Forward copies respect each arena population bound")
	var damaged: CharacterBody3D = ledger.actor_for(gunner, 0)
	damaged.receive_melee_hit(100, 1)
	check(page.panels[0].arena.enemies_alive == 11 and page.panels[1].arena.enemies_alive == 11 and page.panels[2].arena.enemies_alive == 11, "One Past death consistently removes all three live copies")
	check(is_equal_approx(Engine.time_scale, 1.0), "Causal mechanics never change global time")
	finish("CAUSAL LIFECYCLE")
