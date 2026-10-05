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
- panels snap/resize when switching
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
- future-position mirages visible

Present:
- neutral visual treatment

Future:
- sharper/brighter feeling
- ghost movement traces

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


## Current focus: environment first
Use the supplied Hi-Fi Rush rooftop screenshots as the environment reference.
Open sky, painted cream/teal/red industrial surfaces, discrete violet shadows,
restrained ink lines, and a blue sky with subtle printed halftone dots. Show floor depth with a more
elevated side camera. Characters now use the original ember sprite family: magenta/cyan
swordsman, orange/plum melee revenant, and violet/green carbine revenant. Mirages copy
the real enemy sprite frame rather than using primitive capsules.

Service-wall details should form small clusters around equipment: inset vents,
maintenance hatches, conduit clamps and painted unit numbers. Use red-brown seams
and localized diagonal hatching, not full-surface noise. Keep ink strokes filtered
at inactive-panel sizes. Preserve broad quiet red paint between these clusters
and leave the central combat lane clear. The accepted camera angle stays intact.

Lived-in details follow depth: service balconies behind the stage, utility
displays fastened to the charcoal facade, short grass tufts and
stones at the foreground deck lip (positive Z, in front of the player plane).
The distant skyscrapers, spires and cloud slabs are removed. Shadow hatching
is world-anchored and fades before it becomes subpixel noise. Screens have brief,
low-contrast interference, never full-screen flashes or gameplay warning colors.

Avoid mirrored prop clusters: cargo and a taller signal lamp on the left; a utility
tank and shorter lamp on the right. The lamp posts stand on the main deck with
wide feet and continuous columns; screens bolt to the rear facade. Props need
visible supports. Use broader, more widely spaced shadow hatch strokes rather than dense
fine stripes; preserve the existing filtering and quiet central combat lane.

Lighting uses a lower-angle warm sun, restrained cool ambient fill, warm/cool lamp
pools and a small green screen spill. Local lights must multiply attenuation so
unlit surfaces stay dark; keep the sun as the only shadow-map light for Web.
Street lamps need luminous front/side faces visible to the elevated camera, with
their spotlights emerging from the same fixture. Rear railings sit on the roof
of a continuous charcoal utility building; retain the blue sky above it.

The charcoal roofline must project above the red service roofs in the camera view;
depth and height both affect this. The rear railings align with visible piers on
the charcoal facade. Build lamp silhouettes as continuous floor plate, plinth,
mast, arm and lantern, with a contact mark on the deck. Fasten screens to a
visible wall with brackets. Every prop needs an evident supporting surface.
For the side camera, street-lamp arms must extend along X; an arm extending
only in Z overlaps its pole in projection. Dark support masses need enough value
contrast to remain visible below the sky and between the red service buildings.
