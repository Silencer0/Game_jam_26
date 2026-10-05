"""Normalize generated equal-grid sheets into small runtime atlases.

This only slices/resizes the generated frames; it does not redraw the art.
Pillow is a development-only dependency. Original alpha is preserved.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CELL = 128
ROWS = {"movement": 8, "combat": 6, "grunt": 6, "gunner": 6, "effects": 4}

for name, rows in ROWS.items():
    source = Image.open(ROOT / "art" / "ember" / f"{name}.png").convert("RGBA")
    if source.getchannel("A").getextrema()[0] != 0:
        raise ValueError(f"{name}: source is missing transparent background")
    atlas = Image.new("RGBA", (CELL * 4, CELL * rows))
    for row in range(rows):
        for column in range(4):
            bounds = (
                round(column * source.width / 4),
                round(row * source.height / rows),
                round((column + 1) * source.width / 4),
                round((row + 1) * source.height / rows),
            )
            frame = source.crop(bounds)
            if frame.getchannel("A").getbbox() is None:
                raise ValueError(f"{name}: empty frame {row}, {column}")
            frame = frame.resize((CELL, CELL), Image.Resampling.NEAREST)
            atlas.paste(frame, (column * CELL, row * CELL))
    destination = ROOT / "assets" / "characters" / "ember" / f"{name}.png"
    destination.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(destination, optimize=True)
    print(f"{name}: {4 * rows} frames, {atlas.width}x{atlas.height}")
