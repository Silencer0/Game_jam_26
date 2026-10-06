# Shared wave difficulty validation

The subsequent [manga UI revision](MANGA_UI_TEST_REPORT.md) retains this wave/combat coverage and adds presentation tests.

## Results

- **20 suites / 409 assertions passed**, including the original movement, causal, scoring, pause-drag, dilation, singularity and enemy-AI regressions. No parser/runtime errors or gameplay warnings.
- Godot MCP inspected the project, booted it cleanly with Godot 4.7.2, exported Web successfully and ran the current main scene.
- Native OpenGL Compatibility wave-combat scenario passed: four waves cleared using real melee inputs and causal propagation, plus actual higher-wave pursuit, gunner emission, collision, parry and reflected damage. Combat progression fixtures isolate AI; separate checks exercise actual AI.
- Exported Chromium/WebGL2 smoke passed with movement, jumping, panel switching, pause/role dragging, parry, attacks, E and restart. No Godot, JavaScript or shader errors; panel wave footers were visually inspected.
- No commits were created. Web output remains in ignored `build/index.html`.

## New coverage

The progression suite advances through ten waves, checks the introductory compositions, exponential HP growth, bounded density and distinct birth positions. It verifies that surviving or unborn earlier copies block clearance after Future kills, that contradictions can clear a cohort and award MULT, and that the next wave is born in the current Future after roles move. Capacity-delayed members retry without disappearing. Pause freezes wave clocks, inactive Future uses 10% local time, and Future dilation slows the intermission clock. Defeat and singularity stop progression; real R input resets wave, cohort, score snapshot and difficulty.

Delayed arrivals and swap-created copies inherit immutable wave profiles. Existing health never changes because ADD increases. A wave-six grunt survives an actual 48-damage attack; a reflected shot deals the full 96 scaled damage once. Stronger enemies still launch, stagger and parry. Incoming damage stays one shared HP. Pursuit/recovery/windup/projectile scaling is checked in actual simulation, with capped timing/speeds and unchanged panel rates.

## Tuning

HP = `ceil(6 × wave-start ADD × 1.45^(wave − 1))`. MULT remains an advantage; it is not included in the health snapshot. Compounded pursuit +8% per wave caps at 1.5×; recovery speeds up by a 1.1 factor per wave with a 0.5× duration floor; windup speeds up by 1.04 with a 0.7× duration floor; bullet speed +5% caps at 1.5×. Cohorts cap at eight identities (up to three linked bodies each). Defensive HP cap is one billion.

The break is **2.5 Future-local seconds**, so it lasts longer when Future is inactive or dilating; selecting Future resumes its ordinary clock. Wave health, speed and counts stay independent of local time scale. See `WAVE_DIFFICULTY_PLAN.md`.

The test suite establishes functional behavior and stronger combat statistics. Human difficulty and performance across every browser/device remain tuning/measurement questions; browser smoke used local Chromium with software WebGL. Export reported only the existing duplicate Godot MCP bridge-port warning from its second editor process; exported gameplay and suite runs are clean.

## Suite results

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

## Reproduce

- `python3 tools/run_game_tests.py` → `build/qa/results.json` and per-suite logs.
- `godot --path . --fixed-fps 60 --frame-delay 5 --audio-driver Dummy --script tests/wave_combat_test.gd` → native scenario (recorded in `build/qa/wave-combat-rendered.log`).
- `node tools/qa_web.cjs <playwright-package> <chromium-executable>` → `build/qa/web-results.json`, screenshots and recorded `web-smoke.log`.
