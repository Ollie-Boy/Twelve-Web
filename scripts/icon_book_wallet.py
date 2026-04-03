"""Hand-drawn sketch icons: diary (open book) and ledger (wallet)."""

from __future__ import annotations

import math
from typing import List, Tuple

from PIL import Image, ImageDraw

from icon_hand_drawn import fill_sky_gradient, stroke_wobbly_line, stroke_wobbly_round_rect

Point = Tuple[float, float]
Ink = Tuple[int, int, int, int]

# Near-black linework (reads solid on gradient)
INK: Ink = (18, 20, 26, 255)


def _s(size: int) -> float:
    return size / 1024.0


def _lw(size: int, base: float) -> int:
    return max(3, int(base * _s(size)))


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
        stroke_wobbly_line(draw, x0, y0, x1, y1, fill=ink, width=width, scale=scale, phase=phase + i * 0.7, steps=22)


def _lerp_quad(corners: List[Point], tx: float, ty: float) -> Point:
    """Bilinear interp: tx,ty in [0,1]. corners order TL,TR,BR,BL."""
    tl, tr, br, bl = corners
    top = (tl[0] + (tr[0] - tl[0]) * tx, tl[1] + (tr[1] - tl[1]) * tx)
    bot = (bl[0] + (br[0] - bl[0]) * tx, bl[1] + (br[1] - bl[1]) * tx)
    return (top[0] + (bot[0] - top[0]) * ty, top[1] + (bot[1] - top[1]) * ty)


def fill_blue_white_gradient(img: Image.Image) -> None:
    fill_sky_gradient(
        img,
        top=(210, 236, 255),
        bottom=(255, 255, 255),
    )


