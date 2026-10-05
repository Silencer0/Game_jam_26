# Ember sprite generation prompts

Built-in image_gen was used for all four sheets. The user-supplied image provided visual direction; movement establishes the original character design and subsequent sheets reference the generated family. Original files are preserved under art/ember; runtime atlases are prepared with tools/prepare_ember_sprites.py.

## movement

Use case: stylized-concept. Asset type: production-ready transparent game sprite animation sheet. Reference image is STYLE ONLY, not a character to copy literally. Create an ORIGINAL nonhuman flame-wraith swordsman for FRAME//SHIFT: elongated athletic proportions, no face or human skin, magenta ember plume head with small gold slit, red flowing scarf, dark navy angular shoulder armor, teal luminous forearms, ochre loose trousers, dark violet shadows, cyan boots, a slender chipped cyan energy sword always present. Dead Cells-inspired handcrafted crisp pixel-art clusters, rich strong flat colors, economical pixels, dramatic angular silhouette, no cute/chibi proportions, no soft vector cartoon, no gradients, no huge head. Side-view right-facing ALL frames. Consistent anatomy, clothing, palette, sword, scale throughout.
Exact sheet 1024x2048 pixels, exactly FOUR equal columns and EIGHT equal rows, each cell 256x256. No margins or captions. Precisely one full-body sprite centered horizontally per cell, feet aligned at y=230 within its cell for grounded poses. Character about 160 pixels tall including plume; generous blank space around sword. True transparent background, no grid, no labels, no shadows on ground, no checkerboard painted into output. Every row contains exactly FOUR sequential animation frames, ordered left to right:
row 1 idle: breathing, scarf flicker, return pose.
row 2 run: four genuinely distinct phases of a dynamic running stride with scarf trailing.
row 3 jump: crouch takeoff, rising tucked legs, apex, falling legs extended.
row 4 dash: low forward thrust, acceleration stretched scarf, full-speed sword trailing, recovery.
row 5 parry: sword raise, guard, forceful deflection cyan spark, recovery.
row 6 hurt: recoil, stagger, recover, settle.
row 7 death: knees buckle, collapse, ember fragments, low extinguishing remains.
row 8 beam cast: sword point right, charge, narrow cyan discharge, recovery.
Maintain identical sprite alignment across cells; everything contained within each cell. This is animation material not a character lineup; poses must vary over time.

## combat

Use case: stylized-concept. Asset type: transparent production game animation sprite sheet. Use the attached generated movement sheet as the EXACT character model reference. Create six COMBAT animations of this same original flame-wraith swordsman, matching every design detail and same pixel-art style. Long athletic body, faceless magenta ember head with tiny gold slit, long red scarf, navy angular shoulder plate, cyan arms, ochre trousers, teal boots, cyan chipped sword. Do NOT change proportions, colors, weapon or costume. No human face and no chibi design. Crisp deliberate Dead Cells-inspired colored pixel clusters, flat violet shadows, sharp cyan weapon edges.
Sheet exactly 1024x1536 aspect 2:3, FOUR columns and SIX rows, equal square cells. Each row FOUR sequential frames left-to-right. All frames side-view RIGHT-facing. Sprite height 160 pixels within each 256px cell, centered at x128, grounded feet at y230, no camera motion and no resizing across frames. Everything contained within each cell with transparent padding.
row1 combo attack 1: anticipatory draw-back, horizontal cut to RIGHT, slash follow-through, recovery.
row2 combo attack 2: coil low, upward diagonal cut to RIGHT, high sword follow-through, recover.
row3 combo attack 3: wind-up overhead, strong downward cut to RIGHT, heavy cyan crescent impact, recover.
row4 airborne light: tucked airborne preparation, horizontal right slash, legs tucked follow-through, reset airborne pose.
row5 launcher: deep crouch with blade low, rising uppercut to RIGHT, blade straight up and lifted knee, recover.
row6 diagonal finisher: airborne overhead wind-up, body leaning and blade extending down-right, strong diagonal slash aimed down-right, landing crouch with tiny cyan shards.
Transparent alpha background ONLY, no gridlines, no captions, no ground or drop shadows, no frame borders. Keep the same consistent identity and body pixel scale as the reference sheet. Wide readable weapon arcs, carefully controlled particles, no image noise.

