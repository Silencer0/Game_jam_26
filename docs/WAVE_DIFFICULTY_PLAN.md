# Shared waves and enemy scaling

Requested follow-up: enemies arrive in waves and become substantially, exponentially tougher as ADD/MULT grows.

1. Replace automatic single-enemy births with one session-wide wave coordinator in the causal ledger. Births still occur only in the current Future. A wave completes only once its whole cohort has no living or pending copies anywhere; Future-only kills cannot skip surviving Past/Present enemies. Pause, local Future slowdown, dilation, defeat and singularity continue to govern spawning.
2. Keep the accepted introduction: one grunt; two grunts; one gunner; one grunt plus one gunner. Then grow to eight identities per wave, with a bounded mix of melee and ranged enemies. Add a 2.5 Future-local-second break between waves.
3. Snapshot ADD at wave start. HP = ceil(6 × starting ADD × 1.45^(wave − 1)). MULT remains an earned burst advantage and is not cancelled by adaptive health changes. Profiles stay immutable for the identity, including delayed and role-swapped copies. Old enemies never gain health because the player scores another kill.
4. Increase pursuit by 8% compounded per wave (cap 1.5×), shorten recovery by 10% compounded (floor 0.5×), shorten telegraphs by 4% compounded (floor 0.7×), and increase bullet speed by 5% compounded (cap 1.5×). Keep player hit damage at one HP, the parry window unchanged, launch/interrupt mechanics intact, and all changes separate from panel time scales. Defensive HP ceiling 1 billion prevents runaway integer overflow in extremely long runs.
5. Show shared wave number, remaining identity count and break countdown in the existing panel footer. Add focused progression/scaling/AI/causality tests, then rerun the complete mechanics suite, Godot boot and Web smoke. Preserve the existing standalone combat sandbox fixtures.

No commits requested. No new art or runtime dependencies.

## Completed validation

All five steps completed. Twenty suites / 409 assertions passed; native wave combat, Godot MCP boot/run, Web export and Chromium smoke passed. Details: `WAVE_DIFFICULTY_TEST_REPORT.md`.
