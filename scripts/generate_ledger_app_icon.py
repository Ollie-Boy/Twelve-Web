#!/usr/bin/env python3
"""Generate Ledger app icon PNGs (Pillow). Run from repo root."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def draw_ledger_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pix = img.load()
    # Soft vertical gradient (Twelve-style sky)
    c_top = (247, 250, 255)
    c_bot = (230, 242, 255)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(lerp(c_top[0], c_bot[0], t))
        g = int(lerp(c_top[1], c_bot[1], t))
        b = int(lerp(c_top[2], c_bot[2], t))
        for x in range(size):
            pix[x, y] = (r, g, b, 255)

    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    pad = int(90 * s)
    # Outer rounded "sticker"
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=int(180 * s),
        fill=(255, 255, 255, 255),
        outline=(0, 122, 255, 255),
        width=max(4, int(14 * s)),
    )

    # Inner "ledger page" panel
    inner_pad = int(150 * s)
    draw.rounded_rectangle(
        [inner_pad, inner_pad + int(30 * s), size - inner_pad, size - inner_pad - int(40 * s)],
        radius=int(48 * s),
        fill=(248, 251, 255, 255),
        outline=(180, 210, 255, 255),
        width=max(2, int(6 * s)),
    )

    # Horizontal ledger lines
    line_y0 = inner_pad + int(120 * s)
    line_gap = int(56 * s)
    line_left = inner_pad + int(50 * s)
    line_right = size - inner_pad - int(50 * s)
    blue_soft = (200, 224, 255, 255)
    for i in range(5):
        y = line_y0 + i * line_gap
        draw.line([(line_left, y), (line_right, y)], fill=blue_soft, width=max(2, int(5 * s)))

    # Accent bar (income / expense hint)
    bar_w = int(18 * s)
    draw.rounded_rectangle(
        [inner_pad + int(36 * s), line_y0 - int(10 * s), inner_pad + int(36 * s) + bar_w, line_y0 + line_gap * 4 + int(10 * s)],
        radius=int(8 * s),
        fill=(0, 122, 255, 255),
    )

    # Coin circle (center-right)
    cx = int(size * 0.62)
    cy = int(size * 0.52)
    r_coin = int(155 * s)
    draw.ellipse([cx - r_coin, cy - r_coin, cx + r_coin, cy + r_coin], fill=(255, 230, 120, 255), outline=(0, 90, 220, 255), width=max(3, int(10 * s)))
    draw.ellipse(
        [cx - r_coin + int(18 * s), cy - r_coin + int(18 * s), cx + r_coin - int(18 * s), cy + r_coin - int(18 * s)],
        outline=(255, 255, 255, 180),
        width=max(2, int(5 * s)),
    )

    # Simple "¥" or "$" using lines (universal money symbol feel)
    arm = int(52 * s)
    draw.line([(cx - arm, cy - int(30 * s)), (cx + arm, cy + int(30 * s))], fill=(30, 60, 140, 255), width=max(5, int(16 * s)))
    draw.line([(cx + arm, cy - int(30 * s)), (cx - arm, cy + int(30 * s))], fill=(30, 60, 140, 255), width=max(5, int(16 * s)))
    draw.line([(cx - arm, cy + int(8 * s)), (cx + arm, cy + int(8 * s))], fill=(30, 60, 140, 255), width=max(4, int(12 * s)))

    return img


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "Ledger" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    base = draw_ledger_icon(1024)
    sizes = {
        "LedgerAppIcon-1024.png": 1024,
        "LedgerAppIcon-180.png": 180,
        "LedgerAppIcon-120.png": 120,
        "LedgerAppIcon-87.png": 87,
        "LedgerAppIcon-80.png": 80,
        "LedgerAppIcon-60.png": 60,
        "LedgerAppIcon-58.png": 58,
        "LedgerAppIcon-40.png": 40,
    }
    for name, dim in sizes.items():
        resized = base.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(out_dir / name, "PNG")

    print("Wrote", out_dir)


if __name__ == "__main__":
    main()
