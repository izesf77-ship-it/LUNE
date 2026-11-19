"""Prepare the LUNE iOS AppIcon from the approved logo.png.

The artwork in logo.png is a ready-made rounded "icon inside an icon" with
transparent margins and a drop shadow. iOS applies its own icon shape, so this
script extracts ONLY the flower symbol and rebuilds a full-bleed square
background using the original colour palette. The symbol is never redrawn.

Output: 1024x1024 RGB PNG, no alpha, no rounded corners, no white frame.
"""
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
OUT = ROOT / "Resources" / "Assets" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
LOGO = ROOT / "logo.png"

FLOWER_WIDTH_RATIO = 0.76  # 70–80 % ширины холста
MASK_THRESHOLD = 20.0       # порог отделения символа от фона (дальше — заливка дыр)


def _background_coefficients(tile):
    """Fit a smooth background gradient from the border ring of the original tile."""
    h, w = tile.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    ring = ((xx < 0.08 * w) | (xx > 0.92 * w)
            | (yy < 0.08 * h) | (yy > 0.92 * h))
    ring &= tile[..., 3] >= 250

    x = xx[ring] / w
    y = yy[ring] / h
    design = np.stack(
        [np.ones_like(x), x, y, x * x, x * y, y * y], axis=1
    )

    coefficients = []
    for channel in range(3):
        coefficients.append(
            np.linalg.lstsq(design, tile[..., channel][ring], rcond=None)[0]
        )
    return np.array(coefficients)


def _evaluate_background(coefficients, u, v):
    design = np.stack([np.ones_like(u), u, v, u * u, u * v, v * v], axis=-1)
    return np.einsum("ij,xyj->xyi", coefficients, design)


def main():
    if not LOGO.exists():
        raise SystemExit(f"Missing approved logo: {LOGO}")

    with Image.open(LOGO) as source:
        logo = np.array(source.convert("RGBA"))

    # 1. Original tile bounds (drop transparent margins and most of the shadow).
    opaque = logo[..., 3] >= 250
    ys, xs = np.where(opaque)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max(), ys.max()
    tile = logo[y0:y1 + 1, x0:x1 + 1]
    h, w = tile.shape[:2]

    # 2. Estimate the original pink gradient and subtract it to isolate the flower.
    coefficients = _background_coefficients(tile)
    yy, xx = np.mgrid[0:h, 0:w]
    background = _evaluate_background(coefficients, xx / w, yy / h)
    distance = np.linalg.norm(tile[..., :3].astype(float) - background, axis=-1)

    raw_mask = distance > MASK_THRESHOLD
    # Only original opaque pixels; no transparent corners or drawn tile border.
    raw_mask &= tile[..., 3] >= 250
    # Ignore the rounded tile border entirely — no outline must survive.
    raw_mask &= ((xx > 0.06 * w) & (xx < 0.94 * w)
                 & (yy > 0.06 * h) & (yy < 0.94 * h))

    # 3. Fill enclosed low-contrast areas (light petals, crescent) that belong
    # to the symbol, but keep border-connected background outside.
    # .copy() is required: ImageDraw.floodfill does not traverse images
    # created directly by Image.fromarray in some Pillow versions.
    seed = Image.fromarray((raw_mask * 255).astype("uint8"), "L").copy()
    for point in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
                  (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        if seed.getpixel(point) == 0:
            ImageDraw.floodfill(seed, point, 128, thresh=0)
    filled = Image.fromarray(((np.array(seed) != 128) * 255).astype("uint8"), "L").copy()

    # Keep only the connected component containing the flower's centre.
    # Any remaining background specks are disconnected and disappear.
    centre = (w // 2, h // 2)
    if filled.getpixel(centre) != 0:
        ImageDraw.floodfill(filled, centre, 128, thresh=0)
        component = np.array(filled) == 128
    else:
        component = np.array(filled) != 0

    mask_image = Image.fromarray((component * 255).astype("uint8"), "L")
    mask_image = mask_image.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    mask_image = mask_image.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    mask_image = mask_image.filter(ImageFilter.GaussianBlur(1.4))
    mask = np.array(mask_image).astype(float) / 255.0

    # 4. Crop tightly to the symbol, preserving its original pixels and colours.
    fy, fx = np.where(mask > 0.15)
    if fx.size == 0:
        raise SystemExit("Could not isolate the flower from logo.png")
    fx0, fx1, fy0, fy1 = fx.min(), fx.max(), fy.min(), fy.max()
    symbol_rgb = tile[fy0:fy1 + 1, fx0:fx1 + 1, :3]
    symbol_alpha = mask[fy0:fy1 + 1, fx0:fx1 + 1]

    target_width = int(round(SIZE * FLOWER_WIDTH_RATIO))
    target_height = int(round(symbol_rgb.shape[0] * target_width / symbol_rgb.shape[1]))

    flower = Image.fromarray(symbol_rgb, "RGB").resize(
        (target_width, target_height), Image.LANCZOS
    )
    alpha = Image.fromarray((symbol_alpha * 255).astype("uint8"), "L").resize(
        (target_width, target_height), Image.LANCZOS
    )

    # 5. Full-bleed background in the original pink palette, no alpha.
    u, v = np.meshgrid(np.linspace(0, 1, SIZE), np.linspace(0, 1, SIZE))
    canvas = np.clip(_evaluate_background(coefficients, u, v), 0, 255).astype(float)

    left = (SIZE - target_width) // 2
    top = (SIZE - target_height) // 2
    a = np.array(alpha).astype(float) / 255.0
    region = canvas[top:top + target_height, left:left + target_width]
    blended = np.array(flower).astype(float) * a[..., None] + region * (1 - a[..., None])
    canvas[top:top + target_height, left:left + target_width] = blended

    OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(canvas, 0, 255).astype("uint8"), "RGB").save(
        OUT, format="PNG", optimize=True
    )
    print(f"Written {OUT.relative_to(ROOT)} ({SIZE}x{SIZE} RGB, flower {target_width}px wide)")


if __name__ == "__main__":
    try:
        main()
    except ImportError as exc:
        raise SystemExit(f"Pillow and NumPy are required to rebuild the icon: {exc}") from exc
