# FRAME//SHIFT

Godot 4.7.2 / GDScript / Compatibility renderer. Primary target: Web.

## Current stage

Stages 0–7: placeholder 2.5D movement/combat, timed parry, local hit-stop,
launcher/aerial combat, and three independently simulated combat panels.
The stage list is `PLAN.md` (`BUILD_PLAN.md` is not present).
Stage 6 adds instant panel switching and local inactive slowdown.
Stage 7 adds temporal roles and twisting. Future information and final art remain
later stages. Esc opens a paused panel-selection menu.

Open `project.godot` and run `main.tscn` (F5).
The viewport is 1280×720. The Web preset exports to `build/index.html`.

## Controls

- A / D or Left / Right: move and face left/right.
- Space: jump, then press again for a double jump; release early for a shorter hop.
- Shift: dash in the facing direction, on the ground or in the air.
- J / Left click: three-hit ground light string, or up to two lights while airborne.
- Q: ground launcher, or directional airborne finisher (diagonally forward and down).
- F / Right click: timed parry toward the facing direction.
- 1 / 2 / 3: select the matching numbered panel directly.
- Esc: pause all arenas and open the panel menu; Esc or Resume continues play.
- T: rotate temporal roles; Y: swap Past and Future. Also available while paused.
- Tab: cycle to the next panel (A → B → C → A).
- R: restart all three panels at any time, including after victory or defeat.
- Mouse: smoothly eased camera orbit (up to 7° horizontal / 4.5° vertical).

## Movement and melee

Movement changes direction immediately. Jump has a 90 ms coyote window and
100 ms input buffer. Dash lasts 140 ms with a 220 ms recovery cooldown.
Landing restores one extra jump, one air dash, two air lights, and one air finisher.
Neither double jumping nor cancelling an air attack refreshes these budgets.
The player uses a CharacterBody3D and an X/Y movement plane with Z locked to zero.
The orthographic Camera3D follows from a slightly elevated side view.

Attacks have startup, active, and recovery phases. One follow-up can be buffered.
Facing is latched per swing. Ground lights deal 1, 1, and 2 damage; launchers and
finishers deal 2. Targets can be hit once per swing, and solid geometry blocks hits.
Holding attack never repeats. The ground finisher, launcher, and air finisher have
a 200 ms cooldown after recovery/cancellation once their active window begins.
Cooldown clicks are discarded. Walking remains unrestricted; jump and dash can
cancel an attack. Holding Shift does not repeat dashes.

## Stages 5–6: three live panels and switching

`main.tscn` displays the selected arena in a large frame, with the other two
stacked beside it. Use 1/2/3 or Tab to switch instantly. The active arena accepts
movement, combat, and mouse-camera input and runs at its temporal role’s native speed. Inactive arenas
continue at a baseline 0.1x speed, including collision movement, gravity, enemy decisions,
attack phases, hit-stop, cooldowns, damage feedback, and wave timers. UI and
camera easing continue at real speed. `Engine.time_scale` always stays at 1.

Wave progress never changes speed. Active Past/Present/Future arenas run at
70%/100%/130%; inactive arenas run at 7%/10%/13%. The same local clock applies
to player and enemy movement, gravity, attacks, parries, cooldowns, hit-stop,
and wave timers. Headers show the effective speed.

Switching cancels the outgoing attack/recovery, closes its parry window, and
clears buffered taps. Held movement transfers immediately to the selected
player. Held jump/dash/attack/parry buttons must be released and pressed again
before they trigger in the destination; they cannot become ghost inputs.
Health, position, enemy state, momentum, and airborne budgets are preserved.
Double jump, air dash, air lights, and finisher allowances only refresh on landing.
An outgoing dash continues in slow time until its normal end/collision/landing.

Try Q to launch, switch away, fight in another panel, then return and hold Space
to follow the still-airborne target for two air lights and a directional finish.
A contact freeze also runs in local time, so a 60 ms freeze lasts 600 ms while
its panel is inactive. Switching itself is available during hit-stop.

All three player bodies use one six-point health pool, displayed once above
the panels. Damage in any world reduces that pool; switching never restores it.
At zero health the whole run ends. R resets the common pool and all encounters.
Enemies, waves, and arena clears remain independent. Inactive players remain
vulnerable to their own world's attacks, with their existing local damage feedback.
The initial wave is present in every panel from startup. Grunts begin approaching
without requiring the panel to be selected first. Each panel has its own
World3D, collision queries, camera, and encounter. Selection resizes panel Controls
without reparenting/recreating worlds or actors. Panel IDs A/B/C stay fixed and
are separate from the temporal roles that will be added in Stage 7.

Viewports render at their displayed sizes, update continuously, and resize with
the page. The selected frame has a cyan border and `ACTIVE` header; others show
`SLOW 10%` and a large muted 1/2/3 at the center. The center marker is hidden in
the active panel. The active camera keeps the approved framing and small mouse tilt;
side cameras frame more tightly. Inactive panels flash red for 700 ms only after their player actually takes damage.
Windups, misses, dodges, and parries do not trigger red. Only the struck panel
flashes; the timer runs in real time and the active panel hides this indicator. Borders/readouts remain placeholders. Browser
frame pacing and the feel of switching still need hands-on testing.

## Stage 7: temporal roles and pause menu

