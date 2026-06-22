"""Generate cohesive activity-card art: a soft, slightly grainy spectrum
gradient (blue -> teal -> lavender -> pink, blended toward each card's accent)
with the activity's own numberblock characters crisp in the foreground.

The backdrop is intentionally calm and low-contrast so it never competes with
the foreground characters. Same pastel palette, rounded squares, friendly face."""
import math
from PIL import Image, ImageDraw

# Soft spectrum (matches the in-app wordmark / room backgrounds)
SPECTRUM = [(79, 142, 247), (45, 201, 160), (167, 139, 250), (255, 107, 157)]


def _lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _soft(c, accent):
    c = _lerp(c, (255, 255, 255), 0.66)  # lift well toward white (lighter)
    return _lerp(c, accent, 0.11)        # faint nudge toward the card accent


def _multi(stops, t):
    t = max(0.0, min(1.0, t))
    seg = t * (len(stops) - 1)
    i = min(int(seg), len(stops) - 2)
    return _lerp(stops[i], stops[i + 1], seg - i)


def grad_bg(img, accent):
    """Full-bleed diagonal spectrum gradient + fine grain, tinted by accent."""
    stops = [_soft(c, accent) for c in SPECTRUM]
    L = 2 * (S - 1)
    lut = [_multi(stops, i / L) for i in range(L + 1)]
    g = Image.new("RGB", (S, S))
    g.putdata([lut[x + y] for y in range(S) for x in range(S)])
    img.paste(g, (0, 0))
    # fine film grain
    noise = Image.effect_noise((S, S), 18).convert("L")
    overlay = Image.merge("RGBA", (noise, noise, noise, Image.new("L", (S, S), 18)))
    img.alpha_composite(overlay)

S = 600                      # canvas (square, rendered BoxFit.cover in-app)
UNIT = 96                    # one foreground square
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

# scenery palette (pastel, calm)
SKY_TOP = (205, 233, 255)
SKY_BOT = (233, 247, 255)
GRASS_TOP = (183, 228, 168)
GRASS_BOT = (151, 209, 140)
FOLIAGE = (138, 205, 150)
FOLIAGE2 = (110, 188, 138)
TRUNK = (181, 140, 99)
WALL = (255, 226, 184)
ROOF = (255, 168, 142)
DOOR = (181, 140, 99)
POND = (150, 210, 235)
POND_EDGE = (120, 190, 220)
CLOUD = (255, 255, 255)
SUN = (255, 234, 160)
HORIZON = 392               # grass starts here


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


def minus(d, cx, cy, r=46, w=30, color=INK_SOFT):
    d.rounded_rectangle([cx - r, cy - w / 2, cx + r, cy + w / 2], radius=w / 2, fill=color)


def arrow(d, x0, x1, cy, w=26, color=INK_SOFT):
    d.rounded_rectangle([x0, cy - w / 2, x1, cy + w / 2], radius=w / 2, fill=color)
    d.polygon([(x1, cy - w * 1.5), (x1 + w * 1.6, cy), (x1, cy + w * 1.5)], fill=color)


def shadow(d, cx, ybottom, w):
    """Soft ground ellipse so foreground characters sit on the grass."""
    d.ellipse([cx - w / 2, ybottom - 14, cx + w / 2, ybottom + 14],
              fill=(26, 31, 54, 55))


# ── scenery primitives ──────────────────────────────────────────────────────

def vgrad(draw, x0, y0, x1, y1, top, bot):
    """Vertical gradient fill in [y0,y1) across [x0,x1)."""
    h = max(1, y1 - y0)
    for i in range(h):
        t = i / h
        c = tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3))
        draw.line([(x0, y0 + i), (x1, y0 + i)], fill=c + (255,))


def cloud(d, cx, cy, scale=1.0):
    r = 34 * scale
    for dx, dy, rr in [(-r, 4, r), (0, -r * 0.5, r * 1.25), (r, 4, r), (0, 8, r * 1.3)]:
        d.ellipse([cx + dx - rr, cy + dy - rr, cx + dx + rr, cy + dy + rr], fill=CLOUD + (255,))


def sun(d, cx, cy, r=46):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN + (255,))