def draw_sketch_book(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    Slightly open sketchbook: cover + page block + spine + ruled lines + bookmark + binding ticks.
    """
    scale = _s(size) * 0.9
    outline = _lw(size, 11)
    thin = _lw(size, 6)
    hair = max(2, int(4 * scale))

    cx, cy = size * 0.5, size * 0.5
    hw, hh = size * 0.2, size * 0.26
    tilt = -0.11

    cover = _quad_corners(cx + 8 * scale, cy + 12 * scale, hw, hh, tilt)
    _stroke_quad(draw, cover, ink=INK, width=outline, scale=scale, phase=0.2)

    inset = 0.08
    inner_tl = _lerp_quad(cover, inset, inset)
    inner_tr = _lerp_quad(cover, 1 - inset, inset)
    inner_br = _lerp_quad(cover, 1 - inset, 1 - inset)
    inner_bl = _lerp_quad(cover, inset, 1 - inset)
    inner = [inner_tl, inner_tr, inner_br, inner_bl]
    _stroke_quad(draw, inner, ink=INK, width=thin, scale=scale, phase=0.9)

    # Spine / thickness along left edge of cover
    spine_off = 22 * scale
    tl, tr, br, bl = cover
    spine_shift = (-spine_off * math.cos(tilt), -spine_off * math.sin(tilt))
    spine_cover = [
        (tl[0] + spine_shift[0], tl[1] + spine_shift[1]),
        (tr[0] + spine_shift[0], tr[1] + spine_shift[1]),
        (br[0] + spine_shift[0], br[1] + spine_shift[1]),
        (bl[0] + spine_shift[0], bl[1] + spine_shift[1]),
    ]
    stroke_wobbly_line(draw, spine_cover[0][0], spine_cover[0][1], spine_cover[3][0], spine_cover[3][1], fill=INK, width=thin, scale=scale, phase=1.4, steps=20)
    stroke_wobbly_line(draw, spine_cover[0][0], spine_cover[0][1], tl[0], tl[1], fill=INK, width=thin, scale=scale, phase=1.55, steps=14)
    stroke_wobbly_line(draw, spine_cover[3][0], spine_cover[3][1], bl[0], bl[1], fill=INK, width=thin, scale=scale, phase=1.65, steps=14)

    # Page fan (right side): stacked arcs
    prx = size * 0.58
    pry = cy
    for i, frac in enumerate([0.22, 0.38, 0.52, 0.64]):
        rx = size * (0.12 + frac * 0.06)
        ry = hh * 0.92
        steps = 24
        pts: List[Point] = []
        for j in range(steps + 1):
            t = j / steps
            ang = -math.pi * 0.08 + math.pi * 0.42 * t
            wob = math.sin(t * math.pi * 5 + i + 0.3) * 3.5 * scale
            rr = rx + wob * 0.15
            pts.append((prx + math.cos(ang) * rr, pry + math.sin(ang) * ry * 0.95))
        draw.line(pts, fill=INK, width=hair, joint="curve")

    # Crease between pages (inside spread)
    mid_top = _lerp_quad(inner, 0.5, inset * 0.5)
    mid_bot = _lerp_quad(inner, 0.5, 1 - inset * 0.5)
    stroke_wobbly_line(draw, mid_top[0], mid_top[1], mid_bot[0], mid_bot[1], fill=INK, width=hair, scale=scale, phase=2.2, steps=18)

    # Ruled lines on both halves (skip crease)
    for row in range(7):
        ty = 0.22 + row * 0.095
        if ty > 0.88:
            break
        lx0 = _lerp_quad(inner, 0.08, ty)
        lx1 = _lerp_quad(inner, 0.46, ty)
        stroke_wobbly_line(draw, lx0[0], lx0[1], lx1[0], lx1[1], fill=INK, width=max(2, hair - 1), scale=scale, phase=2.5 + row * 0.11, steps=12)
        rx0 = _lerp_quad(inner, 0.54, ty)
        rx1 = _lerp_quad(inner, 0.92, ty)
        stroke_wobbly_line(draw, rx0[0], rx0[1], rx1[0], rx1[1], fill=INK, width=max(2, hair - 1), scale=scale, phase=2.8 + row * 0.11, steps=12)

    # Bookmark ribbon (top center)
    btop = _lerp_quad(cover, 0.52, 0.0)
    stroke_wobbly_line(draw, btop[0], btop[1] - 4 * scale, btop[0] - 6 * scale, btop[1] - size * 0.09, fill=INK, width=thin, scale=scale, phase=3.1, steps=14)
    stroke_wobbly_line(draw, btop[0], btop[1] - 4 * scale, btop[0] + 6 * scale, btop[1] - size * 0.09, fill=INK, width=thin, scale=scale, phase=3.25, steps=14)

    # Binding stitches along spine edge
    n_st = 5
    for k in range(n_st):
        t = (k + 0.5) / n_st
        p0 = _lerp_quad([spine_cover[0], spine_cover[1], spine_cover[2], spine_cover[3]], 0.0, t)
        p1 = _lerp_quad([tl, tr, br, bl], 0.0, t)
        stroke_wobbly_line(draw, p0[0], p0[1], p1[0], p1[1], fill=INK, width=max(2, hair), scale=scale, phase=3.5 + k * 0.2, steps=8)

    # Corner fold hint (dog-ear) upper right of cover
    stroke_wobbly_line(draw, inner_tr[0], inner_tr[1], inner_tr[0] - 28 * scale, inner_tr[1] + 36 * scale, fill=INK, width=hair, scale=scale, phase=4.0, steps=10)
    stroke_wobbly_line(draw, inner_tr[0], inner_tr[1], inner_tr[0] - 52 * scale, inner_tr[1] + 8 * scale, fill=INK, width=hair, scale=scale, phase=4.1, steps=10)


def draw_sketch_wallet(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Bifold wallet: outer shell, fold line, card slots, flap curve, corner details."""
    scale = _s(size) * 0.9
    bold = _lw(size, 12)
    mid = _lw(size, 8)
    fine = max(2, int(4 * scale))

    # Outer rounded rectangle (horizontal bifold)
    pad_x = int(118 * scale)
    pad_y = int(268 * scale)
    r = int(52 * scale)
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
        phase=0.35,
    )

    cx = size / 2
    y0 = float(pad_y + r)
    y1 = float(size - pad_y - r)

    # Center fold
    stroke_wobbly_line(draw, cx, y0 + 8 * scale, cx, y1 - 6 * scale, fill=INK, width=mid, scale=scale, phase=1.0, steps=26)

    # Inner top curve (coin pocket feel)
    dip_cy = pad_y + int(118 * scale)
    stroke_wobbly_line(
        draw,
        pad_x + int(70 * scale),
        dip_cy,
        size - pad_x - int(70 * scale),
        dip_cy,
        fill=INK,
        width=fine,
        scale=scale,
        phase=1.4,
        steps=20,
    )

    # Card slots — left stack
    lx = pad_x + int(52 * scale)
    for i, yy in enumerate([0.42, 0.52, 0.62]):
        y = pad_y + int((size - 2 * pad_y) * yy)
        stroke_wobbly_line(draw, lx, y, cx - int(36 * scale), y + 4 * scale, fill=INK, width=fine, scale=scale, phase=2.0 + i * 0.3, steps=14)

    # Card slots — right stack
    rx = size - pad_x - int(52 * scale)
    for i, yy in enumerate([0.42, 0.52]):
        y = pad_y + int((size - 2 * pad_y) * yy)
        stroke_wobbly_line(draw, cx + int(36 * scale), y + 2 * scale, rx, y, fill=INK, width=fine, scale=scale, phase=2.6 + i * 0.25, steps=14)

    # Bottom stitch / clasp ticks
    stitch_y = size - pad_y - int(38 * scale)
    for k in range(4):
        sx = pad_x + int(80 * scale) + k * int(118 * scale)
        stroke_wobbly_line(draw, sx, stitch_y, sx + int(22 * scale), stitch_y - int(10 * scale), fill=INK, width=fine, scale=scale, phase=3.1 + k * 0.15, steps=8)

    # Subtle outer corner brackets (sketch emphasis)
    c = int(18 * scale)
    stroke_wobbly_line(draw, float(pad_x + r), float(pad_y + r), float(pad_x + r + c), float(pad_y + r), fill=INK, width=fine, scale=scale, phase=3.8, steps=8)
    stroke_wobbly_line(draw, float(pad_x + r), float(pad_y + r), float(pad_x + r), float(pad_y + r + c), fill=INK, width=fine, scale=scale, phase=3.85, steps=8)


def compose_twelve_book_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    fill_blue_white_gradient(img)
    draw = ImageDraw.Draw(img)
    draw_sketch_book(draw, size)
    return img


def compose_ledger_wallet_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    fill_blue_white_gradient(img)
    draw = ImageDraw.Draw(img)
    draw_sketch_wallet(draw, size)
    return img
