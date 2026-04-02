#!/usr/bin/env python3
"""Ledger app icon: pale sky + hand-drawn notepad + clear '+' (add entry / money in)."""

from __future__ import annotations

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
    ink_bold = max(3, int(9 * s))

    # Note area on the left (~62% width) — ruled lines + margin
    xl = inner + int(38 * s)
    xm = inner + int(400 * s)
    y0 = inner + int(128 * s)
    gap = int(50 * s)
    for i in range(5):
        y = y0 + i * gap
        stroke_wobbly_line(
            draw,
            xl,
            y + (i % 3) * 1.5 * s,
            xm,
            y - (i % 2) * 2 * s,
            fill=line_color,
            width=line_w,
            scale=scale,
            steps=20,
            phase=0.4 + i * 0.28,
        )

    bx = inner + int(32 * s)
    stroke_wobbly_line(
        draw,
        bx,
        y0 - int(10 * s),
        bx + 2 * s,
        y0 + gap * 4 + int(14 * s),
        fill=ink,
        width=ink_bold,
        scale=scale,
        steps=26,
        phase=1.0,
    )

    # Large hand-drawn '+' on the right = "add" / ledger (readable at a glance)
    pcx = inner + int(560 * s)
    pcy = size / 2 + int(8 * s)
    half_h = int(118 * s)
    half_w = int(112 * s)
    stroke_wobbly_line(
        draw,
        pcx,
        pcy - half_h,
        pcx + 5 * s,
        pcy + half_h,
        fill=ink,
        width=ink_bold,
        scale=scale,
        steps=30,
        phase=1.7,
    )
    stroke_wobbly_line(
        draw,
        pcx - half_w,
        pcy + 3 * s,
        pcx + half_w,
        pcy - 2 * s,
        fill=ink,
        width=ink_bold,
        scale=scale,
        steps=30,
        phase=2.3,
    )

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