Each arena retains its number and state while its role changes: Past runs at
0.7×, Present at 1.0×, and Future at 1.3× native speed. T rotates these roles;
Y swaps Past and Future. Twisting preserves health, waves, positions, momentum,
and combat budgets. It does not rewind or predict gameplay. The selected panel
stays large; inactive panels are ordered by temporal role.

Esc freezes gameplay in all arenas and opens an overlay. Drag numbered arena previews between Past, Present, and Future to swap roles.
Click a preview or use 1/2/3 to select the active panel, then press Resume or Esc. Selecting a
panel and changing roles keep the game paused. Restart is also available.
Combat taps made in the menu are discarded on resume.

## Stage 4 encounter

The reusable combat scene is a flat 32-unit arena with three waves: one, two, then three
orange melee grunts. Clear all six enemies to win that arena.
The standalone player has six HP; the three-panel page shares six HP across
all player bodies. Grunts have six HP and deal one damage per strike.
After taking damage, the player blinks for 650 ms; this is feedback, not immunity.
Every distinct un-parried enemy strike costs one HP, including during blinking.
Each swing can damage once. Dodges, parries, and blocked/whiffed strikes cost no HP.
Movement resumes after the brief hit-stop without a long damage animation.

Grunts approach, stop for a 550 ms `WINDUP`, commit to one directional strike,
then recover. Recovery limits the next strike but permits pursuit; switching
to inactive speed never adds a movement wait. Windup, strikes, hit-stun, and
parry stagger still stop pursuit. The translucent strike box shows the actual attack area. Cross
behind or jump away during the telegraph, or face the enemy and parry as windup
ends. Holding parry is not a block. A successful parry interrupts the strike,
staggers the grunt for one second, clears offensive recovery, and permits an
immediate counterattack. Grunts stop attacking while launched or staggered.
They do not physically block the player or one another.

Q launches with 8 units/s horizontal knockback and the same 10.5 units/s upward
impulse, creating more space. Move or air-dash after the target to continue
the aerial chain. Use Q to launch upward and away along X, jump after the target, use two airborne
lights, then Q to slam it diagonally forward/down. Face left or right before the
finisher. A surviving target stops on ground impact and resumes its normal loop.
A lethal air finisher completes the diagonal fall before removing the body.
Light contact briefly interrupts the enemy. Health readouts, mesh squash,
attack/guard boxes, and text remain placeholder feedback.

Contact produces local hit-stop: 35 ms on light hits, 60 ms on heavy hits/parries
and player damage. Only the contacting actors freeze. The camera/UI and other
actors continue; `Engine.time_scale` is unchanged. Jump, dash, parry, and attack
taps during this brief freeze are buffered. Mouse tilt recenters on mouse exit
or focus loss.

## Preserved sandbox

`scenes/combat_arena.tscn` preserves the Stage 4 standalone encounter; run it
directly (F6) for the original full-window view. Its R key restarts that scene.

`scenes/movement_sandbox.tscn` preserves the earlier platforms, three pink
practice targets, and middle-target parry drill. Run that scene directly (F6)
for isolated movement/combat practice. Practice targets have no health/death;
its missed-strike counter remains diagnostic. The original automated suites
now load this scene so they continue checking the approved movement and timing.

## Regression checks

Run from the repository root:

```sh
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-movement.log --script res://tests/player_movement_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-melee.log --script res://tests/player_melee_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-stage3.log --script res://tests/player_stage3_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-stage4.log --script res://tests/player_stage4_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-stage5.log --script res://tests/player_stage5_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-stage6.log --script res://tests/player_stage6_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-shared-health.log --script res://tests/shared_health_warning_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-hit-pressure.log --script res://tests/hit_wave_pressure_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-enemy-switch.log --script res://tests/enemy_switch_movement_test.gd
godot --headless --path . --fixed-fps 60 --log-file /tmp/frame-shift-stage7.log --script res://tests/player_stage7_test.gd
```

These instantiate the actual sandbox and exercise movement, 3D collisions,
attack timing/range/cooldown, cancellation, parry timing/facing, local hit-stop
and buffered inputs, aerial budgets, launch/finish/landing, and mirrored sequences.
Stage 4 checks cover enemy approach, collision damage, parry/counterattack,
committed strikes, aerial combat, enemy deaths, waves, victory/defeat, and restart.
Stage 5 checks cover three separate physics worlds, local input/damage/hit-stop,
independent enemy/wave states, shared health depletion, live updates, cameras, resizing, render
resolution, and restarting all arenas. That foundation suite sets inactive speed
and native role speeds to 1x explicitly. Stage 6 checks actual 0.1x clocks, collision displacement,
switching keys/layout/input ownership, held-button isolation, switch cancels,
launch/switch/return aerial combat, preserved budgets, rapid switches, and restart.
Shared-health checks cover cross-panel damage, one health bar, distinct-hit damage, global
defeat/restart, and attack-warning activation/clearing with real collision strikes.
Earlier panel suites use neutral native role rates to isolate their foundation checks.
Stage 7 checks native rates, role permutations, state preservation, wave-independent flow,
pause freezing, menu selection, resume input isolation, and restart while paused.
They exit nonzero on failure. Movement feel and browser frame pacing still need
hands-on testing on the target device.