def tree(d, cx, base, scale=1.0):
    """Numberblock tree: brown trunk + stack of rounded green squares."""
    u = 46 * scale
    tw = u * 0.5
    d.rounded_rectangle([cx - tw / 2, base - u * 1.1, cx + tw / 2, base],
                        radius=tw * 0.3, fill=TRUNK + (255,))
    # canopy: 3 squares (2 over 1) in numberblock style
    cy = base - u * 1.1
    d.rounded_rectangle([cx - u / 2, cy - u, cx + u / 2, cy],
                        radius=u * 0.22, fill=FOLIAGE2 + (255,))
    for dx in (-u * 0.55, u * 0.55):
        d.rounded_rectangle([cx + dx - u / 2, cy - u * 1.9, cx + dx + u / 2, cy - u * 0.9],
                            radius=u * 0.22, fill=FOLIAGE + (255,))
    d.rounded_rectangle([cx - u / 2, cy - u * 2.7, cx + u / 2, cy - u * 1.7],
                        radius=u * 0.22, fill=FOLIAGE + (255,))


def bush(d, cx, base, scale=1.0):
    u = 40 * scale
    for dx in (-u * 0.45, u * 0.45):
        d.rounded_rectangle([cx + dx - u / 2, base - u, cx + dx + u / 2, base],
                            radius=u * 0.25, fill=FOLIAGE + (255,))
    d.rounded_rectangle([cx - u / 2, base - u * 1.5, cx + u / 2, base - u * 0.5],
                        radius=u * 0.25, fill=FOLIAGE2 + (255,))


def house(d, cx, base, scale=1.0):
    """Numberblock house: square wall + triangle roof + door + window."""
    w = 96 * scale
    wall_top = base - w
    d.rounded_rectangle([cx - w / 2, wall_top, cx + w / 2, base],
                        radius=w * 0.12, fill=WALL + (255,))
    # roof
    d.polygon([(cx - w * 0.62, wall_top + 6), (cx, wall_top - w * 0.5),
               (cx + w * 0.62, wall_top + 6)], fill=ROOF + (255,))
    # door
    dw = w * 0.26
    d.rounded_rectangle([cx - dw / 2, base - w * 0.5, cx + dw / 2, base],
                        radius=dw * 0.2, fill=DOOR + (255,))
    # window
    ws = w * 0.22
    d.rounded_rectangle([cx + w * 0.16, wall_top + w * 0.18,
                         cx + w * 0.16 + ws, wall_top + w * 0.18 + ws],
                        radius=ws * 0.2, fill=POND + (255,))


def pond(d, cx, cy, w=170, h=64):
    d.ellipse([cx - w / 2 - 6, cy - h / 2 - 6, cx + w / 2 + 6, cy + h / 2 + 6],
              fill=POND_EDGE + (255,))
    d.ellipse([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], fill=POND + (255,))
    # ripple
    d.arc([cx - w * 0.18, cy - h * 0.1, cx + w * 0.18, cy + h * 0.25],
          200, 340, fill=(255, 255, 255, 200), width=3)


def duck(d, cx, base, scale=1.0):
    """Tiny numberblock duck (yellow square + beak + eye)."""
    u = 30 * scale
    d.rounded_rectangle([cx - u / 2, base - u, cx + u / 2, base],
                        radius=u * 0.25, fill=(255, 213, 79, 255))
    # beak
    d.polygon([(cx + u * 0.5, base - u * 0.55), (cx + u * 0.95, base - u * 0.4),
               (cx + u * 0.5, base - u * 0.25)], fill=(255, 152, 0, 255))
    # eye
    d.ellipse([cx + u * 0.05, base - u * 0.78, cx + u * 0.25, base - u * 0.58], fill=INK)


def cat(d, cx, base, scale=1.0):
    """Tiny numberblock cat (square body + ears + face)."""
    u = 38 * scale
    top = base - u
    # ears
    d.polygon([(cx - u * 0.42, top), (cx - u * 0.18, top - u * 0.35), (cx - u * 0.02, top)],
              fill=(179, 136, 255, 255))
    d.polygon([(cx + u * 0.02, top), (cx + u * 0.18, top - u * 0.35), (cx + u * 0.42, top)],
              fill=(179, 136, 255, 255))
    d.rounded_rectangle([cx - u / 2, top, cx + u / 2, base], radius=u * 0.25,
                        fill=(179, 136, 255, 255))
    for dx in (-u * 0.18, u * 0.18):
        d.ellipse([cx + dx - u * 0.07, top + u * 0.3, cx + dx + u * 0.07, top + u * 0.44], fill=INK)


