extends "res://tests/causal_test_base.gd"
func run_checks() -> void:
	await fresh()
	var ult: Node = page.dilation
	check(not ult.begin(), "Base x1 cannot fund a charge")
	page.multiplier = 2.0
	check(ult.begin(), "One spare MULT unit can start a hold")
	ult.step(ult.HOLD_SECONDS * 0.5)
	check(not ult.active and page.multiplier == 2.0 and page.gaps[0] == 6.0, "An unfinished hold costs nothing")
	ult.stop()
	check(not ult.charging and not ult.active, "Release cancels an unfinished purchase")
	check(ult.begin(), "A fresh hold can reuse unspent MULT")
	ult.step(ult.HOLD_SECONDS)
	check(page.multiplier == 1.0 and page.gaps == [5.0, 6.0], "One completed hold costs exactly one MULT and closes one gap second")
	check(is_equal_approx(ult.remaining_for(0), 5.0), "One charge buys exactly five real seconds")
	check(is_equal_approx(page.panels[0].arena.simulation_rate, 0.255) and is_equal_approx(page.panels[0].arena.player.simulation_rate, 0.85), "Past environment runs at 30% while the player keeps native speed")
	ult.stop()
	ult.step(2.0)
	check(is_equal_approx(ult.remaining_for(0), 3.0), "Release retains purchased time and keeps ticking it")
	page.select_panel(2)
	check(is_equal_approx(page.panels[0].arena.simulation_rate, 0.03), "Purchased slowdown survives switching and applies to inactive flow")
	page.multiplier = 2.0
	ult.input_blocked = false
	check(ult.begin(), "Another physical arena can buy its own slowdown")
	ult.step(ult.HOLD_SECONDS)
	check(ult.remaining_for(0) > 0 and is_equal_approx(ult.remaining_for(2), 5.0) and page.gaps == [5.0, 5.0], "Arena timers coexist and gaps are reduced independently")
	page.set_paused(true)
	var retained: float = ult.remaining_for(2)
	ult.step(100.0)
	check(ult.remaining_for(2) == retained and not ult.charging, "Pause freezes purchased time and cancels charging")
	page.set_paused(false)
	ult.step(5.0)
	check(not ult.active and is_equal_approx(page.panels[2].arena.simulation_rate, 1.15), "Expiry restores ordinary local flow")
	page.select_panel(1)
	page.multiplier = page.MAX_MULT
	ult.input_blocked = false
	check(not ult.begin(), "Present cannot spend dilation charges")
	page.select_panel(2)
	ult.input_blocked = false
	ult.begin()
	ult.step(ult.HOLD_SECONDS)
	page._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(ult.active and not ult.charging and ult.input_blocked, "Focus loss cancels charging but retains purchased seconds")
	page.panels[2].arena.player.receive_damage(100)
	check(not ult.active and page.health == 0, "Defeat clears all purchased slowdowns")

	await fresh()
	ult = page.dilation
	page.multiplier = page.MAX_MULT
	ult.begin()
	var duration: float = ult.HOLD_SECONDS * 3.0 + 0.25
	ult.step(duration)
	var big_remaining: float = ult.remaining_for(0)
	check(page.multiplier == 1.0 and page.gaps[0] == 3.0 and is_equal_approx(ult.spent_total, 3.0), "Three charges add fifteen seconds and close exactly three gap seconds")
	await fresh()
	ult = page.dilation
	page.multiplier = page.MAX_MULT
	ult.begin()
	for _i in range(600):
		ult.step(duration / 600.0)
	check(absf(big_remaining - ult.remaining_for(0)) < 0.00001 and page.gaps[0] == 3.0 and page.multiplier == 1.0, "Charge boundaries and remaining duration agree across frame sizes")
	ult.reset()
	page.gaps[0] = 0.5
	page.multiplier = page.MAX_MULT
	ult.input_blocked = false
	ult.begin()
	ult.step(ult.HOLD_SECONDS * 3.0)
	check(page.gaps[0] == 0 and page.multiplier == 3.0, "Gap floors at zero and never consumes extra charges after overlap")

	await fresh()
	page.set_physics_process(true)
	page.multiplier = page.MAX_MULT
	key(KEY_E, true)
	await ticks(10)
	check(page.dilation.charging and not page.dilation.active, "Raw E starts an unpaid hold")
	await ticks(90)
	check(page.dilation.active and page.gaps[0] == 5.0, "A sustained raw E hold purchases one charge")
	key(KEY_E, false)
	await ticks(2)
	check(page.dilation.active and not page.dilation.charging, "Releasing raw E keeps the purchased slowdown")
	key(KEY_E, true)
	await ticks(2)
	page.set_paused(true)
	page.set_paused(false)
	await ticks(3)
	check(not page.dilation.charging, "Holding E through pause cannot restart charging")
	key(KEY_E, false)
	await ticks(2)
	key(KEY_E, true)
	await ticks(2)
	check(page.dilation.charging, "Release and press restores charging")
	key(KEY_E, false)
	check(is_equal_approx(Engine.time_scale, 1.0), "Dilation never changes Engine.time_scale")
	finish("TIME DILATION")
