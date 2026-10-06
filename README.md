# FRAME//SHIFT

Godot 4.7.2 · GDScript · Compatibility · Web / itch.io · 1920×1080.
Open `project.godot` and run `main.tscn`. Web output remains `build/index.html`.

Esc → **TRAINING ISSUE / TUTORIAL** opens the roughly five-minute guided issue (or run `tutorial.tscn` directly). Twelve drills introduce movement, combat, melee/bullet parries, timelines, ADD costs, contradictions and both dilation gaps. Objectives and practice time provide feedback; click **NEXT LESSON** to advance whenever ready. Jumping and elapsed time never advance a lesson. Training uses small encounters, a defeat-prevention shield and labelled practice ultimate charges; normal waves retain their difficulty.

Soundtracks follow the active temporal role: Iron Velocity in Past, heavy rock in Present, Synthwave in Future. All versions keep running on one 176.256-second loop; changing arenas or reassigning the active role crossfades at the same playback position. Pause freezes every track together; starting a new issue resets the shared transport. Credits/source mapping are in `CREDITS.md` and `assets/audio/music/SOURCES.json`.

## Current game

The causal-timeline design in `new_idea.md` replaces the former future-mirage and light-beam mechanics. The implementation sequence and explicit tuning assumptions are in `docs/NEW_IDEA_IMPLEMENTATION_PLAN.md`; validation is in `docs/NEW_IDEA_TEST_REPORT.md`.

Enemies arrive in shared waves: one grunt, two grunts, one gunner, then a grunt plus a gunner. Later waves grow to eight identities. Clear every living/pending representation of the wave across the timeline to earn a real-time break of one tenth of the current Future/Present gap and the next wave. Each wave snapshots ADD and gives its enemies `ceil(6 × starting ADD × 1.45^(wave − 1))` HP. Pursuit and bullet speed increase, recovery and windup shorten with readable caps; incoming hits still cost one HP. Stats remain fixed for all copies of an identity. See `docs/WAVE_DIFFICULTY_PLAN.md`.

Every enemy identity is born in Future and arrives in Present, then Past, after one tenth of each corresponding time gap (0.6 seconds per step initially). Its bodies have independent AI, positions and health. A death erases later representations and leaves earlier ones alive. Missing copies differ from permanent death records.

Esc pauses the whole game. Drag the numbered arena previews between temporal roles: 5 ADD per position crossed, or 10 ADD between Past and Future. Unaffordable drops are blocked; choosing the active arena with 1/2/3 remains free. Inactive frames show large amber edge arrows for hidden enemies. An earlier dead representation contradicts later living counterparts and kills them. Moving a survivor earlier creates its missing later counterparts. The enemy ledger joins matching portraits with strings; faded X portraits are dead, dashes have not arrived. Small enemy IDs in combat match these rows.

Direct kills add ADD. Contradiction kills add MULT. Automatic causal removals award no extra points. Attack damage is base damage × ADD × MULT. Both start at 1; MULT fills at 4. In Past or Future, each completed 1.54-second E hold spends one whole MULT charge above the base x1: five real seconds at 30% ordinary environment flow and exactly one second off the adjacent gap. Hold longer to spend more; each charge adds five seconds. Releasing E or switching arenas retains purchased slowdown in the original arena. Pause freezes its timer. A partial hold costs nothing; MULT x2 is enough to start. The player retains their normal local clock. Present cannot dilate.

Close both gaps to achieve singularity: one final Present panel, no duplicate survivors or resurrection, a stable victory state, and R to replay.

## Controls

- A/D or arrows: move and face.
- Space: jump/double jump; release for a shorter hop.
- Shift: ground dash or one air dash before landing.
- J/left click: ground combo or airborne lights.
- Q: launcher / diagonal air finisher.
- F/right click: facing parry (250 ms native-time window); reflects gunner bullets.
- 1/2/3 or Tab: choose an arena.
- Esc: pause/resume; Timeline page has role previews and links, Controls page has every binding and fullscreen toggle. Esc from Controls returns to Timeline.
- Hold E: spend MULT charges for dilation in Past/Future (at least x2).
- R: restart, including defeat and singularity.
- Mouse: eased camera tilt and skyline parallax.

Active Past/Present/Future flow stays at 85%/100%/115%. Every inactive arena runs at 10%. Purchased dilation applies a 30% environmental factor in its arena until its real-time duration expires, including while inactive; its player remains at the ordinary native rate. `Engine.time_scale` stays at 1. Role swaps preserve arena identity, positions and player state. Gaps follow temporal roles.

## Implementation

- `scripts/causal_timeline.gd`: identity records, Future births, gap-dependent arrivals, causal/contradiction resolution and population bounds.
- `scripts/time_dilation.gd`: whole-charge purchases, per-arena slowdown timers and hold cancellation.
- `scripts/panel_session.gd`: shared health, score, local clocks, pause/swaps and singularity.
- `scripts/causality_board.gd`: pause-menu linked portraits and tombstones.
- Existing movement, melee, enemy AI, collision/parry and comic presentation remain in their original scripts.

The game opens in native fullscreen; Web fills the browser canvas and supports fullscreen from the pause Controls page. The manga page has a wide active upper frame and two diagonally divided lower frames. One drawn green/amber/violet HUD overlays the active panel, with moving death fragments, meter pulses and exact hit numbers (including overkill). Switching eases the frame geometry and camera zoom while input changes immediately. `docs/MANGA_UI_PLAN.md` and `docs/MANGA_UI_TEST_REPORT.md` cover this revision.

The accepted toon industrial rooftop, original Rift Courier sprites, comic city, character shadows, manga frames and tighter inactive cameras are preserved. Asset credits and generated-art prompts remain in `CREDITS.md`, `AI_USAGE.md` and `docs/`.

## Automated QA

Run `python3 tools/run_game_tests.py`. It checks all applicable suites, rejects engine errors and timeouts, and saves results/logs under `build/qa/`. Old independent-wave, T/Y-twist, mirage and beam scenarios have been replaced by causal tests; standalone movement/combat sandbox tests still run.

For the rendered complete-loop test:

```sh
godot --path . --fixed-fps 60 --audio-driver Dummy --script tests/causal_end_to_end_test.gd
```

It exercises actual melee keys, GUI mouse drags and held E, earns its scores and reaches singularity without setting scores/gaps. AI is isolated for this scenario; separate suites exercise real melee/gunner AI, parry, damage and pursuit. Screenshots go to `build/qa/`.

`tools/qa_web.cjs` accepts a Playwright package path and Chromium executable for a development-only exported-browser smoke test. No browser tooling is a runtime dependency.

Initial gaps (6 seconds), trickle/intermission ratio (0.1), frame-shift cost (5 ADD per role), MULT cap (4), hold cadence (one MULT per 1/0.65 seconds), slowdown (30% for 5 seconds per MULT), convergence (1 gap second per MULT) and enemy caps are explicit tuning constants. Further enemy variety and a boss remain future work; shared waves now provide ongoing difficulty progression until singularity.
