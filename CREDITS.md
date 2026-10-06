# Third-Party Assets

For every external asset:

## Asset name
- Creator:
- Source:
- URL:
- License:
- Files used:
## Kenney Space Station Kit 1.0
- Creator: Kenney (Kenney Vleugels)
- Source: official free asset pack
- URL: https://kenney.nl/assets/space-station-kit
- License: CC0 1.0 Universal; original license included at assets/kenney/station/LICENSE.txt
- Files used: balcony-rail-center.fbx, computer-system.fbx, container-flat.fbx
- Adaptation: toon-lit material overrides and scaled set dressing; no asset collisions.

## Kenney Fonts
- Creator: Kenney
- Source: official free font pack
- URL: https://kenney.nl/assets/kenney-fonts
- License: CC0 1.0 Universal; original license included at assets/kenney/fonts/LICENSE.txt
- Files used: Kenney Future.ttf and Kenney Future Narrow.ttf (renamed locally).

## Original comic presentation
- Industrial deck decorations, impact lettering, procedural humanoid posing,
  and custom rendering shaders are original project code, assisted by OpenAI Codex.
  Character rendering uses the original generated ember sprite family credited below.
- No Hi-Fi Rush assets, models, logos, or characters are included.
- Skyline accents, service balconies, lamps/signals, procedural utility-screen
  graphics, painted tags, grass/rocks and shadow hatching are original project
  geometry/shader code assisted by OpenAI Codex; no additional external assets.

## Quaternius Ultimate Space Kit — workshop props
- Creator: Quaternius
- Source: individual free GLB models on Poly Pizza
- URLs: https://poly.pizza/m/tLs9mFVCSU (Mech), https://poly.pizza/m/ZyUjmgnTyw (Metal Support), https://poly.pizza/m/V7XQDxF8JC (Roof Radar)
- Creator license statement: https://quaternius.com/faq.html
- License: CC0 1.0 Universal; source/license record in assets/quaternius/LICENSE.txt
- Files used: workshop_mech.glb, metal_support.glb, radar.glb
- Adaptation: normalized scale, toon-lit materials, recoloring on support/radar. The mech is static background workshop scenery; no gameplay animations or collisions are imported.

## Original ember character sprite family
- Creator/tool: OpenAI image_gen, prompted and integrated with OpenAI Codex.
- Art direction: user-supplied Dead Cells reference; original masked ember fighters with coordinated armor, scarf, trousers, and weapons.
- Runtime files: `assets/characters/ember/movement.png`, `combat.png`, `grunt.png`, `gunner.png`.
- Source sheets: `art/ember/`; these are excluded from Godot import/export using .gdignore.
- Prompt record: `docs/EMBER_SPRITE_PROMPTS.md`.
- Preparation: `python3 tools/prepare_ember_sprites.py` creates equal-grid 128px frames while preserving alpha.
- No extracted Dead Cells game sprites are included. The former overcrafted character pack has been replaced and removed.

## Rift Courier and comic city revision
- Built-in imagegen: original hero movement/combat sheets, bullet/parry/damage effects,
  and original industrial comic city. No existing-game character image was supplied
  to these generations; combat references only the newly generated hero.
- Sources: `art/ember/{movement,combat,effects}.png`; runtime atlases:
  `assets/characters/ember/`; city: `assets/environment/comic_city.png`.
- Full prompts: `docs/RIFT_COURIER_PROMPTS.md`. Technical slicing uses Pillow;
  damage impact shader and pooled sprite effects are project-authored code.

City panorama revision: built-in imagegen original flat cel-shaded skyline, dark comic outlines, restrained halftone. Replaces the earlier ink illustration at `assets/environment/comic_city.png`. Full skyline now fits each panel camera without texture cropping. Prompt recorded in `docs/RIFT_COURIER_PROMPTS.md`.

## User-supplied sound packs
- `sound/Helton Yan's Pixel Combat`: Helton Yan, Pixel Combat pack, supplied by the project owner.
- `sound/400 Sounds Pack`: supplied by the project owner; author and license were not included in this local folder.
- Used clips and exact original filenames: `assets/audio/SOURCES.json`.
- Runtime adaptations: first variation selected from the Pixel Combat multi-variation WAVs, silent padding trimmed, peaks balanced, mono 44.1 kHz Ogg Vorbis encoding. Tool: `tools/prepare_sound_assets.py` / FFmpeg.
- Only the 37 selected sound-effect WAV masters and three BGM masters remain locally in `sound/`; unused source sounds and the superseded jump clip were removed. `.gdignore` excludes masters from Godot imports/exports and `.gitignore` excludes them from Git. The 37 runtime effects and three runtime tracks in `assets/audio/` are included in the repository. No license terms are inferred from the folder names.

## User-supplied temporal soundtrack
- Source files: `sound/bgm/Iron Velocity.wav` (Past), `heavy rock cover.wav` (Present), `80s Synthwave Remix.wav` (Future).
- Supplied by the project owner; no author/license metadata file accompanied these downloads. No license is inferred from their names.
- Adaptations: stereo 44.1 kHz Ogg Vorbis, loudness matching, aligned 176.256-second loops (the shortest supplied version), and an 80 ms fade at the loop end. Longer versions lose at most 2.7 seconds at the tail.
- Exact durations/source mapping: `assets/audio/music/SOURCES.json`. Reproducible preparation: `tools/prepare_bgm.py`.