## grunt

Use case: stylized-concept. Asset type: transparent pixel-art game sprite animation sheet for the MELEE ENEMY. Use the attached sheets only as the art-direction and body-proportion reference, creating an original companion enemy from the same world and same artist style. Nonhuman ember-armored revenant, absolutely no human face/skin, lean tall athletic proportions, slightly broader shoulders than the hero, faceless burnt-orange flame head with tiny pale gold slit, short ragged charcoal scarf, angular dark plum armor, ochre trousers and dark boots, pale orange gloved hands. Main hues burnt orange, purple shadows, charcoal. Weapon: ONE broad chipped copper-orange cleaver/sword, consistent shape in every frame. Keep enemy silhouette distinct from cyan/magenta hero yet identical pixel scale and shading approach. Handcrafted Dead Cells-inspired sharply clustered pixel art; controlled highlights, no cute/chibi body, no round huge heads, no soft vector cartoon.
Exact output sheet 1024x1536 aspect2:3 FOUR equal columns SIX equal rows, square cells. FOUR sequential animation frames per row. All frames side-view RIGHT-facing, same scale, full sprite including weapon contained in each cell. Character about160 pixels tall inside256 cell, centered x128, grounded feet baseline y230. No grid/labels/frame borders. Genuine transparent alpha background with zero-alpha empty space; no haze, painted background, shadows, floor, checkerboard.
row1 idle: breathing and orange flame flicker, weapon low right.
row2 run: four distinct dynamic running-stride phases, cleaver held back.
row3 melee attack: threatening wind-up cleaver overhead, blade cuts toward right, forceful follow-through with narrow orange trail, recovery.
row4 hurt: struck backward recoil, stagger, recovery, settle.
row5 launched: legs lift and arms flail, body tips backward, suspended curl, descending legs extended.
row6 death: knees buckle, collapse to right, broken ember armor low, extinguished low remains.
Strict consistent costume and body from frame to frame. Readable quiet empty space around each sprite.

## gunner

Use case: stylized-concept. Asset type: production transparent game sprite sheet for RANGED ENEMY. Use the attached hero and melee sheets as exact visual family references. Create a third ORIGINAL nonhuman masked revenant with same lean tall athletic proportions, same ochre trousers, same angular charcoal/navy armor, same strong colored pixel clusters and violet shadows. The gunner has a pointed dark-violet hood enclosing a green ember spirit, no face, no skin, only ONE tiny green-gold eye slit; short purple torn scarf. A small teal-green glowing compact crossbow-like sci-fi CARBINE with dark stock is its unique weapon, consistently held in both hands and aimed to the RIGHT. Not a sword. Slimmer shoulder silhouette than melee enemy, no giant oversized head, no cute/chibi look. Match the Dead Cells-inspired handcrafted crisp pixel art of the supplied sheets; cohesive detailed color clusters, readable silhouettes, no smooth vector or gradients.
Exact output1024x1536 aspect2:3 FOUR equal columns SIX equal rows, equal256 square cells. Each row precisely FOUR consecutive animation frames; same side-view right-facing camera, consistent clothing/weapon/scale throughout, character160 pixels tall, anchored center x128, grounded feet y230. Genuine transparent alpha background, zero-alpha empty areas; no labels, grid, floor, haze or painted checkerboard.
row1 idle: cautious breathing, carbine pointing diagonally right, scarf twitch.
row2 run: four distinct fast running gait phases carrying same carbine.
row3 shoot: raise carbine to aim right, settle precise aim, small green-white muzzle flash, gun recoils and recovers. Keep muzzle pointed horizontally right in firing frames.
row4 hurt: backward recoil, stagger, recover, settle.
row5 launched: legs lift, body tips backward clutching carbine, suspended curl, descending legs extended.
row6 death: knees buckle, collapse right, hood spirit fragments dissipate, low extinguished body.
Do not enlarge any pose beyond its cell. Keep blank transparent padding and no ground shadow.

