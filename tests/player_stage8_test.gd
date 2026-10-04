extends "res://tests/player_stage6_test.gd"
## Live beam targets, not AI prediction or historical traces.

func run_checks() -> void:
	await fresh_page(true, true)
	var routing_ok: bool = true
	for cycle in range(2):
		for turn in range(3):
			for panel in panels:
				var info: Node3D = panel.arena.get_node("TemporalInformation")
				info.refresh()
				if panel.arena.temporal_role == &"Future":
					routing_ok = routing_ok and info.displayed.is_empty()
				else:
					var next_role: StringName = &"Present" if panel.arena.temporal_role == &"Past" else &"Future"
					for source in panels:
						if source.arena.temporal_role == next_role:
							var enemy: CharacterBody3D = source.arena.enemies.get_child(0)
							routing_ok = routing_ok and info.displayed.size() == 1 and info.displayed[0].enemy_id == enemy.get_instance_id() and info.cues[0].position == enemy.position
			page.twist_timeline()
		page.twist_timeline(true)
	check(routing_ok, "All six role assignments show exact live enemies from only the next role; Future shows none")
	var info: Node3D = panels[0].arena.get_node("TemporalInformation")
	var enemy: CharacterBody3D = panels[1].arena.enemies.get_child(0)
	enemy.position = Vector3(10, 4, 0)
	enemy.hitstun_left = 1.0
	info.refresh()
	check(info.displayed.size() == 1 and info.cues[0].position == enemy.position, "Airborne and stunned enemies remain visible beam targets at their actual position")
	var before: Vector3 = enemy.position
	for i in range(100):
		info.refresh()
	check(enemy.position == before and enemy.hitstun_left == 1.0 and page.health == 6, "Mirages do not simulate or damage the source enemies")
	check(info.find_children("*", "CollisionObject3D", true, false).is_empty() and info.get_child_count() == info.MAX_CUES, "Mirages use a fixed collision-free mesh pool")
	page.set_paused(true)
	await ticks(10)
	check(info.cues[0].position == before, "Pause freezes mirages with their real targets")
	page.assign_panel_role(1, &"Future")
	check(info.displayed[0].source_panel == 3, "Dragging roles updates the next-role targets immediately while paused")
	page.set_paused(false)
	var target: CharacterBody3D = panels[2].arena.enemies.get_child(0)
	target.receive_melee_hit(100, 1)
	info.refresh()
	check(info.displayed.is_empty() and not info.cues[0].visible, "Dead enemies leave no stale shootable mirages")
	print("STAGE 8 MIRAGE CHECKS COMPLETE: ", failures, " failures")
	quit(1 if failures else 0)
