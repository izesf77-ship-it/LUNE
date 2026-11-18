"""Prepare LUNÉ app icon (1024x1024 PNG).

Prefers the project's original logo.png (resized to 1024). If Pillow is not
available, falls back to a deterministic pure-stdlib five-petal mark.
No network access.
"""
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
OUT = ROOT / "Resources" / "Assets" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
LOGO = ROOT / "logo.png"


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def main():
    if LOGO.exists():
        try:
            from PIL import Image
            with Image.open(LOGO) as image:
                image = image.convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
                OUT.parent.mkdir(parents=True, exist_ok=True)
                image.save(OUT, format="PNG", optimize=True)
            print(f"Resized {LOGO.name} -> {OUT.relative_to(ROOT)}")
            return
        except ImportError:
            pass

    bg = (0xFC, 0xE8, 0xEF)
    bg_edge = (0xF8, 0xDC, 0xE8)
    petal = (0xF4, 0xA6, 0xBE)
    petal_light = (0xF9, 0xC4, 0xD3)
    center = (0xA6, 0x4D, 0x72)

    cx = cy = SIZE / 2
    petal_dist = SIZE * 0.215
    petal_radius = SIZE * 0.176

    petals = []
    for i in range(5):
        angle = -math.pi / 2 + i * (2 * math.pi / 5)
        petals.append((cx + math.cos(angle) * petal_dist,
                       cy + math.sin(angle) * petal_dist))

    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)  # PNG filter: none
        for x in range(SIZE):
            # subtle background gradient
            t = (x + y) / (2 * SIZE)
            r, g, b = mix(bg, bg_edge, t)

            # petals (soft union of five circles)
            best = -1.0
            for px, py in petals:
                d = math.hypot(x - px, y - py) / petal_radius
                if d > best:
                    best = d
            coverage = max(0.0, min(1.0, (1.0 - best) * petal_radius / 3.0))
            if coverage > 0:
                shade = min(1.0, max(0.0, (x + y) / (2 * SIZE)))
                pr, pg, pb = mix(petal_light, petal, shade)
                r, g, b = mix((r, g, b), (pr, pg, pb), coverage)

            # center
            dc = math.hypot(x - cx, y - cy) / (SIZE * 0.115)
            cov_c = max(0.0, min(1.0, (1.0 - dc) * (SIZE * 0.115) / 3.0))
            if cov_c > 0:
                r, g, b = mix((r, g, b), center, cov_c)

            raw.extend((r, g, b))

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(png)
    print(f"Written {OUT} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
