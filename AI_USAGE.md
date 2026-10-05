# AI Tool Disclosure

## OpenAI Codex CLI
Used for:
- programming, including the Stage 4 grunt, health, and single-arena wave loop
- implementing Stage 5 arena reuse, isolated viewports, local input gating, and regression checks
- implementing Stage 6 panel switching, local simulation clocks, scaled collision movement, and regression checks
- implementing Stage 7 temporal roles, state-preserving twists, and the Esc pause/panel-selection overlay with regression checks
- simplifying the paused timeline into draggable arena preview cards and role slots
- removing wave-gap acceleration so temporal role clocks remain independent of wave progress
- reproducing and fixing enemy pursuit stalls during locally slowed attack recovery
- widening temporal role speed differences to Past 0.7× and Future 1.3× at user request
- implementing Stage 8 collision-free AI intent mirages/traces, committed strike previews, and regression checks
- simplifying Stage 8 mirages so Past and Future both read only the current Present arena
- implementing Stage 9 forward-only light beams, destination-local swept collision, cooldown/input isolation, and regression checks
- revising light beams to visibly hit exact next-role enemy mirages in the firing panel, removing future-sight prediction and direct Past-to-Future shots
- tuning active roles to 85% / 100% / 115% and making every inactive clock a fixed 10% at user request
- implementing the Stage 10 ranged gunner, telegraphed local projectiles, parry reflection, light mixed waves, and regression checks
- reducing enemy movement by another 15%, halving hostile bullet speed, and simplifying the three-panel encounter into four requested waves
- implementing the Stage 13 first comic visual pass: original articulated silhouettes, ink outlines, flat reactor set dressing, pooled hit/parry typography, and a halftone UI; integrating licensed Kenney fonts and props
- extending Stage 13 with original beveled mesh generation, toon lighting and directional shadows, batched workshop geometry, deck shading, and CC0 Quaternius model integration
- revising Stage 13 toward original anime-inspired humanoids with smooth meshes, sculpted jackets, swept hair, faces, local-clock combat poses, a custom cel shader, and quieter background values
- researching primary anime/toon rendering workflows, replacing primitive figures with the licensed VRoid beta Vita skin, writing a reproducible GLB preparation tool, original texture-aware character/outline/mirage shaders, and local-clock skeletal poses
- rebuilding the environment from user-supplied Hi-Fi Rush references as an open toon rooftop with original discrete-light materials, painted color blocks, restrained ink, layered skyline, and clear combat lane; removing the rejected Vita skin
- detailing the accepted rooftop service walls with original filtered ink hatching, panel seams, painted unit stencils, inset louvers, maintenance hatches, conduit and roof fan details; retaining the camera and gameplay
- adding faint skyline window bands, service balconies, rails, lamps, traffic signals, original procedural glitch screens, wayfinding/graffiti marks, foreground grass/rocks, and world-anchored shadow hatching; screen animation follows each arena's local time and pause
- correcting unsupported scenery with a connected service apron, bolted post/display bases and a rooftop screen mount; breaking mirrored prop layouts into cargo and utility areas; widening and darkening comic shadow hatch strokes
- replacing distant towers with an original filtered halftone sky, relocating all display/lamp feet onto the visible main deck, and adding warm/cool practical lights with corrected toon-material attenuation
- replacing hidden underside lamp strips with visible warm/cool street-lantern diffusers aligned to their spotlights, and restoring a continuous charcoal utility building beneath the rear balconies
- correcting the projected support geometry: raising the charcoal building roof and balcony deck above the red roofs, replacing thin lamp poles with continuous floor-mounted plinths and masts, and bolting the utility screens to the charcoal facade
- diagnosing the invisible supports in an actual rendered game frame, replacing near-black toon-painted foundation and lamp masts with stable flat-painted materials, then adding aligned facade piers and lamp contact marks
- checking the live 1280x720 game view and correcting the street-lamp arms to extend horizontally in the side camera, lengthening the facade piers to the apparent deck line, and moving wall screens clear of the piers
- debugging
- architecture assistance
- testing

## Godot MCP
Used for:
- interacting with Godot
- scene/project inspection
- runtime testing

## ChatGPT
Used for:
- design
- architecture
- development guidance

## Computer Use MCP
Used for:
- refreshing externally changed Godot scenes
- inspecting the running placeholder sandbox

## AI-generated assets
Record generated images/audio/models here.

### Ember character sprites — 2026-10-05
- Built-in OpenAI image_gen generated four original transparent animation sheets:
  player movement (32 frames), player combat (24), melee revenant (24), and gunner (24).
- The user-provided Dead Cells image informed color clustering, scarf, armor,
  athletic silhouette, and faceless/nonhuman heads. Later sheets referenced
  the generated family for consistency; no extracted game sprite is distributed.
- Source files: art/ember/. Runtime atlases: assets/characters/ember/.
- Full prompts: docs/EMBER_SPRITE_PROMPTS.md.
- Codex implemented equal-grid atlas preparation, local-clock state mapping,
  frame/feet alignment, and live sprite mirages. Preparation only slices and
  resizes the generated output; originals and alpha are preserved.

## Rift Courier and comic city revision
- Built-in imagegen: original hero movement/combat sheets, bullet/parry/damage effects,
  and original industrial comic city. No existing-game character image was supplied
  to these generations; combat references only the newly generated hero.
- Sources: `art/ember/{movement,combat,effects}.png`; runtime atlases:
  `assets/characters/ember/`; city: `assets/environment/comic_city.png`.
- Full prompts: `docs/RIFT_COURIER_PROMPTS.md`. Technical slicing uses Pillow;
  damage impact shader and pooled sprite effects are project-authored code.

City panorama revision: built-in imagegen original flat cel-shaded skyline, dark comic outlines, restrained halftone. Replaces the earlier ink illustration at `assets/environment/comic_city.png`. Full skyline now fits each panel camera without texture cropping. Prompt recorded in `docs/RIFT_COURIER_PROMPTS.md`.

Manga presentation revision: code-authored paper halftone UI, ink borders, character contact-shadow shader, camera threat framing and skyline parallax. No new external assets.
