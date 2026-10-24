"""App Store screenshots: the game's own renders (main.gd `-- --shots --shot-size=WxH`) under a short caption.

Input: store/screenshots/raw_iphone/shot_N.png (1320x2868, iPhone 6.9") and raw_ipad/shot_N.png (2064x2752, iPad 13").
Output: store/screenshots/appstore/iphone_N.png and ipad_N.png at exactly those sizes, RGB (Apple rejects alpha).
Colors only from the locked D-74 palette; type in the game's own fonts, like make_feature_graphic.py.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "store", "screenshots")
OUT = os.path.join(SHOTS, "appstore")

PAPER = (0xEF, 0xE3, 0xC6)
INK = (0x33, 0x28, 0x22)
GOLD = (0xA8, 0x82, 0x3A)

# order on the store page: the strongest picture first
ORDER = [
    (2, "Belle Époque pictures,", "real jigsaw cuts"),
    (4, "No timer, no score.", "Just the picture."),
    (1, "Pieces wait in a tray,", "out of your way"),
    (3, "No ads, ever. Help is", "a note about the art"),
    (5, "A new daily puzzle,", "382 pictures in all"),
]


def font(name, size, weight=None):
    f = ImageFont.truetype(os.path.join(ROOT, "jigsaw", "fonts", name), size)
    if weight:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def make(kind, n, line1, line2, size):
    W, H = size
    raw = Image.open(os.path.join(SHOTS, "raw_" + kind, "shot_%d.png" % n)).convert("RGB")
    canvas = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(canvas)
    u = W / 1320.0
    if kind == "ipad":
        u = W / 1700.0
    # double rule round the page, as on the feature graphic
    d.rectangle((int(18 * u), int(18 * u), W - int(18 * u), H - int(18 * u)), outline=GOLD, width=max(3, int(5 * u)))
    d.rectangle((int(32 * u), int(32 * u), W - int(32 * u), H - int(32 * u)), outline=INK, width=max(1, int(2 * u)))
    f = font("CormorantGaramond.ttf", int(104 * u), 600)
    top = int(130 * u)
    for i, line in enumerate((line1, line2)):
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, top + i * int(124 * u)), line, font=f, fill=INK)
    cap_end = top + 2 * int(124 * u) + int(40 * u)
    # the screen, scaled to fit what is left, in a gold frame
    room_h = H - cap_end - int(110 * u)
    room_w = W - int(200 * u)
    k = min(room_w / raw.width, room_h / raw.height)
    sw, sh = int(raw.width * k), int(raw.height * k)
    shot = raw.resize((sw, sh), Image.LANCZOS)
    x, y = (W - sw) // 2, cap_end + (room_h - sh) // 2 + int(30 * u)
    b = max(4, int(8 * u))
    d.rectangle((x - b, y - b, x + sw + b - 1, y + sh + b - 1), fill=GOLD)
    canvas.paste(shot, (x, y))
    canvas.save(os.path.join(OUT, "%s_%d.png" % (kind, ORDER.index((n, line1, line2)) + 1)), optimize=True)


os.makedirs(OUT, exist_ok=True)
for n, l1, l2 in ORDER:
    make("iphone", n, l1, l2, (1320, 2868))
    make("ipad", n, l1, l2, (2064, 2752))
print("written to", OUT)