PINE = (127, 196, 138)


def pine(d, cx, base, scale=1.0):
    """Blocky pine — stacked triangles on a short trunk."""
    u = 46 * scale
    tw = u * 0.34
    d.rounded_rectangle([cx - tw / 2, base - u * 0.5, cx + tw / 2, base],
                        radius=tw * 0.3, fill=TRUNK + (255,))
    for i in range(3):
        ty = base - u * 0.5 - i * u * 0.7
        spread = u * (1.1 - i * 0.28)
        d.polygon([(cx - spread, ty), (cx, ty - u * 1.0), (cx + spread, ty)],
                  fill=PINE + (255,))


def flower(d, cx, base, scale=1.0, petal=ROOF):
    """Tiny flower — stem + four petals + sun centre."""
    u = 40 * scale
    d.rectangle([cx - u * 0.05, base - u, cx + u * 0.05, base], fill=FOLIAGE2 + (255,))
    cy = base - u
    pr = u * 0.22
    for ox, oy in [(0, -u * 0.34), (0, u * 0.34), (-u * 0.34, 0), (u * 0.34, 0)]:
        d.ellipse([cx + ox - pr, cy + oy - pr, cx + ox + pr, cy + oy + pr],
                  fill=petal + (255,))
    d.ellipse([cx - u * 0.18, cy - u * 0.18, cx + u * 0.18, cy + u * 0.18],
              fill=(255, 234, 160, 255))


def bird(d, cx, cy, scale=1.0, col=(191, 211, 230)):
    """Tiny numberblock bird in the sky."""
    u = 34 * scale
    d.rounded_rectangle([cx - u / 2, cy - u / 2, cx + u / 2, cy + u / 2],
                        radius=u * 0.32, fill=col + (255,))
    d.polygon([(cx + u * 0.5, cy - u * 0.05), (cx + u * 0.85, cy + u * 0.02),
               (cx + u * 0.5, cy + u * 0.12)], fill=(255, 152, 0, 255))
    d.ellipse([cx + u * 0.05, cy - u * 0.2, cx + u * 0.2, cy - u * 0.05], fill=INK)


def scene(img, d, *, sunside="left", trees=(), houses=(), pond_xy=None,
          clouds=(), bushes=(), ducks=(), cats=(), pines=(), flowers=(), birds=()):
    """Compose a calm world: sky gradient, grass, then scattered scenery.
    All scenery is drawn here; a white veil mutes it before the foreground."""
    vgrad(d, 0, 0, S, HORIZON, SKY_TOP, SKY_BOT)
    vgrad(d, 0, HORIZON, S, S, GRASS_TOP, GRASS_BOT)
    # gentle rolling hill behind the grass line
    d.ellipse([-120, HORIZON - 70, 320, HORIZON + 160], fill=(168, 222, 156, 255))
    d.ellipse([300, HORIZON - 50, 760, HORIZON + 180], fill=(176, 226, 162, 255))
    if sunside:
        sun(d, 70 if sunside == "left" else S - 70, 78)
    for cx, cy, sc in clouds:
        cloud(d, cx, cy, sc)
    for cx, sc in houses:
        house(d, cx, HORIZON + 28, sc)
    for cx, sc in trees:
        tree(d, cx, HORIZON + 36, sc)
    for cx, sc in pines:
        pine(d, cx, HORIZON + 34, sc)
    for cx, sc in bushes:
        bush(d, cx, HORIZON + 30, sc)
    for cx, sc, petal in flowers:
        flower(d, cx, HORIZON + 40, sc, petal)
    if pond_xy:
        pond(d, *pond_xy)
    for cx, b, sc in ducks:
        duck(d, cx, b, sc)
    for cx, b, sc in cats:
        cat(d, cx, b, sc)
    for cx, cy, sc in birds:
        bird(d, cx, cy, sc)
    # white veil → push scenery back so foreground pops
    veil = Image.new("RGBA", (S, S), (255, 255, 255, 96))
    img.alpha_composite(veil)


def canvas():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, name):
    img.save(f"{OUT}\\{name}.png")
    print("wrote", name)


# ── numberblocks: characters 1 2 3 on a grassy hill, trees + house behind ────
img, d = canvas()
grad_bg(img, (167, 139, 250))
d = ImageDraw.Draw(img)
yb = 470
for cx, n in zip((175, 320, 470), (1, 2, 3)):
    shadow(d, cx, yb, 72)
    block(d, cx, yb, n, unit=74)
