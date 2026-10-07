"""Pagouro Jigsaw icons (Eric, 2026-10-04): the crab medallion cut into four classic jigsaw pieces, three together and
the fourth nudged a little out of place, with cut lines heavier than in the game so it reads as a jigsaw at icon size.
Colors only from the locked D-74 palette (PAGOURO_BUILD/docs/STYLE_GUIDE.md). Writes jigsaw/art/icon/*.png.

    python tools_src/make_icons.py
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "jigsaw", "art", "icon")
SRC = r"C:\Users\Eric Wade\PAGOURO_BUILD\brand\pagouro_mark_1024.png"
CREAM = (0xEF, 0xE3, 0xC6, 255)   # D-74 poster cream
INK = (0x33, 0x28, 0x22, 255)     # D-74 warm black
GOLD = (0xA8, 0x82, 0x3A, 255)    # D-74 gold ochre

M = 2048                          # master canvas
D = 1500                          # medallion diameter on the master
C = M / 2


def medallion():
    src = Image.open(SRC).convert("RGBA")
    s = src.size[0] / 512
    crop = src.crop((int(105 * s), int(35 * s), int(405 * s), int(335 * s))).resize((D, D), Image.LANCZOS)  # inside the mark's own ring
    mask = Image.new("L", (D, D), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, D - 1, D - 1), fill=255)
    disc = Image.new("RGBA", (D, D), (0, 0, 0, 0))
    disc.paste(crop, (0, 0), mask)
    ImageDraw.Draw(disc).ellipse((0, 0, D - 1, D - 1), outline=GOLD, width=int(D * 0.022))
    full = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    full.alpha_composite(disc, (int(C - D / 2), int(C - D / 2)))
    return full


def tab_edge(a, b, out):
    """Points from a to b with one classic round tab at the middle, bulging to side `out` (+1 / -1) of a->b."""
    ax, ay = a; bx, by = b
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    nx, ny = -uy * out, ux * out
    def P(t, h):
        return (ax + ux * t * L + nx * h * L, ay + uy * t * L + ny * h * L)
    pts = [P(0, 0), P(0.38, 0), P(0.43, 0.035)]
    cx, cy, r = 0.5, 0.15, 0.105
    for k in range(41):
        ang = math.radians(235 - (290 * k / 40))
        pts.append(P(cx + r * math.cos(ang), cy + r * math.sin(ang)))
    pts += [P(0.57, 0.035), P(0.62, 0), P(1, 0)]
    return pts


R = D / 2 + 40  # cuts run a little past the medallion's edge
# the vertical cut, top to bottom: tab to the right above the centre, to the left below
V = tab_edge((C, C - R), (C, C), -1)[:-1] + tab_edge((C, C), (C, C + R), 1)
# the horizontal cut, left to right: tab downward on the left, upward on the right
H = tab_edge((C - R, C), (C, C), -1)[:-1] + tab_edge((C, C), (C + R, C), 1)


def region(left: bool, top: bool):
    """Mask of one quarter: the side of the vertical cut and the side of the horizontal cut."""
    side_v = Image.new("L", (M, M), 0)
    xs = -10 if left else M + 10
    ImageDraw.Draw(side_v).polygon([(xs, -10)] + V + [(xs, M + 10)], fill=255)
    side_h = Image.new("L", (M, M), 0)
    ys = -10 if top else M + 10
    ImageDraw.Draw(side_h).polygon([(-10, ys)] + H + [(M + 10, ys)], fill=255)
    from PIL import ImageChops
    return ImageChops.multiply(side_v, side_h)


def build(size: int, bg) -> Image.Image:
    med = medallion()
    alpha = med.split()[3]
    from PIL import ImageChops
    pieces = []
    for left, top in ((True, True), (False, True), (True, False), (False, False)):
        m = ImageChops.multiply(region(left, top), alpha)
        p = Image.new("RGBA", (M, M), (0, 0, 0, 0))
        p.paste(med, (0, 0), m)
        pieces.append((p, m))
    canvas = Image.new("RGBA", (M, M), bg)
    stroke = int(M * 0.011)  # the cut line: heavier than in the game, so it reads at icon size
    # three together
    for p, m in pieces[:3]:
        canvas.alpha_composite(p)
    lines = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    line = ImageDraw.Draw(lines)
    line.line(V[: len(V) // 2 + 1], fill=INK, width=stroke, joint="curve")  # the cut between the two top pieces
    line.line(H[: len(H) // 2 + 1], fill=INK, width=stroke, joint="curve")  # between the two left pieces
    # the fourth, nudged out and turned a little, with a soft shadow and its own outline
    p, m = pieces[3]
    edge = m.filter(ImageFilter.MaxFilter(9))
    outline = Image.new("RGBA", (M, M), INK)
    outline.putalpha(ImageChops.subtract(edge, m.filter(ImageFilter.MinFilter(stroke // 2 * 2 + 1))))
    loose = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    loose.alpha_composite(p)
    loose.alpha_composite(outline)
    loose = loose.rotate(-7, center=(C, C), resample=Image.BICUBIC)
    shift = (int(D * 0.055), int(D * 0.06))
    shadow = Image.new("RGBA", (M, M), (INK[0], INK[1], INK[2], 0))
    shadow.putalpha(loose.split()[3].point(lambda v: int(v * 0.30)).filter(ImageFilter.GaussianBlur(18)))
    # the joined cuts also meet the loose piece's edges: ink along the rest of both cuts
    line.line(V[len(V) // 2:], fill=INK, width=stroke, joint="curve")
    line.line(H[len(H) // 2:], fill=INK, width=stroke, joint="curve")
    lines.putalpha(ImageChops.multiply(lines.split()[3], alpha))  # only on the medallion
    canvas.alpha_composite(lines)
    canvas.alpha_composite(shadow, (shift[0] + 14, shift[1] + 20))
    canvas.alpha_composite(loose, shift)  # the loose piece above the lines
    # centre the art (the nudge moved its weight down-right) and scale
    bbox = canvas.split()[3].getbbox() if bg[3] == 0 else Image.composite(Image.new("L", (M, M), 255), Image.new("L", (M, M), 0), ImageChops.difference(canvas.convert("RGB"), Image.new("RGB", (M, M), bg[:3])).convert("L").point(lambda v: 255 if v > 8 else 0)).getbbox()
    art = canvas.crop(bbox)
    out = Image.new("RGBA", (M, M), bg)
    out.alpha_composite(art, ((M - art.size[0]) // 2, (M - art.size[1]) // 2))
    return out.resize((size, size), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for size, name in ((192, "icon_192.png"), (256, "icon_256.png"), (512, "icon_512.png")):
        build(size, CREAM).save(os.path.join(OUT, name))
    # iOS: one 1024 icon, square and opaque (no alpha); iOS rounds the corners itself
    build(1024, CREAM).convert("RGB").save(os.path.join(OUT, "icon_ios_1024.png"))
    # adaptive icon: the art inside the 66 % safe zone on a transparent foreground, plain cream behind
    fg = build(432, (0, 0, 0, 0))
    small = fg.resize((300, 300), Image.LANCZOS)
    f = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    f.alpha_composite(small, (66, 66))
    f.save(os.path.join(OUT, "icon_fg_432.png"))
    Image.new("RGBA", (432, 432), CREAM).save(os.path.join(OUT, "icon_bg_432.png"))
    print("icons written to", os.path.normpath(OUT))
