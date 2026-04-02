#!/usr/bin/env python3
"""Twelve app icon: pale sky, hand-drawn stick figure — wobbly tilted head, face, angled arms."""

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


def stroke_wobbly_arc(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    r: float,
    a0: float,
    a1: float,
    *,
    fill: tuple[int, int, int, int],
    width: int,
    scale: float,
    steps: int = 14,
    phase: float = 0.0,
) -> None:
    pts: list[tuple[float, float]] = []
    for i in range(steps + 1):
        t = i / steps
        ang = a0 + (a1 - a0) * t
        w = math.sin(t * math.pi * 4 + phase) * 2.8 * scale
        rr = r + w * 0.08
        pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr))
    draw.line(pts, fill=fill, width=width, joint="curve")


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_sky_gradient(
        img,
        top=(240, 249, 255),
        bottom=(218, 236, 252),
    )
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    scale = s

    faint_breeze_arcs(draw, size, scale, (255, 255, 255, 70), max(2, int(3 * s)))

    pad = int(52 * s)
    r_card = int(198 * s)
    card_fill = (255, 255, 255, 255)
    card_outline = (120, 178, 230, 255)
    stroke_wobbly_round_rect(
        draw,
        float(pad),
        float(pad),
        float(size - pad),
        float(size - pad),
        float(r_card),
        fill=card_fill,
        outline=card_outline,
        width=max(3, int(10 * s)),
        scale=scale,
        phase=0.2,
    )

    cx = size / 2
    inset = pad + int(20 * s)
    inner_h = (size - inset) - inset
    ink = (72, 118, 175, 255)
    line_w = max(4, int(14 * s))
    head_w = max(3, int(11 * s))
    dot_w = max(2, int(6 * s))

    head_r = 0.185 * inner_h
    head_cy = inset + head_r + 0.035 * inner_h
    # More organic head: stronger wobble + slight tilt (not a perfect circle)
    stroke_wobbly_ellipse(
        draw,
        cx + 4 * s,
        head_cy - 2 * s,
        head_r * 0.98,
        head_r * 1.08,
        fill=card_fill,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=52,
        phase=0.85,
        wobble_mult=1.62,
        tilt=0.11,
    )

    # Eyes — small wobbly dots
    eye_dx = head_r * 0.34
    eye_y = head_cy - head_r * 0.12
    for ex in (cx - eye_dx + 2 * s, cx + eye_dx + 6 * s):
        stroke_wobbly_ellipse(
            draw,
            ex,
            eye_y,
            max(3.5, 4.8 * s),
            max(4.0, 5.2 * s),
            fill=ink,
            outline=ink,
            width=dot_w,
            scale=scale,
            segments=16,
            phase=ex * 0.01,
            wobble_mult=1.25,
            tilt=0.05,
        )

    # Friendly smile arc
    mouth_cy = head_cy + head_r * 0.22
    stroke_wobbly_arc(
        draw,
        cx + 5 * s,
        mouth_cy - head_r * 0.35,
        head_r * 0.52,
        math.pi * 0.15,
        math.pi * 0.85,
        fill=ink,
        width=max(3, int(8 * s)),
        scale=scale,
        steps=16,
        phase=0.3,
    )

    neck_top_y = head_cy + head_r * 0.88
    shoulder_y = neck_top_y + 0.045 * inner_h
    stroke_wobbly_line(
        draw,
        cx + 2 * s,
        neck_top_y,
        cx + 5 * s,
        shoulder_y,
        fill=ink,
        width=max(3, int(11 * s)),
        scale=scale,
        steps=14,
        phase=0.9,
    )

    torso_bot = size - inset - 0.055 * inner_h
    stroke_wobbly_line(
        draw,
        cx + 5 * s,
        shoulder_y,
        cx + 10 * s,
        torso_bot,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=32,
        phase=1.15,
    )

    sx = cx + 5 * s
    sy = shoulder_y + 0.06 * inner_h
    arm_len = 0.31 * (size - 2 * inset)
    # Left arm: down and out (not horizontal)
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        sx - arm_len * 0.92,
        sy + arm_len * 0.48,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=28,
        phase=2.2,
    )
    # Right arm: up and out
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        sx + arm_len * 0.88,
        sy - arm_len * 0.35,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=28,
        phase=2.8,
    )

    return img


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "Twelve" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    base = draw_icon(1024)
    sizes = {
        "AppIcon-1024.png": 1024,
        "AppIcon-180.png": 180,
        "AppIcon-120.png": 120,
        "AppIcon-87.png": 87,
        "AppIcon-80.png": 80,
        "AppIcon-60.png": 60,
        "AppIcon-58.png": 58,
        "AppIcon-40.png": 40,
    }
    for name, dim in sizes.items():
        base.resize((dim, dim), Image.Resampling.LANCZOS).save(out_dir / name, "PNG")

    print("Wrote Twelve icons to", out_dir)


if __name__ == "__main__":
    main()
