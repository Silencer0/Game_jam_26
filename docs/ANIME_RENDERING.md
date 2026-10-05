# Environment-first toon 3D direction

## Reference
The user's three Hi-Fi Rush screenshots are the current visual target: ordinary
painted colors on actual 3D geometry, clean ink lines, discrete colored shadows,
cream/teal/red industrial structures, a clear foreground, blue sky and pale distant
city forms. A vague anime label, grey materials or a generic avatar do not achieve
this direction. The rejected Vita model has been removed from the repository.
Character design is deferred until the environment direction is accepted.

## Tutorials and sources researched
- Tango Gameworks, GDC 2024: **3D Toon Rendering in Hi-Fi RUSH**.
  https://gdcvault.com/play/1034330/3D-Toon-Rendering-in-Hi
  https://www.youtube.com/watch?v=gdBACyIOCtc
  The source describes toon shading of both characters and the entire world,
  coordinated comic shaders, toon lighting and static/dynamic shadow strategies.
  Its deferred Unreal renderer is not directly portable to Godot Compatibility.
- Rafael Bordoni: **Godot 4 Complete Cel Shader**, source and companion tutorial.
  https://github.com/eldskald/godot4-cel-shader
  The authored tutorial documents a discrete diffuse curve and inverted-hull
  outlines. This project implements its own small forward-rendered materials;
  no tutorial code or demo assets are copied.
- Watt Interactive: **Easy Toon Style in Godot**.
  https://www.youtube.com/watch?v=rAU7nPclNtA
  The published tutorial outline distinguishes design, lighting and materials.
- Godot spatial shader documentation:
  https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html

## Implemented
- An open rooftop replaces the closed grey workshop and opaque rear wall.
- Actual 3D service buildings, roof vents, pipes and deck trim use cream, teal,
  ochre and warm red with a deliberately limited palette.
- A three-level light ramp replaces continuously shaded/metallic materials.
- Quantized cast shadows have a violet cast; no shiny PBR highlights.
- Thin inverted-hull outlines are on near scenery; distant silhouettes omit ink.
- A blue halftone sky replaces the skyline towers, spires and cloud slabs.
- The floor uses broad, low-frequency seams; no dense tread or screen grain.
- Set dressing is noncolliding and batched. Gameplay collision and clocks remain.
- Player, enemies and mirages are temporary colored capsule markers.
- Service walls have red-brown printed seams and small derivative-filtered hatch
  patches, with inset louvers, maintenance doors, conduit clamps and unit stencils.
  Roof equipment has fan spokes, grille marks and roof joints. These decorations
  are static, noncolliding, and reuse material batches wherever possible.

## Verification and limits
The skyline is now a clean blue halftone field. Service balconies,
rails, lamps, signals and two subdued utility screens add middle-distance detail;
grass and stones sit on the near deck lip. Screen interference follows arena-local
time and pause. World-space hatching affects shaded scenery, with derivative
filtering to suppress distant shimmer. Two fixture-mounted spotlights and a small
screen spill add local color, balanced against a dimmer low-angle sun and ambient
fill. Local falloff follows Godot ATTENUATION (see the linked spatial shader
reference). Only the sun casts mapped shadows. Both lamp posts have continuous
floor-mounted plinths and columns. The screens mount to the charcoal utility
building, whose roof supports the two railings above the red service roofs.

Parser/runtime and gameplay checks are automated. No screenshots or visual review
are performed, following the user's testing preference. Browser speed, outline
thickness and the art direction require manual review. This is an environment art
iteration, not a claim of equivalence to Hi-Fi Rush's full art/animation pipeline.
