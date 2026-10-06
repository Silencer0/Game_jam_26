# Manga interface validation

## Final validation

**22 suites / 455 assertions passed.** The final regression run has no parser/runtime errors or gameplay warnings. Godot MCP inspected the starting project, verified clean boots, exported the Web build and ran the main scene. Compatibility, GDScript, single-threaded Web export and all temporal/combat mechanics remain intact.

Native rendered checks cover the complete causal loop through real attacks, mouse role drags and held E; the UI scenario covers rapid switching, resizing, pointer-operated Controls navigation, role-preview easing, score fragments during pause and the final single panel. The native damage-number scenario verifies the actual 48-damage hit and shows the number on screen. Screenshots were reviewed; a pause z-order defect discovered visually was corrected and covered by a regression check.

Exported Chromium/WebGL2 smoke checks gameplay input, role dragging, separate Timeline/Controls pages, an actual browser fullscreen request and exit, and 1920×1080 / 1280×720 resizing. Browser output has no Godot, JavaScript or shader errors. The build remains `build/index.html`.

## Presentation behavior

- A 1920×1080 canvas, native fullscreen and a responsive 16:9 Web page. Browser fullscreen is available through Esc → Controls → Toggle Fullscreen, requested directly inside an input event as required by [Godot's Web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#full-screen-and-mouse-capture).
- One broad active upper frame and two close-camera lower frames, genuinely clipped into polygons around a diagonal gutter. Old layout tweens are cancelled during rapid switches; the latest choice controls immediately. Geometry eases over 340 ms, camera zoom eases independently, viewport allocation waits for layout to settle, and render width caps at 1440 per world.
- One shared vector-drawn HUD overlays the active frame: green segmented health blade with damage trail, amber ADD ribbon with uncapped exact counter, violet MULT charges with refill/drain and readiness treatment. A compact time-gap diagram replaces the detached timeline header. Combat controls appear only in the pause Field Manual.
- Every accepted enemy hit signals its final attack amount, including overkill and reflected-shot damage, into a 24-label pool per arena. Same-frame hits retain separate labels; dead targets and automatic causal removals produce no fake numbers. Floating numbers expire in real time after 680 ms, including in inactive panels.
- Direct deaths send one amber +1 fragment; genuine contradiction deaths send violet +1 fragments. Automatic causal removals send none. Fragments arc from the world hit location, or the corresponding pause preview, into the active meter, then burst/pulse. Presentation never awards score or delays logical rewards. Flights and collection bursts are bounded at 40; animations can complete while the combat world is paused.
- Pause uses a halftone dark overlay, offset printed-paper cover, slanted buttons and separate Timeline/Field Manual pages. Esc from Controls returns to Timeline, then resumes. Actual gameplay input remains isolated while reading controls. Role previews ease their reassignment and the dragged preview uses a slight comic tilt.
- Main-game drill labels are hidden while graphical windups, attack poses, health strips and strategic enemy IDs remain. Footer text shows only the wave and between-wave countdown; parry and enemy-count readouts and the parry caption are removed. Parry effects and gameplay remain. The final targeted UI rerun passed all 36 assertions. Inactive red frames still occur only after actual shared-health damage; singularity, defeat and restart retain their original behavior.

## Coverage

The new UI suite checks canvas/native-Web fullscreen settings, absence of detached stock progress controls, page geometry and its diagonal gutter, bounded world targets, exactly one controlled player, 18 rapid switches, resize behavior, pause layers, real button input, all control categories, gameplay input isolation, both Esc paths, score-fragment accounting, paused animation cleanup, anti-farming, heavy-effect bounds, preview easing, and single-frame victory. The damage-number suite checks direct/reflected/same-frame/overkill/dead-target/causal cases, exact real-melee ADD/MULT damage and bounded label/history cleanup.

| Suite | Checks | Result |
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
| wave_difficulty | 66 | PASS |
| wave_combat | 30 | PASS |
| manga_ui | 36 | PASS |
| damage_numbers | 10 | PASS |

## Evidence and commands

- `python3 tools/run_game_tests.py`: `build/qa/results.json` and per-suite logs.
- Native: `godot --path . --fixed-fps 60 --frame-delay 5 --audio-driver Dummy --script tests/manga_ui_test.gd`; also `tests/damage_numbers_test.gd` and `tests/causal_end_to_end_test.gd`.
- Native evidence: `manga-ui-rendered.log`, `manga-damage-rendered.log`, `manga-rendered.log`, `manga-page.png`, `manga-timeline.png`, `manga-controls.png`, `manga-damage.png`, `manga-victory.png` under `build/qa/`.
- Web: `node tools/qa_web.cjs <playwright-package> <chromium-executable>`. Its click positions come from actual UI geometry recorded by the UI suite. Evidence: `web-results.json`, `web-smoke.log`, `web-gameplay.png`, `web-controls.png`, `web-fullscreen.png`, `web-1080p.png`, `web-drag.png`, `web-restart.png`.

## Limits and diagnostics

Browser testing used local Chromium with software WebGL, verifying behavior and rendering rather than guaranteeing performance on every device/browser or inside every host iframe. Native fullscreen follows the display's physical resolution; 1920×1080 is the design canvas. Browser security requires a real input for fullscreen, so the Web project override starts in the normal canvas and offers the tested toggle.

One earlier accelerated run while multiple QA processes overlapped produced the existing Jolt worker-job capacity warning. The final complete serial regression run is clean; native/Web final logs are checked separately. Web export reports only the already-running Godot MCP bridge port warning from the second editor process, exits 0 and produces a clean-running game.

No external assets, image-generation output, paid templates or runtime dependencies were added. Graphics are project-authored vector/shader work using the existing credited fonts. No commits were made.
