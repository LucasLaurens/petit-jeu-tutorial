"""Generate the graveyard background map and the game logo as pixel art.

Run from the repository root:  uv run --with pillow tools/generate_art.py
The seed is fixed, so the output is identical on every run.
"""

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

SEED = 1031
ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "creer-un-jeu-sur-godot-facilement-assets-main" / "art"

# One map pixel covers 6 screen pixels (sprites use 7): 180 x 400 fills the 1080 x 2400 viewport.
MAP_SIZE = (180, 400)

# The sprites use the DawnBringer 16 palette; the map keeps its darkest tones so they stay readable.
OUTLINE = (20, 12, 28)
GROUND = [(27, 31, 51), (33, 38, 63), (40, 46, 74)]
MOSS = (37, 54, 58)
PATH = (58, 47, 59)
PATH_EDGE = (46, 38, 51)
PEBBLE = (78, 74, 78)
STONE = (98, 97, 112)
STONE_LIGHT = (128, 128, 144)
STONE_DARK = (61, 59, 74)
TREE = (42, 29, 46)
GRASS = (47, 74, 58)
SLIME = (109, 170, 44)
SLIME_DARK = (68, 110, 34)
SLIME_LIGHT = (180, 212, 74)
BONE = (200, 196, 176)
WAX = (210, 170, 153)
FLAME = (218, 212, 94)
FLAME_EDGE = (210, 125, 44)
MUSHROOM = (122, 74, 140)
GHOST_SPRITE = ART / "enemyFlyingAlt_1.png"
# Yellow, so the pale ghost stands out against it.
MOON = FLAME
MOON_CRATER = (190, 168, 70)

# Ordered dithering gives the classic 2D pixel-art blend between ground tones.
BAYER_4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

SPRITES = {
    "tomb": [
        "..ooo..",
        ".oLLLo.",
        "oLLLLSo",
        "oLdddSo",
        "oLLLLSo",
        "oLdddSo",
        "oLLLLSo",
        "oSSSSSo",
        "ooooooo",
    ],
    "cross": [
        "..ooo..",
        "..oLo..",
        "oooLooo",
        "oLLLLSo",
        "oooSooo",
        "..oSo..",
        "..oSo..",
        "..oSo..",
        "..ooo..",
    ],
    "tree": [
        "o....o.....o",
        ".o...o....o.",
        "..o..o...o..",
        "..o..o..o...",
        "...o.o.o..o.",
        "....ooo..o..",
        "....oooo....",
        ".....oo.....",
        ".....oo.....",
        ".....oo.....",
        ".....oo.....",
        "....oooo....",
        "...oo..oo...",
    ],
    "bone": ["b...b", ".bbb.", "b...b"],
    "skull": [".bbb.", "bobob", "bbbbb", ".b.b."],
    "candle": [".y.", ".f.", ".w.", ".w.", "www"],
    "mushroom": [".m.", "mmm", ".b."],
    "grass": ["g.g.g", ".g.g."],
}
SPRITE_COLORS = {
    "o": OUTLINE,
    "L": STONE_LIGHT,
    "S": STONE_DARK,
    "d": STONE,
    "b": BONE,
    "y": FLAME,
    "f": FLAME_EDGE,
    "w": WAX,
    "m": MUSHROOM,
    "g": GRASS,
}
TREE_SPRITE_COLORS = {**SPRITE_COLORS, "o": TREE}


def build_noise(rng: random.Random, size: tuple[int, int], cells: tuple[int, int]) -> Image.Image:
    coarse = Image.new("L", cells)
    coarse.putdata([rng.randrange(256) for _ in range(cells[0] * cells[1])])
    return coarse.resize(size, Image.BICUBIC)


def paint_ground(img: Image.Image, rng: random.Random) -> None:
    # O(w * h) time, O(w * h) space for the noise layers.
    width, height = img.size
    tone_noise = build_noise(rng, img.size, (10, 22)).load()
    moss_noise = build_noise(rng, img.size, (6, 12)).load()
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            threshold = (BAYER_4[y % 4][x % 4] + 0.5) / 16
            level = tone_noise[x, y] / 256 * (len(GROUND) - 1)
            base = int(level)
            tone = GROUND[min(base + (level - base > threshold), len(GROUND) - 1)]
            if moss_noise[x, y] > 170 and BAYER_4[y % 4][x % 4] < (moss_noise[x, y] - 170) / 5:
                tone = MOSS
            pixels[x, y] = tone


