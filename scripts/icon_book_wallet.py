"""Minimal hand-drawn book & wallet icons: white background, ~7–8 soft strokes each."""

from __future__ import annotations

import math
from typing import List, Tuple

from PIL import Image, ImageDraw

from icon_hand_drawn import stroke_wobbly_line, stroke_wobbly_round_rect

Point = Tuple[float, float]
Ink = Tuple[int, int, int, int]

# Soft gray pencil (weaker than black on white)
INK: Ink = (118, 124, 134, 255)

WHITE = (255, 255, 255, 255)


def _s(size: int) -> float:
    return size / 1024.0


def _lw(size: int, base: float) -> int:
    return max(2, int(base * _s(size)))


def _rot(cx: float, cy: float, x: float, y: float, theta: float) -> Point:
    dx, dy = x - cx, y - cy
    c, sn = math.cos(theta), math.sin(theta)
    return cx + dx * c - dy * sn, cy + dx * sn + dy * c


def _quad_corners(cx: float, cy: float, hw: float, hh: float, theta: float) -> List[Point]:
    pts = [
        (cx - hw, cy - hh),
        (cx + hw, cy - hh),
        (cx + hw, cy + hh),
        (cx - hw, cy + hh),
    ]
    return [_rot(cx, cy, x, y, theta) for x, y in pts]


def _stroke_quad(
    draw: ImageDraw.ImageDraw,
    corners: List[Point],
    *,
    ink: Ink,
    width: int,
    scale: float,
    phase: float,
) -> None:
    for i in range(4):
        x0, y0 = corners[i]
        x1, y1 = corners[(i + 1) % 4]
        stroke_wobbly_line(draw, x0, y0, x1, y1, fill=ink, width=width, scale=scale, phase=phase + i * 0.7, steps=18)


def _lerp_quad(corners: List[Point], tx: float, ty: float) -> Point:
    tl, tr, br, bl = corners
    top = (tl[0] + (tr[0] - tl[0]) * tx, tl[1] + (tr[1] - tl[1]) * tx)
    bot = (bl[0] + (br[0] - bl[0]) * tx, bl[1] + (br[1] - bl[1]) * tx)
    return (top[0] + (bot[0] - top[0]) * ty, top[1] + (bot[1] - top[1]) * ty)


def draw_sketch_book(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    7 笔: 封面四边 + 书脊一条 + 右缘书页弧 + 中缝。
    """
    scale = _s(size) * 0.72
    outline = _lw(size, 9)
    thin = _lw(size, 5)

    cx, cy = size * 0.5, size * 0.5
    hw, hh = size * 0.21, size * 0.27
    tilt = -0.1

    cover = _quad_corners(cx + 6 * scale, cy + 10 * scale, hw, hh, tilt)
    _stroke_quad(draw, cover, ink=INK, width=outline, scale=scale, phase=0.15)

    tl, _, _, bl = cover
    spine_off = 18 * scale
    st = (-spine_off * math.cos(tilt), -spine_off * math.sin(tilt))
    s_tl = (tl[0] + st[0], tl[1] + st[1])
    s_bl = (bl[0] + st[0], bl[1] + st[1])
    stroke_wobbly_line(draw, s_tl[0], s_tl[1], s_bl[0], s_bl[1], fill=INK, width=thin, scale=scale, phase=1.0, steps=16)

    tr, br = cover[1], cover[2]
    prx = tr[0] + 14 * scale
    pry = (tr[1] + br[1]) / 2
    ry = hh * 0.88
    rx = size * 0.11
    pts: List[Point] = []
    for j in range(17):
        t = j / 16
        ang = -math.pi * 0.06 + math.pi * 0.38 * t
        wob = math.sin(t * math.pi * 4) * 2.2 * scale
        pts.append((prx + math.cos(ang) * (rx + wob * 0.08), pry + math.sin(ang) * ry * 0.92))
    draw.line(pts, fill=INK, width=max(2, thin - 1), joint="curve")

    crease_top = _lerp_quad(cover, 0.5, 0.14)
    crease_bot = _lerp_quad(cover, 0.5, 0.86)
    stroke_wobbly_line(
        draw, crease_top[0], crease_top[1], crease_bot[0], crease_bot[1], fill=INK, width=max(2, thin - 1), scale=scale, phase=1.85, steps=14
    )


def draw_sketch_wallet(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    7 笔: 外轮廓 + 中线 + 顶内弧 + 左右卡槽 + 底左 + 底右短划。
    """
    scale = _s(size) * 0.72
    bold = _lw(size, 9)
    mid = _lw(size, 5)
    fine = max(2, int(3.2 * scale))

    pad_x = int(124 * scale)
    pad_y = int(278 * scale)
    r = int(48 * scale)
    stroke_wobbly_round_rect(
        draw,
        float(pad_x),
        float(pad_y),
        float(size - pad_x),
        float(size - pad_y),
        float(r),
        fill=None,
        outline=INK,
        width=bold,
        scale=scale,
        phase=0.28,
    )

    cx = size / 2
    y0 = float(pad_y + r)
    y1 = float(size - pad_y - r)
    stroke_wobbly_line(draw, cx, y0 + 6 * scale, cx, y1 - 4 * scale, fill=INK, width=mid, scale=scale, phase=0.9, steps=22)

    dip_y = pad_y + int(108 * scale)
    stroke_wobbly_line(
        draw,
        pad_x + int(88 * scale),
        dip_y,
        size - pad_x - int(88 * scale),
        dip_y,
        fill=INK,
        width=fine,
        scale=scale,
        phase=1.25,
        steps=16,
    )

    h_inner = pad_y + int((size - 2 * pad_y) * 0.48)
    stroke_wobbly_line(
        draw,
        pad_x + int(48 * scale),
        h_inner,
        cx - int(40 * scale),
        h_inner + 3 * scale,
        fill=INK,
        width=fine,
        scale=scale,
        phase=1.6,
        steps=12,
    )
    stroke_wobbly_line(
        draw,
        cx + int(40 * scale),
        h_inner + 2 * scale,
        size - pad_x - int(48 * scale),
        h_inner,
        fill=INK,
        width=fine,
        scale=scale,
        phase=1.85,
        steps=12,
    )

    stitch_y = size - pad_y - int(32 * scale)
    stroke_wobbly_line(
        draw,
        pad_x + int(100 * scale),
        stitch_y,
        pad_x + int(132 * scale),
        stitch_y - int(8 * scale),
        fill=INK,
        width=fine,
        scale=scale,
        phase=2.15,
        steps=8,
    )
    stroke_wobbly_line(
        draw,
        size - pad_x - int(132 * scale),
        stitch_y,
        size - pad_x - int(100 * scale),
        stitch_y - int(8 * scale),
        fill=INK,
        width=fine,
        scale=scale,
        phase=2.35,
        steps=8,
    )


def compose_twelve_book_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), WHITE)
    draw = ImageDraw.Draw(img)
    draw_sketch_book(draw, size)
    return img


def compose_ledger_wallet_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), WHITE)
    draw = ImageDraw.Draw(img)
    draw_sketch_wallet(draw, size)
    return img
