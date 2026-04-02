#!/usr/bin/env python3
"""Ledger app icon: pale sky + hand-drawn simple notebook + soft wobbly coin ring."""

from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from icon_hand_drawn import (  # noqa: E402
    faint_breeze_arcs,
    fill_sky_gradient,
    stroke_wobbly_line,
    stroke_wobbly_ellipse,
    stroke_wobbly_round_rect,
)


def draw_ledger_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_sky_gradient(
        img,
        top=(240, 249, 255),
        bottom=(218, 236, 252),
    )
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    scale = s

    faint_breeze_arcs(draw, size, scale, (255, 255, 255, 72), max(2, int(3 * s)))

    pad = int(58 * s)
    r_card = int(192 * s)
    stroke_wobbly_round_rect(
        draw,
        float(pad),
        float(pad),
        float(size - pad),
        float(size - pad),
        float(r_card),
        fill=(255, 255, 255, 255),
        outline=(120, 178, 230, 255),
        width=max(3, int(10 * s)),
        scale=scale,
        phase=0.55,
    )

    inner = pad + int(36 * s)
    inner_r = size - inner
    line_color = (170, 205, 238, 255)
    line_w = max(2, int(5 * s))
    ink = (72, 118, 175, 255)
    ink_bold = max(3, int(8 * s))

    y0 = inner + int(120 * s)
    gap = int(52 * s)
    xl, xr = inner + int(40 * s), inner_r - int(40 * s)
    for i in range(5):
        y = y0 + i * gap
        stroke_wobbly_line(
            draw,
            xl,
            y + (i % 3) * 1.5 * s,
            xr,
            y - (i % 2) * 2 * s,
            fill=line_color,
            width=line_w,
            scale=scale,
            steps=22,
            phase=0.4 + i * 0.3,
        )

    bx = inner + int(34 * s)
    by0 = y0 - int(8 * s)
    by1 = y0 + gap * 4 + int(8 * s)
    stroke_wobbly_line(draw, bx, by0, bx, by1, fill=ink, width=ink_bold, scale=scale, steps=26, phase=1.0)

    cx = size * 0.67
    cy = size * 0.52
    coin_r = int(108 * s)
    stroke_wobbly_ellipse(
        draw,
        cx,
        cy,
        float(coin_r),
        float(coin_r * 1.03),
        fill=None,
        outline=ink,
        width=ink_bold,
        scale=scale,
        segments=40,
        phase=1.8,
    )
    # Loose "S" curve — hand-drawn tally feel
    pts: list[tuple[float, float]] = []
    for i in range(17):
        t = i / 16
        ang = 0.7 + t * 1.5
        rr = coin_r * (0.35 + 0.22 * math.sin(t * math.pi))
        pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr * 0.95 + (t - 0.5) * 8 * s))
    draw.line(pts, fill=ink, width=max(3, int(7 * s)), joint="curve")

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
        base.resize((dim, dim), Image.Resampling.LANCZOS).save(out_dir / name, "PNG")

    print("Wrote Ledger icons to", out_dir)


if __name__ == "__main__":
    main()
