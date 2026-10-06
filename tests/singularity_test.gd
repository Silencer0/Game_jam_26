extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var survivor: int = populate()
	var doomed: int = page.ledger.spawn_identity()
	page.ledger.advance(12.0)
	quiet()
	page.ledger.actor_for(doomed, 2).receive_melee_hit(100, 1)
	page.gaps[0] = 0.0
	page.finish_singularity()
	check(page.result == &"fighting", "One closed gap is insufficient for singularity")
	page.select_panel(2)
	page.multiplier = page.MAX_MULT
	page.dilation.begin()
	page.dilation.step(10.0)
	check(page.gaps[1] == 3.0 and page.result == &"fighting", "A full meter closes three seconds and requires new charges for the rest")
	page.multiplier = page.MAX_MULT
	page.dilation.input_blocked = false
	page.dilation.begin()
	page.dilation.step(10.0)
	await ticks(2)
	check(page.result == &"singularity" and page.gaps[1] == 0.0, "Closing both gaps through dilation achieves singularity")
	var visible_count := 0
	var actor_count := 0
	for panel in page.panels:
		visible_count += 1 if panel.visible else 0
		actor_count += panel.arena.enemies.get_child_count()
	check(visible_count == 1 and page.panels[page.active_index].arena.temporal_role == &"Present", "Only the final Present panel remains visible")
	check(actor_count == 1 and page.panels[page.active_index].arena.enemies.get_child(0).temporal_id == survivor, "Merge deduplicates survivors and does not resurrect any dead identity")
	check(not page.ledger.spawning_enabled and not page.dilation.active, "Singularity stops births and dilation")
	var score: int = page.addition
	var clock: float = page.ledger.chronal_time
	var position: Vector3 = page.panels[page.active_index].arena.player.position
	key(KEY_D, true)
	await ticks(30)
	key(KEY_D, false)
	check(page.panels[page.active_index].arena.player.position == position and page.ledger.chronal_time == clock, "Final singular frame is stable and cannot resume combat or spawning")
	page.set_paused(true)
	page.assign_panel_role(0, &"Future")
	check(page.result == &"singularity" and page.addition == score, "Pause cannot twist or farm the completed timeline")
	page.set_paused(false)
	key(KEY_R, true)
	await ticks(3)
	key(KEY_R, false)
	page = current_scene
	page.set_physics_process(false)
	page.ledger.spawning_enabled = false
	quiet()
	check(page.result == &"fighting" and page.health == page.max_health and page.addition == 1 and page.multiplier == 1.0, "Restart resets result, health and scoring")
	check(page.gaps == [6.0, 6.0] and page.ledger.records.size() == 1 and page.ledger.next_id == 2 and not page.dilation.active, "Restart resets gaps, identities, migration and ultimate")
	visible_count = 0
	for panel in page.panels:
		visible_count += 1 if panel.visible else 0
	check(visible_count == 3 and page.panels[0].arena.player.input_enabled, "Restart restores three live panels and usable input")
	await fresh()
	var pending: int = page.ledger.records.keys()[0]
	page.gaps.assign([0.0, 0.0])
	page.finish_singularity()
	await ticks(2)
	clock = page.ledger.chronal_time
	page.ledger.advance(100.0)
	check(page.ledger.chronal_time == clock and page.ledger.spawn_identity() == -1, "Terminal state rejects pending arrivals and new identities in the convergence frame")
	actor_count = 0
	for panel in page.panels:
		actor_count += panel.arena.enemies.get_child_count()
	check(actor_count == 1 and page.panels[page.active_index].arena.enemies.get_child(0).temporal_id == pending, "Future-only pending survivor consolidates exactly once")
	page.set_paused(true)
	check(not page.pause_slots[0].is_visible_in_tree() and not page.causality_board.is_visible_in_tree(), "Victory menu preserves the single-frame presentation")
	page.set_paused(false)
	finish("SINGULARITY / RESTART")
