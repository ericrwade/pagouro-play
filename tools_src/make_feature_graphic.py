"""Google Play feature graphic, 1024 x 500: the cut-crab icon, the name, one line, and three of the puzzle pictures as
tilted cards in gold frames. Colors only from the locked D-74 palette; type in the game's own fonts.

    python tools_src/make_feature_graphic.py   ->  store/feature_graphic.png
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ART = os.path.join(ROOT, "jigsaw", "art", "be")
PAPER = (0xEF, 0xE3, 0xC6)
PAPER_DEEP = (0xD9, 0xC9, 0xA6)
INK = (0x33, 0x28, 0x22)
GOLD = (0xA8, 0x82, 0x3A)
GREEN = (0x3A, 0x4A, 0x34)
S = 2  # draw at twice the size, then shrink, for clean edges
W, H = 1024 * S, 500 * S


def font(name, size, weight=None):
    f = ImageFont.truetype(os.path.join(ROOT, "jigsaw", "fonts", name), size * S)
    if weight:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def card(file, size, angle):
    pic = Image.open(os.path.join(ART, file)).convert("RGB").resize((size, size), Image.LANCZOS)
    b = int(size * 0.035)
    framed = Image.new("RGBA", (size + 4 * b, size + 4 * b), PAPER + (255,))
    d = ImageDraw.Draw(framed)
    d.rectangle((0, 0, framed.width - 1, framed.height - 1), outline=GOLD + (255,), width=b)
    framed.paste(pic, (2 * b, 2 * b))
    return framed.rotate(angle, resample=Image.BICUBIC, expand=True)


def shadow_paste(canvas, img, xy):
    sh = Image.new("RGBA", img.size, INK + (0,))
    sh.putalpha(img.split()[3].point(lambda v: int(v * 0.35)).filter(ImageFilter.GaussianBlur(14 * S)))
    canvas.alpha_composite(sh, (xy[0] + 8 * S, xy[1] + 12 * S))
    canvas.alpha_composite(img, xy)


canvas = Image.new("RGBA", (W, H), PAPER + (255,))
d = ImageDraw.Draw(canvas)
# a thin gold double rule around the edge, like the game's frames
d.rectangle((14 * S, 14 * S, W - 14 * S, H - 14 * S), outline=GOLD + (255,), width=3 * S)
d.rectangle((22 * S, 22 * S, W - 22 * S, H - 22 * S), outline=INK + (90,), width=1 * S)
# three pictures, overlapping and tilted
for file, size, angle, xy in (("014-black-cat-red-cushion.jpg", 215, 8, (430, 150)),
                              ("004-eiffel-tower-spring.jpg", 265, -4, (590, 70)),
                              ("015-irises-vase.jpg", 200, -8, (770, 165))):
    shadow_paste(canvas, card(file, size * S, angle), (xy[0] * S, xy[1] * S))
# the icon and the words
icon = Image.open(os.path.join(ROOT, "jigsaw", "art", "icon", "icon_512.png")).convert("RGBA").resize((150 * S, 150 * S), Image.LANCZOS)
mask = Image.new("L", icon.size, 0)
ImageDraw.Draw(mask).ellipse((0, 0, icon.width - 1, icon.height - 1), fill=255)
icon.putalpha(mask)
canvas.alpha_composite(icon, (62 * S, 70 * S))
d = ImageDraw.Draw(canvas)
d.text((62 * S, 238 * S), "Jigsaw", font=font("CormorantGaramond.ttf", 66, 600), fill=GREEN)
d.text((64 * S, 314 * S), "by Pagouro", font=font("CormorantGaramond.ttf", 44, 600), fill=GREEN)
d.text((64 * S, 392 * S), "Free Belle Époque puzzles", font=font("EBGaramond.ttf", 26), fill=INK)
d.text((64 * S, 426 * S), "No ads · no tracking · no account", font=font("EBGaramond.ttf", 21), fill=GOLD)
out = canvas.convert("RGB").resize((1024, 500), Image.LANCZOS)
os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
out.save(os.path.join(ROOT, "store", "feature_graphic.png"))
print("store/feature_graphic.png", out.size)
