# FRAME//SHIFT Visual Direction

## Overall
2.5D comic-action game: toon industrial environment with Dead Cells-inspired
pixel sprites for characters. Original nonhuman Rift Courier hero: ivory prism helmet, split coat, indigo armor,
teal boots and violet cleaver. Enemies retain distinct spirit armor silhouettes.
No flame-head/red-scarf hero resembling the supplied existing-game reference.
Atmospheric inked industrial city fills the skyline behind the toon stage.
Readability and responsiveness matter more than graphical fidelity.

## Main Reference
Genshin Impact character finish and Hi-Fi Rush action readability:
- cel-shaded / flat-color look
- thin character outlines with strong silhouettes
- bold color separation
- exaggerated silhouettes
- readable attack telegraphs
- punchy hit feedback

## Comic Presentation
- three live comic panels
- thick panel borders
- active panel clearly emphasized
- one broad upper active frame, two close-camera lower frames with a true diagonal ink gutter
- panels ease their geometry and camera framing when switching
- borders react to heavy impacts
- impact typography for strong hits

## Combat Feedback
- brief hit-stop
- subtle camera punch/shake
- slash trails
- speed lines
- bright parry flash
- clear enemy windups
- strong silhouettes

## Temporal Identity
Past:
- slightly subdued / warmer feeling
- warm role accent and reverse chevron icon

Present:
- neutral visual treatment

Future:
- sharper/brighter feeling
- violet role accent and forward chevron icon

These are visual identifiers, not strict color requirements yet.

## Priorities
1. Readable gameplay
2. Strong silhouettes
3. Clear active-panel indication
4. Clear parry/attack telegraphs
5. Comic feel
6. Polish

Avoid:
- realistic materials
- complex lighting
- visual clutter
- tiny effects
- expensive shader work

## Foreground separation
- Characters and attacks carry the saturation and strongest light/dark contrast.
- Background machinery uses muted blue-grey values with no bright competing labels.
- Preserve a quiet combat lane; deck detail must remain broad and low contrast.
- Environment meshes retain smooth normals and modest MSAA; characters use nearest-filtered pixel art.
- Retain shadows and real 3D depth without expensive screen-space effects.


## Current presentation

Accepted toon industrial rooftop: cream deck, teal pipes, red service buildings,
angular cel shadows, selective ink/hatching and a complete comic city panorama.
Continuous rear railings attach to the fight deck; screens and street lamps have
visible floor supports. The large charcoal rear structure has been removed.

Original Rift Courier hero uses an ivory prism helmet, indigo armor, split coat,
teal boots and violet cleaver. Enemy spirits use distinct melee/gunner silhouettes.
Characters have grounded inked contact shadows; their bodies and shadows remain
on actual 3D floor geometry. Generated art provenance is in CREDITS.md and AI_USAGE.md.

The UI uses printed-paper gutters, heavy manga frame borders, a green shared health
bar, gold ADD and violet MULT. Inactive cameras concentrate on the player and nearby
threats. Skyline drift adds subtle depth behind the stage. Brief impact frames and
red borders indicate actual damage; windups do not trigger red.

The pause ledger uses matching enemy portraits/IDs linked by strings, faded portraits
with X for deaths and a dash for an unborn representation. This replaces all mirages
and player light-beam visuals. Dilation closes role gaps toward a single final frame.
Keep the gameplay lane readable and avoid extra screen-space effects or noisy details.

## 1080p manga combat interface

The 1920×1080 canvas has no detached gameplay header or stock progress bars. A single vector-drawn HUD overlays the active frame: segmented green health blade, amber ADD ribbon, violet three-charge MULT strip, exact counters and a compact gap diagram. Direct and contradiction deaths send bounded ink fragments into the corresponding meter; automatic causal removals never imitate rewards. Every actual hit has a pooled floating number showing final attack damage, including overkill. Native fullscreen is the default; browser fullscreen uses a deliberate input on the Controls page.

Pause is a dark halftone issue spread with offset paper cover edges and slanted buttons. Timeline contains role drags and linked portraits; Field Manual contains all bindings and fullscreen. Preserve keyboard focus and the combat lane, use real-time feedback for short visual effects, and keep presentation independent of damage, score and local simulation clocks.
