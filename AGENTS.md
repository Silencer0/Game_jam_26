# FRAME//SHIFT

## Stack

- Godot 4.7.2
- GDScript
- Compatibility renderer
- Primary target: Web / itch.io
- Target resolution: 1920x1080

## Core Architecture

There are three simultaneous combat arenas shown as comic panels.

Arena identity and temporal role are separate concepts.

Temporal roles:
- Past: 0.9x native flow
- Present: 1.0x native flow
- Future: 1.1x native flow

Only one arena is active at a time.

Inactive arenas continue simulation at a heavily reduced LOCAL time scale.

Never use Engine.time_scale for panel slowdown.

Do not implement literal 10-minute rewind/history simulation.

Twisting only reassigns Past / Present / Future roles to existing arena states.

Future prediction should expose enemy AI intent rather than literally simulate the future when possible.

## Visual Language
refer to visuals.md for visual style guide.

## Priorities

1. Complete playable game loop
2. Fun movement/combat/parry
3. Stable Web export
4. Panel switching
5. Temporal twist mechanic
6. Enemy variety
7. Visual polish
look at plan.md for the stage by stage execution plan

Prefer simple and robust implementations.

Avoid unnecessary abstractions and dependencies.

## Development Workflow

After meaningful changes:

1. Check parser/runtime errors.
2. Run the relevant scene.
3. Fix regressions before adding another major feature.
4. Preserve Web compatibility.
5. Make small understandable commits.

For large architectural changes, explain the intended approach before implementing it.

## Repository Rules

- Do not rewrite Git history.
- Do not add external assets without updating CREDITS.md.
- Record AI-generated assets/tools in AI_USAGE.md.
- Do not commit secrets.
- Do not use paid assets or complete game templates.