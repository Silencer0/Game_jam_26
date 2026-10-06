# Causal timeline validation — 6 October 2026
Latest presentation results: [1080p manga UI validation](MANGA_UI_TEST_REPORT.md), 22 suites. Shared waves replace single-enemy cadence. See [wave difficulty validation](WAVE_DIFFICULTY_TEST_REPORT.md) for the current 20-suite results. The results below record the preceding causal-timeline baseline.

All seven phases in `NEW_IDEA_IMPLEMENTATION_PLAN.md` are implemented. The user's `new_idea.md` was preserved unchanged.

## Final results

- **18 automated suites, 313 assertions: PASS.** No SCRIPT ERROR, runtime ERROR or gameplay warnings in the final suite run.
- Godot MCP headless boot: clean, Godot 4.7.2, main scene `res://main.tscn`, Compatibility renderer.
- Rendered native full-loop test: PASS, AMD OpenGL Compatibility. Earned ADD through raw melee input, earned MULT through real GUI drag/drop contradictions, held E to close both gaps, reached singularity. No forced scores or gaps.
- Web release export: PASS, output `build/index.html`, existing single-threaded export preset preserved.
- Exported Chromium/WebGL2 smoke: PASS. Actual movement/jump/switch/pause/parry/attack/E/restart input; actual mouse drag changes role previews and creates linked representations. No JavaScript, Godot runtime or shader errors.
- Reviewed native and Web screenshots: compact meters, linked identity rows, dead X portraits, role icons, city coverage and single-frame victory. Web symbol fallback and victory-backdrop sizing defects were fixed during this review.
- Source diff whitespace check: clean for implementation files. Pre-existing trailing spaces in the user's proposal were left untouched.

## Suite inventory

| Suite | Assertions | Result |
|---|---:|---|
| player_movement | 28 | PASS |
| player_melee | 23 | PASS |
| player_stage3 | 25 | PASS |
| player_stage4 | 29 | PASS |
| keyboard_input | 15 | PASS |
| ember_sprite | 12 | PASS |
| causal_lifecycle | 22 | PASS |
| causal_swap_score | 22 | PASS |
| causal_damage | 5 | PASS |
| causal_pause_ui | 9 | PASS |
| time_dilation | 23 | PASS |
| dilation_clock | 7 | PASS |
| singularity | 13 | PASS |
| ranged_enemy | 26 | PASS |
| shared_health_warning | 19 | PASS |
| enemy_switch_movement | 14 | PASS |
| causal_end_to_end | 16 | PASS |
| causal_bounds | 5 | PASS |

## Mechanics covered

Future-only births before and after role reordering; Future→Present→Past arrivals; gap-dependent delays and accelerated arrival after gap reduction; species and independent body health; missing vs dead; forward causal death; no backwards death; tombstone durability; all pairwise swaps; unrelated births untouched by swaps; missing future creation; no repeated-swap farming; ADD/MULT damage through actual melee and reflected projectiles; scrollable identity links; genuine pause UI mouse drags; shared damage and confirmed-hit-only red borders; native/inactive AI movement and projectile/parry clocks; full-meter and role eligibility; early release, hold, depletion/overlap stop and refill; nonlinear cost/frame-size equivalence; pause/switch/focus/defeat input cancellation; player clock exempt from environmental slowdown; both gaps required; deduplicated/no-resurrection singularity; no post-victory births or pending arrivals; stable final-frame menu; complete restart; long-run ID/archive/population bounds.

Existing movement/ground dash/air dash/double jump, ground combos, launch/aerial finishers, facing parry, gunner aim/telegraph/flight/reflection, solid-wall occlusion and local hit-stop continue to have executable regression coverage.

## Evidence and commands

`python3 tools/run_game_tests.py` writes `build/qa/results.json` and per-suite logs. It times out failed/hanging suites and rejects engine errors, even if assertions print PASS. Fixed-delta tests include a short wall-time delay so Jolt workers can complete between accelerated steps.

Rendered scenario: `godot --path . --fixed-fps 60 --frame-delay 5 --audio-driver Dummy --script tests/causal_end_to_end_test.gd`. Evidence: `build/qa/rendered.log`, `gameplay.png`, `future-death.png`, `pause-links.png`, `dilation.png`, `singularity.png`.

Browser smoke: `node tools/qa_web.cjs <playwright-package> <chromium-executable>`. Evidence: `build/qa/web-results.json`, `web-smoke.log`, `web-gameplay.png`, `web-pause.png`, `web-drag.png`, `web-restart.png`. Browser dependencies are development-only and not added to the game.

Generated Web outputs, logs and screenshots stay in ignored `build/`; source tests, the runner and this report are reviewable repository files.

## Diagnostic notes and practical limits

- Export reported the already-running Godot MCP bridge's port-8756 listen warning. It comes from launching a second editor process for export, not the exported game. Export exits 0; the browser and final gameplay suites have no errors/warnings.
- Unthrottled accelerated test runs initially produced sporadic Jolt worker-capacity warnings. Giving workers 5 ms between fixed-delta steps eliminated them; the final 18-suite run is clean. Native rendered and Web runtime checks also remain clean.
- Full-loop automation isolates enemy AI so it can test the causal strategy deterministically. Separate melee/gunner, pursuit, shared-health and dilation-clock suites exercise actual AI, collision damage and defense. This does not measure human difficulty or guarantee frame pacing on every browser/device.
- Browser smoke used local Chromium with software WebGL; it verifies export/runtime/input/rendering, not GPU performance or all itch.io browsers. No network game service is required.
- Initial gap, spawn cadence, score baselines/full meter, drain and nonlinear cost are explicitly documented tuning choices where the proposal did not provide values. Longer progression, additional enemies, audio and a boss remain outside this revision.

No known unresolved functional failure was found in the covered scenarios. No commit was created.
