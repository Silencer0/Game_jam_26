# Ember character animation map

All three characters use original generated art from one coordinated design family.
Every sheet uses four columns of 128px frames. Sources and full prompts are preserved
in art/ember and docs/EMBER_SPRITE_PROMPTS.md. No human facial animation is required.

| Character | State | Sheet / row (zero-based) | Frames |
|---|---|---|---|
| Player | Idle / run | movement / 0, 1 | 4 each |
| Player | Jump and double jump | movement / 2 | takeoff 0–1, apex 2, falling 3 |
| Player | Ground / air dash | movement / 3 | 4 |
| Player | Parry / successful deflection | movement / 4 | guard 0–1, deflection 2–3 |
| Player | Hurt / death / beam cast | movement / 5, 6, 7 | 4 each |
| Player | Ground combo 1 / 2 / 3 | combat / 0, 1, 2 | 4 distinct frames per strike |
| Player | Air lights 1 / 2 | combat / 3 | shared airborne 4-frame slash |
| Player | Launcher | combat / 4 | 4 upward slash frames |
| Player | Diagonal air finisher | combat / 5 | 4 downward diagonal slash frames |
| Melee enemy | Idle / run / sword attack | grunt / 0, 1, 2 | 4 each |
| Gunner | Idle / run / carbine shot | gunner / 0, 1, 2 | 4 each |
| Both enemies | Hurt / launched / death | respective sheet / 3, 4, 5 | 4 each |
| Mirages | Live source enemy state | same texture, frame, scale and facing as source | exact current frame |

Animation uses local simulation rate, freezes during hit-stop and pause, and
tracks combat timings without changing hitboxes. Input and movement can still cancel
attacks immediately. Ground and air dash share the same visual sequence; the two
air lights share one airborne slash. Every other listed attack has its own row.

These are short generated pose sequences with four frames per full action.
They are not hand-animated production loops; scarf/weapon details may vary between
frames. Check continuity, visual reach and readability during manual play.

Causal-timeline revision: the former beam pose remains unused source artwork. Runtime light-beam/mirage systems are removed; E is dilation. Enemy IDs link physical bodies to pause-menu portraits.
