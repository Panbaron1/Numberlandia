"""Generate cohesive activity-card art from the app's own numberblock
characters (same pastel palette, rounded squares, and friendly face)."""
import math
from PIL import Image, ImageDraw

S = 600                      # canvas
UNIT = 96                    # one square
GAP = int(UNIT * 0.10)
RAD = int(UNIT * 0.20)
INK = (20, 33, 61, 255)      # navy pupils / number
INK_SOFT = (123, 131, 140, 255)
BROWN = (107, 74, 43, 255)   # smile
OUT = r"C:\Users\milan\Numberlandia\assets\cards"

NUMBLOCK = {
    0: (176, 190, 197), 1: (255, 138, 128), 2: (255, 171, 64),
    3: (255, 215, 64), 4: (105, 240, 174), 5: (64, 196, 255),
    6: (29, 233, 182), 7: (179, 136, 255), 8: (244, 143, 177),
    9: (121, 134, 203), 10: (255, 214, 0),
}

def col(n):
    return NUMBLOCK[n] if n <= 10 else NUMBLOCK[(n - 1) % 10 + 1]

def dims(n):
    if n <= 1:
        return (1, 1)
    root = math.ceil(math.sqrt(n))
    for r in range(root, n + 1):
        if n % r == 0:
            return (r, n // r)
    return (n, 1)

def face(d, x, y, cell):
    cx = x + cell / 2
    ey = y + cell * 0.40
    er = cell * 0.16
    pr = cell * 0.09
    for dx in (-cell * 0.20, cell * 0.20):
        d.ellipse([cx + dx - er, ey - er, cx + dx + er, ey + er], fill=(255, 255, 255, 255))
        d.ellipse([cx + dx - pr, ey - pr, cx + dx + pr, ey + pr], fill=INK)
    sr = cell * 0.20
    sy = y + cell * 0.55
    d.arc([cx - sr, sy - sr, cx + sr, sy + sr], 20, 160, fill=BROWN, width=int(cell * 0.075))

def square(d, x, y, color, unit=UNIT, drawface=False):
    c = color if len(color) == 4 else color + (255,)
    d.rounded_rectangle([x, y, x + unit, y + unit], radius=RAD, fill=c)
    if drawface:
        face(d, x, y, unit)

def block(d, cx, ybottom, n, unit=UNIT, force_color=None):
    """Draw an n-character (square-packed, vertical-first) centred at cx with
    its bottom at ybottom. Returns (width, height)."""
    rows, cols = dims(n)
    c = force_color or col(n)
    gw = cols * unit + (cols - 1) * GAP
    gh = rows * unit + (rows - 1) * GAP
    ox = cx - gw / 2
    oy = ybottom - gh
    for r in range(rows):
        for cc in range(cols):
            x = ox + cc * (unit + GAP)
            y = oy + r * (unit + GAP)
            square(d, x, y, c, unit, drawface=(r == 0 and cc == 0))
    return gw, gh

def plus(d, cx, cy, r=46, w=30, color=INK_SOFT):
    d.rounded_rectangle([cx - r, cy - w / 2, cx + r, cy + w / 2], radius=w / 2, fill=color)
    d.rounded_rectangle([cx - w / 2, cy - r, cx + w / 2, cy + r], radius=w / 2, fill=color)

def arrow(d, x0, x1, cy, w=26, color=INK_SOFT):
    d.rounded_rectangle([x0, cy - w / 2, x1, cy + w / 2], radius=w / 2, fill=color)
    d.polygon([(x1, cy - w * 1.5), (x1 + w * 1.6, cy), (x1, cy + w * 1.5)], fill=color)

def canvas():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)

def save(img, name):
    img.save(f"{OUT}\\{name}.png")
    print("wrote", name)

# ── numberblocks: characters 1 2 3 in a row ─────────────────────────────────
img, d = canvas()
yb = 420
xs = [150, 300, 450]
for cx, n in zip(xs, (1, 2, 3)):
    block(d, cx, yb, n, unit=78)
save(img, "numberblocks")

# ── add up: 2 + 3 ───────────────────────────────────────────────────────────
img, d = canvas()
block(d, 175, 430, 2, unit=86)
plus(d, 300, 300)
block(d, 430, 430, 3, unit=86)
save(img, "addup")

# ── number line: a character standing on a line ─────────────────────────────
img, d = canvas()
d.rounded_rectangle([60, 470, 540, 500], radius=15, fill=(45, 201, 160, 255))  # teal track
for tx in range(100, 541, 90):
    d.rounded_rectangle([tx - 4, 440, tx + 4, 470], radius=4, fill=(45, 201, 160, 180))
block(d, 300, 470, 3, unit=92)
save(img, "numberline")

# ── doubling: 2 -> 4 ────────────────────────────────────────────────────────
img, d = canvas()
block(d, 165, 430, 2, unit=82)
arrow(d, 270, 330, 300)
block(d, 445, 430, 4, unit=82)
save(img, "doubling")

# ── times tables: a 3 x 3 array ─────────────────────────────────────────────
img, d = canvas()
rows = cols = 3
unit = 120
gw = cols * unit + (cols - 1) * GAP
gh = rows * unit + (rows - 1) * GAP
ox = (S - gw) / 2
oy = (S - gh) / 2
tcol = (255, 140, 66)  # times-tables orange
for r in range(rows):
    for c in range(cols):
        x = ox + c * (unit + GAP)
        y = oy + r * (unit + GAP)
        square(d, x, y, tcol, unit, drawface=(r == 0 and c == 0))
save(img, "timestables")

# ── build a million: a tall tower ───────────────────────────────────────────
img, d = canvas()
million = (79, 142, 247)
unit = 82
count = 5
gh = count * unit + (count - 1) * GAP
oy = (S - gh) / 2
cx = S / 2
for i in range(count):
    y = oy + i * (unit + GAP)
    square(d, cx - unit / 2, y, million, unit, drawface=(i == 0))
save(img, "million")

# ── clock: digital time made of numberblocks (1 2 : 3 0) ────────────────────
img, d = canvas()
u = 70
yb = 380
block(d, 130, yb, 1, unit=u)
block(d, 215, yb, 2, unit=u)
# colon
for dy in (-30, 30):
    d.ellipse([300 - 13, yb - 95 + dy - 13, 300 + 13, yb - 95 + dy + 13], fill=INK_SOFT)
block(d, 375, yb, 3, unit=u)
block(d, 500, yb, 4, unit=u)
save(img, "clock")

print("done")
