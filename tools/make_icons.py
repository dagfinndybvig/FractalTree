"""Generate FractalTree launcher icons (legacy + adaptive) with PIL.

All geometry in pixel coordinates. The glyph is the sketch's own tree:
night-blue ground, warm branch strokes, pink blossoms at the tips.
"""
import math, os
from PIL import Image, ImageDraw

RES = r"C:\Users\dybvig\Coding\Processing\android\app\src\main\res"
BG = (15, 18, 30)          # same night-blue as the sketch background
TRUNK_LO = (96, 66, 40)    # thick branches: dark brown
TRUNK_HI = (196, 156, 112) # thin branches: light warm brown
BLOSSOM = (255, 150, 178)
SPREAD = 0.60              # radians between parent and child branch
RATIO = 0.75               # child length / parent length

def branch_color(t):
    return tuple(int(a + (b - a) * t) for a, b in zip(TRUNK_LO, TRUNK_HI))

def draw_tree(d, s, x, y, angle, length, width, depth, blossoms, min_w):
    """x, y, length, width, min_w in pixels; angle in radians from vertical."""
    x2 = x + length * math.sin(angle)
    y2 = y - length * math.cos(angle)
    t = 1.0 - depth / 6.0
    d.line([(x, y), (x2, y2)],
           fill=branch_color(t), width=max(int(min_w), int(width)))
    if depth == 0:
        blossoms.append((x2, y2))
        return
    draw_tree(d, s, x2, y2, angle + SPREAD, length * RATIO, width * 0.78,
              depth - 1, blossoms, min_w)
    draw_tree(d, s, x2, y2, angle - SPREAD, length * RATIO, width * 0.78,
              depth - 1, blossoms, min_w)

def render(size, rounded, trunk_len, base_y, trunk_w, depth=5, min_w_frac=0.014):
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.18), fill=BG + (255,))
    else:
        d.rectangle([0, 0, s, s], fill=BG + (255,))
    blossoms = []
    draw_tree(d, s, 0.5 * s, base_y * s, 0.0, trunk_len * s, trunk_w * s,
              depth, blossoms, min_w_frac * s)
    r = s * 0.024
    for (bx, by) in blossoms:
        d.ellipse([bx - r, by - r, bx + r, by + r], fill=BLOSSOM + (230,))
    return img

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

for dpi, k in DENSITIES.items():
    folder = os.path.join(RES, "mipmap-" + dpi)
    os.makedirs(folder, exist_ok=True)
    # legacy launcher icon: rounded square, full tree
    render(int(48 * k), True, 0.22, 0.90, 0.055).save(os.path.join(folder, "ic_launcher.png"))
    # adaptive foreground: transparent, tree inside the 66% safe zone
    render(int(108 * k), False, 0.15, 0.80, 0.040).save(os.path.join(folder, "ic_launcher_foreground.png"))

print("icons written")