def compute_paths(width: int, height: int) -> list[set[tuple[int, int]]]:
    """Return the path pixels: a winding north-south trail and an east-west one."""
    vertical = set()
    for y in range(height):
        center = width / 2 + 38 * math.sin(y / 61 + 1.2) + 10 * math.sin(y / 19)
        half = 5 + math.sin(y / 7)
        vertical.update((x, y) for x in range(int(center - half), int(center + half) + 1))
    horizontal = set()
    for x in range(width):
        center = height * 0.62 + 16 * math.sin(x / 27 + 0.4)
        half = 4 + math.sin(x / 5)
        horizontal.update((x, y) for y in range(int(center - half), int(center + half) + 1))
    return [vertical, horizontal]


def paint_paths(img: Image.Image, rng: random.Random, path: set[tuple[int, int]]) -> None:
    pixels = img.load()
    width, height = img.size
    for x, y in path:
        if not (0 <= x < width and 0 <= y < height):
            continue
        is_edge = any((x + dx, y + dy) not in path for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        pixels[x, y] = PATH_EDGE if is_edge else PATH
        if not is_edge and rng.random() < 0.04:
            pixels[x, y] = PEBBLE


def stamp(img: Image.Image, name: str, at: tuple[int, int], colors: dict[str, tuple[int, int, int]]) -> None:
    pixels = img.load()
    for dy, row in enumerate(SPRITES[name]):
        for dx, char in enumerate(row):
            x, y = at[0] + dx, at[1] + dy
            if char != "." and 0 <= x < img.width and 0 <= y < img.height:
                pixels[x, y] = colors[char]


def paint_shadow(img: Image.Image, center: tuple[int, int], radius_x: int) -> None:
    pixels = img.load()
    for dx in range(-radius_x, radius_x + 1):
        x, y = center[0] + dx, center[1]
        if 0 <= x < img.width and 0 <= y < img.height:
            pixels[x, y] = OUTLINE if abs(dx) < radius_x else GROUND[0]


def paint_glow(img: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int]) -> None:
    # Dithered halo: the further from the centre, the fewer lit pixels.
    pixels = img.load()
    for y in range(center[1] - radius, center[1] + radius + 1):
        for x in range(center[0] - radius, center[0] + radius + 1):
            if not (0 <= x < img.width and 0 <= y < img.height):
                continue
            distance = math.dist((x, y), center) / radius
            if distance < 1 and BAYER_4[y % 4][x % 4] / 16 > distance + 0.25:
                pixels[x, y] = tuple((a + b) // 2 for a, b in zip(pixels[x, y], color))


def paint_slime_pond(img: Image.Image, rng: random.Random, center: tuple[int, int]) -> set[tuple[int, int]]:
    blobs = [(center[0] + rng.randint(-8, 8), center[1] + rng.randint(-5, 5), rng.randint(5, 8)) for _ in range(4)]
    pond = {
        (x, y)
        for bx, by, r in blobs
        for y in range(by - r, by + r + 1)
        for x in range(bx - r - 3, bx + r + 4)
        if ((x - bx) / (r + 3)) ** 2 + ((y - by) / r) ** 2 <= 1
    }
    paint_glow(img, center, 22, SLIME_DARK)
    pixels = img.load()
    for x, y in pond:
        is_edge = any((x + dx, y + dy) not in pond for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        pixels[x, y] = SLIME_DARK if is_edge else SLIME
    for _ in range(10):
        x, y = rng.choice(sorted(pond))
        if (x + 1, y) in pond and (x - 1, y) in pond:
            pixels[x, y] = SLIME_LIGHT
    return pond


def find_free_spot(
    rng: random.Random, blocked: set[tuple[int, int]], size: tuple[int, int], area: tuple[int, int, int, int]
) -> tuple[int, int] | None:
    for _ in range(60):
        x, y = rng.randint(area[0], area[2] - size[0]), rng.randint(area[1], area[3] - size[1])
        footprint = {(x + dx, y + dy) for dx in range(-2, size[0] + 2) for dy in range(-2, size[1] + 3)}
        if not footprint & blocked:
            blocked.update(footprint)
            return x, y
    return None


def place_graveyard(img: Image.Image, rng: random.Random, blocked: set[tuple[int, int]], origin: tuple[int, int]) -> None:
    """A fenced plot with rows of graves."""
    cols, rows = 3, 2
    width, height = cols * 12 + 4, rows * 15 + 6
    plot = {(origin[0] + dx, origin[1] + dy) for dx in range(width) for dy in range(height)}
    if plot & blocked:
        return
    blocked.update(plot)
    draw = ImageDraw.Draw(img)
    left, top, right, bottom = origin[0], origin[1], origin[0] + width - 1, origin[1] + height - 1
    for x in range(left, right + 1, 3):
        draw.line([(x, top - 2), (x, top)], fill=OUTLINE)
        draw.line([(x, bottom - 2), (x, bottom)], fill=OUTLINE)
    draw.line([(left, top - 1), (right, top - 1)], fill=OUTLINE)
    draw.line([(left, bottom - 1), (right, bottom - 1)], fill=OUTLINE)
    draw.line([(left, top), (left, bottom)], fill=OUTLINE)
    draw.line([(right, top), (right, bottom)], fill=OUTLINE)
    for row in range(rows):
        for col in range(cols):
            x, y = left + 4 + col * 12, top + 3 + row * 15
            paint_shadow(img, (x + 3, y + 9), 4)
            stamp(img, rng.choice(["tomb", "tomb", "cross"]), (x, y), SPRITE_COLORS)


def scatter(
    img: Image.Image,
    rng: random.Random,
    blocked: set[tuple[int, int]],
    name: str,
    count: int,
    colors: dict[str, tuple[int, int, int]] = SPRITE_COLORS,
) -> list[tuple[int, int]]:
    size = (len(SPRITES[name][0]), len(SPRITES[name]))
    placed = []
    for _ in range(count):
        spot = find_free_spot(rng, blocked, size, (0, 0, img.width, img.height))
        if spot:
            stamp(img, name, spot, colors)
            placed.append(spot)
    return placed


def paint_vignette(img: Image.Image) -> None:
    # Darker edges frame the play area and pull the eye to the centre.
    pixels = img.load()
    cx, cy = img.width / 2, img.height / 2
    for y in range(img.height):
        for x in range(img.width):
            distance = math.hypot((x - cx) / cx, (y - cy) / cy) / math.sqrt(2)
            if distance > 0.55 and BAYER_4[y % 4][x % 4] / 16 < (distance - 0.55) * 2.2:
                pixels[x, y] = tuple(c * 3 // 4 for c in pixels[x, y])


def generate_map() -> Image.Image:
    rng = random.Random(SEED)
    img = Image.new("RGB", MAP_SIZE)
    paint_ground(img, rng)
    paths = compute_paths(*MAP_SIZE)
    for path in paths:
        paint_paths(img, rng, path)
    blocked = set().union(*paths)
    blocked |= paint_slime_pond(img, rng, (130, 330))
    for origin in [(10, 30), (120, 120), (14, 300)]:
        place_graveyard(img, rng, blocked, origin)
    for name, count in [("tree", 7), ("tomb", 6), ("cross", 4)]:
        for x, y in scatter(img, rng, blocked, name, count, TREE_SPRITE_COLORS if name == "tree" else SPRITE_COLORS):
            if name != "tree":
                paint_shadow(img, (x + 3, y + 9), 4)
    for name, count in [("grass", 70), ("mushroom", 14), ("bone", 12), ("skull", 4)]:
        scatter(img, rng, blocked, name, count)
    for x, y in scatter(img, rng, blocked, "candle", 6):
        paint_glow(img, (x + 1, y), 7, FLAME_EDGE)
        stamp(img, "candle", (x, y), SPRITE_COLORS)
    paint_vignette(img)
    return img


def build_logo_layer(canvas: int, with_background: bool) -> Image.Image:
    """The logo: the game's ghost in front of the moon, centred in `canvas` pixels."""
    img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset = (canvas - 32) // 2
    draw = ImageDraw.Draw(img)
    if with_background:
        draw.rounded_rectangle([offset, offset, offset + 31, offset + 31], radius=5, fill=GROUND[0] + (255,))
    draw.ellipse([offset + 17, offset + 2, offset + 30, offset + 15], fill=MOON + (255,))
    draw.rectangle([offset + 25, offset + 5, offset + 26, offset + 6], fill=MOON_CRATER + (255,))
    draw.rectangle([offset + 27, offset + 10, offset + 28, offset + 11], fill=MOON_CRATER + (255,))
    ghost = Image.open(GHOST_SPRITE).convert("RGBA").resize((24, 32), Image.NEAREST)
    img.alpha_composite(ghost.crop((0, 0, 24, 26)), (offset + 2, offset + 5))
    return img


def generate_logo() -> dict[Path, Image.Image]:
    logo = build_logo_layer(32, with_background=True)
    background = Image.new("RGBA", (54, 54), GROUND[0] + (255,))
    icons = ART / "icons"
    return {
        ROOT / "icon.png": logo.resize((512, 512), Image.NEAREST),
        icons / "launcher_192.png": logo.resize((192, 192), Image.NEAREST),
        # Android adaptive icons: 432 px, launchers may mask all but a central circle of 288 px.
        # The 32-pixel logo in a 54-pixel canvas keeps the ghost and moon inside that circle.
        icons / "adaptive_foreground_432.png": build_logo_layer(54, with_background=False).resize((432, 432), Image.NEAREST),
        icons / "adaptive_background_432.png": background.resize((432, 432), Image.NEAREST),
    }


def main() -> None:
    generate_map().save(ART / "graveyard_map.png", optimize=True)
    for path, image in generate_logo().items():
        path.parent.mkdir(exist_ok=True)
        image.save(path, optimize=True)


if __name__ == "__main__":
    main()
