"""Generate the Numberlandia app icon: dark rounded square + rainbow 'N'
(same treatment as the Spectroom 's' icon)."""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BG = (33, 38, 43, 255)          # #21262B (Spectroom dark)
RADIUS = int(SIZE * 0.235)
FONT = r"C:\Users\milan\Numberlandia\assets\fonts\Fredoka.ttf"
OUT = r"C:\Users\milan\Numberlandia\assets\icon\icon.png"

# Pastel spectrum stops, left -> right (Spectroom feel)
STOPS = [
    (0.00, (255, 138, 128)),  # coral
    (0.25, (255, 200, 120)),  # amber
    (0.50, (140, 220, 170)),  # mint
    (0.75, (130, 200, 235)),  # sky
    (1.00, (190, 170, 230)),  # lavender
]

def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def grad_color(x):
    for i in range(len(STOPS) - 1):
        p0, c0 = STOPS[i]
        p1, c1 = STOPS[i + 1]
        if p0 <= x <= p1:
            t = (x - p0) / (p1 - p0)
            return lerp(c0, c1, t)
    return STOPS[-1][1]

# 1) base with rounded-rect dark background
base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(base)
d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=RADIUS, fill=BG)

# 2) 'N' text mask (draw first so we know its exact bounds)
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
try:
    font = ImageFont.truetype(FONT, int(SIZE * 0.82))
    try:
        font.set_variation_by_axes([700])  # heavy weight if variable
    except Exception:
        pass
except Exception:
    font = ImageFont.load_default()

text = "N"
box = md.textbbox((0, 0), text, font=font)
tw, th = box[2] - box[0], box[3] - box[1]
tx = (SIZE - tw) / 2 - box[0]
ty = (SIZE - th) / 2 - box[1]
md.text((tx, ty), text, fill=255, font=font)

# 3) horizontal rainbow gradient spanning the N's actual width, so it shows
#    the full coral->lavender spectrum (like the Spectroom 's').
bb = mask.getbbox()
x0, x1 = bb[0], bb[2]
span = max(1, x1 - x0)
grad = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
gp = grad.load()
for x in range(SIZE):
    t = min(1.0, max(0.0, (x - x0) / span))
    c = grad_color(t)
    for y in range(SIZE):
        gp[x, y] = (c[0], c[1], c[2], 255)

# 4) composite gradient through the N onto the base
base.paste(grad, (0, 0), mask)
base.save(OUT)
print("wrote", OUT)
