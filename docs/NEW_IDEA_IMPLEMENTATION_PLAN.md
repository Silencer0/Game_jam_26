# FRAME//SHIFT causal timeline implementation

Source: `new_idea.md` (6 October 2026). This replaces old Plan stages 8–12 where they conflict. Keep Godot 4.7.2, GDScript, Compatibility/Web, three independent World3Ds, local clocks, accepted visuals and combat. No commits requested.

## Concrete rules and tuning assumptions

- An enemy has one stable identity with independent physical copies and durable alive/dead records per arena. Roles reorder arena states, not enemy IDs. Missing (not yet arrived) differs from dead.
- Every new identity originates in the current Future. It trickles into Present, then Past. Initial gaps are 6 chronal seconds each; migration advances on a shared chronal clock (paused with the game). The follow-up in `WAVE_DIFFICULTY_PLAN.md` replaces single births with shared waves and a Future-local intermission clock. A smaller gap shortens pending arrivals, zero gap arrives immediately. Copies keep their original species; health and AI are independent.
- Killing a copy normally adds one ADD point and kills any existing later copies causally. Those automatic removals do not grant extra score. Earlier copies survive. Unborn earlier copies can still arrive after a later death; an existing tombstone is never resurrected.
- After a role swap, reprocess only identities represented in either swapped arena. An earlier dead record kills later live copies as contradictions. Each genuinely killed copy gives +1 MULT; dead/missing copies give nothing. Then earlier live copies fill missing later copies. No resurrection, no reward for simply creating a copy or dragging back and forth without a new kill.
- ADD and MULT start at 1 so attacks always work. Melee/reflected player-shot damage = existing base damage × ADD × max(1, MULT). ADD is uncapped; MULT caps at 4, which is also the ultimate meter. Three contradiction kills fill it. A direct kill always gives ADD, not MULT.
- Hold E in Past or Future, with MULT full, to start dilation. Past closes Past↔Present; Future closes Present↔Future. Present cannot dilate. Dilation spends MULT continuously down to its baseline of 1; releasing E retains unused MULT and permanent gap progress, but restarting requires a full meter again. Closing the last part of a gap costs more per unit. Environmental simulation (enemy AI, projectiles, spawning, local effects) slows to 20% of its normal rate; that arena's player movement/combat/parry keeps its normal rate. Never change Engine.time_scale.
- Switching, opening pause, defeat, losing focus, exhausting the meter or reaching a gap stop dilation immediately. No held-input carry into another arena. Gaps belong to temporal roles and persist through swaps.
- When both gaps reach zero, consolidate surviving identities into one visible Present arena (one copy per identity, earliest death wins), suspend other arenas, stop spawning/combat and show SINGULARITY ACHIEVED. R restarts all scores, gaps, identities, clocks and input state. No additional boss is required by this proposal.
- Spawn pressure is bounded (at most 12 live copies per arena / 36 identities with pending or live representations). Tombstones remain while relevant and a recent bounded archive is available in pause. The shared-wave follow-up applies immutable exponential health profiles and bounded aggression scaling.

## Sequential phases and test gates

1. **Baseline and remove retired mechanics**: record baseline, remove beam/mirage nodes, scripts, bindings and UI references. Keep ranged enemy bullets/reflection. Adapt superseded tests rather than retain false expectations. Gate: clean boot; movement/melee/parry tests; no beam/mirage nodes or action.
2. **Causal enemy lifecycle and trickle spawning**: session-owned identity ledger, managed arenas, Future-only births, gap-dependent migration, forward death propagation, persistent tombstones and population limits. Gate: Future→Present→Past, missing vs dead, Past/Present/Future kills, species/position safety, simultaneous deaths, pause, bounds.
3. **Role swaps and scoring**: atomic pause swaps, contradiction-first resolution followed by forward creation, duplicate-reward protection, ADD/MULT counters and damage scaling. Gate: all role permutations, partial representations, unrelated births, multiple contradictions, repeated swaps, actual melee and reflected projectile damage.
4. **Pause causality view**: corresponding enemy portraits linked by strings, faded dead portraits with X, clear missing states, dragging previews remains fast and paused. Gate: correspondence, distinct tombstones, scrolling/bounds, swap redraw, keyboard/mouse drag and pause input isolation.
5. **Dilation and convergence**: hold-E activation/continuous drain/nonlinear gap costs, local environment-only slowdown, all cancellation paths, compact meters and gap display. Gate: incomplete/full meter, both eligible roles, Present rejection, early release, depletion, paused/switch/focus/death cancellation, enemy vs player clocks, gap-dependent arrivals, frame-rate independence.
6. **Singularity and restart**: consolidate identities, one final panel, victory presentation and restart. Gate: both gaps required, no duplicates/resurrection, frozen spawns/projectiles, all restart fields reset, defeat path.
7. **Integrated QA and Web**: run all applicable suites with timeouts/error scanning; rendered gameplay/input scenario and pause drag; build Web and run it in a browser if tooling permits. Record exact results, limitations and tuning in `docs/NEW_IDEA_TEST_REPORT.md`. Fix regressions before completion.

Each phase must pass its tests and a parser/runtime check before the next begins. Progress and validated results are appended below.

## Progress

- Baseline inspected with Godot MCP: `main.tscn`, three panel arenas; Godot 4.7.2 headless boot clean. Git contains only the user's edit to `new_idea.md`; preserve it.

- Phase 1 passed: removed runtime beam/mirage systems and T/Y shortcuts; baseline movement/combat/parry/input/sprite checks clean.
- Phase 2 passed: stable identities, Future births, backward arrivals, forward deaths, tombstones and population limits.
- Phase 3 passed: all role swaps, unaffected identity preservation, contradiction-first resolution, no reward farming, actual melee/reflected damage scaling.
- Phase 4 passed: scrollable linked portraits, faded X tombstones, stable preview numbers and genuine GUI drag/drop under pause.
- Phase 5 passed: integral nonlinear cost, meter/refill/hold/release, all cancellation paths and actual player/environment clock separation.
- Phase 6 passed: one final panel, no duplicates/resurrection, pending-arrival terminal guard, victory menu and restart.
- Phase 7 passed: 18 suites / 313 checks, rendered complete-input scenario and Chromium Web smoke. Final gameplay suite run has no errors or warnings; export's duplicate MCP-port warning is documented in NEW_IDEA_TEST_REPORT.md.
