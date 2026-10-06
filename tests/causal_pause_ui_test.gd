extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var id: int = page.ledger.records.keys()[0]
	page.set_paused(true)
	var board: Control = page.causality_board
	check(board.rows.size() == 1 and board.rows[0].cells == [&"missing", &"missing", &"alive"], "Pause ledger shows Future-only identity with explicit missing cells")
	page.addition = 10 # Fund the two-role GUI swap.
	var past: Button = page.pause_slots[0]
	var data := {"panel_session": page.get_instance_id(), "panel_index": 2}
	check(past._can_drop_data(Vector2.ZERO, data), "Real role-slot drag payload is accepted while paused")
	past._drop_data(Vector2.ZERO, data)
	check(board.rows[0].cells == [&"alive", &"alive", &"alive"], "Dragging Future to Past refreshes all three linked counterparts")
	check(page.pause_buttons[2] == past and past.get_node("Number").text.contains("3"), "Pause previews retain stable arena numbers after swapping")
	check(not past._can_drop_data(Vector2.ZERO, {"panel_session": -1, "panel_index": 1}), "Foreign drag payload cannot mutate the game")
	var before: Vector3 = page.ledger.actor_for(id, 2).position
	await ticks(15)
	check(page.ledger.actor_for(id, 2).position == before, "Enemy bodies remain frozen throughout pause-menu interaction")
	page.set_paused(false)
	check(not past._can_drop_data(Vector2.ZERO, data), "Role drops are rejected during live combat")
	page.ledger.actor_for(id, 1).receive_melee_hit(100, 1)
	page.set_paused(true)
	check(board.rows[0].cells == [&"alive", &"dead", &"dead"], "Pause ledger retains faded/X tombstones instead of losing counterpart rows")
	for _i in range(9):
		page.ledger.spawn_identity()
	page.refresh_pause_menu()
	check(board.custom_minimum_size.y > 176 and board.rows.size() == page.ledger.records.size(), "Long enemy ledger is scrollable and includes all tracked identities")
	page.set_paused(false)
	finish("CAUSAL PAUSE UI")