save(img, "numberblocks")

# ── add up: 2 + 3 in a sunny garden ──────────────────────────────────────────
img, d = canvas()
grad_bg(img, (52, 199, 89))
d = ImageDraw.Draw(img)
yb = 470
shadow(d, 185, yb, 110)
_, ha = block(d, 185, yb, 2, unit=84)
shadow(d, 430, yb, 150)
_, hb = block(d, 430, yb, 3, unit=84)
plus(d, 305, yb - (ha + hb) / 4)  # midpoint of the two tower centres
save(img, "addup")

# ── number line: a character on a path, trees lining it ──────────────────────
img, d = canvas()
grad_bg(img, (45, 201, 160))
d = ImageDraw.Draw(img)
d.rounded_rectangle([50, 486, 550, 516], radius=15, fill=(45, 201, 160, 255))  # teal track
for tx in range(95, 541, 90):
    d.rounded_rectangle([tx - 4, 458, tx + 4, 486], radius=4, fill=(45, 201, 160, 220))
shadow(d, 300, 486, 100)
block(d, 300, 486, 3, unit=90)
save(img, "numberline")

# ── doubling: 2 -> 4, pond + duck ────────────────────────────────────────────
img, d = canvas()
grad_bg(img, (255, 107, 157))
d = ImageDraw.Draw(img)
yb = 470
shadow(d, 175, yb, 100)
_, hd1 = block(d, 175, yb, 2, unit=80)
shadow(d, 445, yb, 150)
_, hd2 = block(d, 445, yb, 4, unit=80)
arrow(d, 270, 330, yb - (hd1 + hd2) / 4)
save(img, "doubling")

# ── times tables: a 3x3 array in a tidy orchard ──────────────────────────────
img, d = canvas()
grad_bg(img, (255, 140, 66))
d = ImageDraw.Draw(img)
rows = cols = 3
unit = 112
gw = cols * unit + (cols - 1) * GAP
gh = rows * unit + (rows - 1) * GAP
ox = (S - gw) / 2
oy = (S - gh) / 2 + 24
tcol = (255, 140, 66)
shadow(d, S / 2, oy + gh, gw)
for r in range(rows):
    for c in range(cols):
        x = ox + c * (unit + GAP)
        y = oy + r * (unit + GAP)
        square(d, x, y, tcol, unit, drawface=(r == 0 and c == 0))
save(img, "timestables")

# ── build a million: a tall tower beside a house ─────────────────────────────
img, d = canvas()
grad_bg(img, (79, 142, 247))
d = ImageDraw.Draw(img)
million = (79, 142, 247)
unit = 80
count = 5
gh = count * unit + (count - 1) * GAP
oy = 470 - gh
cx = 290
shadow(d, cx, 470, unit + 20)
for i in range(count):
    y = oy + (count - 1 - i) * (unit + GAP)
    square(d, cx - unit / 2, y, million, unit, drawface=(i == count - 1))
save(img, "million")

# ── take away: 5 - 2, cat watching ───────────────────────────────────────────
img, d = canvas()
grad_bg(img, (255, 107, 107))
d = ImageDraw.Draw(img)
yb = 470
shadow(d, 175, yb, 90)
_, ht1 = block(d, 175, yb, 5, unit=76)
shadow(d, 430, yb, 110)
_, ht2 = block(d, 430, yb, 2, unit=84)
minus(d, 305, yb - (ht1 + ht2) / 4)
save(img, "takeaway")

# ── clock: 1 2 : 3 0 under the sun, village behind ───────────────────────────
img, d = canvas()
grad_bg(img, (92, 107, 192))
d = ImageDraw.Draw(img)
u = 68
yb = 430
for cx, n in ((125, 1), (210, 2)):
    shadow(d, cx, yb, u + 8)
    block(d, cx, yb, n, unit=u)
for dy in (-30, 30):
    d.ellipse([300 - 12, yb - 95 + dy - 12, 300 + 12, yb - 95 + dy + 12], fill=INK_SOFT)
for cx, n in ((375, 3), (495, 4)):
    shadow(d, cx, yb, u + 8)
    block(d, cx, yb, n, unit=u)
save(img, "clock")

print("done")
