# Manga page / combat HUD revision

1. Preserve causal waves, scoring, parry and local clocks. Move the game to a 1920×1080 canvas and native fullscreen; keep responsive Web scaling and an explicit fullscreen toggle in the pause menu.
2. Build the supplied page composition: one broad active upper panel, two close-camera lower panels separated by a diagonal ink gutter. Use lightweight viewport-texture clipping and custom vector borders, so the shape is real rather than a rectangle with decoration. Animate position/size/shape during switches, cancel old tweens when switching again, and update camera/viewport framing smoothly.
3. Draw one shared HUD inside the active panel: green segmented health ribbon, amber ADD ink reservoir and violet MULT charge strip with exact values. No detached progress bars or separate top header. Overlay compact wave/gap/status graphics; keep combat lane clear.
4. Signal every actual enemy hit (including reflection) into bounded animated damage-number pools. Display the final attack amount, including overkill. Deaths send amber/violet score fragments from their actual on-screen locations into the appropriate active HUD, with a count/fill pulse, no reward for causal automatic removals. Make pause-origin contradiction rewards visible while paused too. Animate refill, drain, readiness, damage trail, switch ink sweeps and terminal state.
5. Redesign pause as a styled issue spread with two pages: Timeline (role dragging and enemy links) and Controls (all current bindings, ability rules, fullscreen). Inputs remain isolated while paused; no gameplay control text in the main game. Retain keyboard focus navigation and singularity/restart behavior.
6. Test exact numbers, reward accounting, HUD lifecycle, full and partial MULT, damage, rapid switching/tween cleanup, polygon geometry, 1920/1280/resizes, pause pages and real GUI drags. Run all mechanics regressions, rendered screenshots and exported-browser tests. No commits, new runtime dependencies or external art assets.

Vector graphics are project-authored and remain crisp at different display sizes. This is a presentation revision, not new combat mechanics.

## Completed gates

All six phases implemented and tested. Final mechanics/UI regression: 22 suites / 455 passing assertions, no gameplay warnings. Native rendered scenarios and Web fullscreen/controls/resizing checks passed. Details and evidence: `MANGA_UI_TEST_REPORT.md`.
