"""Helpers for hand-drawn / wobbly vector strokes on app icons (Pillow)."""

from __future__ import annotations

import math
from typing import List, Tuple

from PIL import Image, ImageDraw

Point = Tuple[float, float]


def fill_sky_gradient(
    img: Image.Image,
    top: Tuple[int, int, int] = (238, 248, 255),
    bottom: Tuple[int, int, int] = (214, 234, 252),
) -> None:
    w, h = img.size
    pix = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        for x in range(w):
            pix[x, y] = (r, g, b, 255)


def _perp(dx: float, dy: float) -> Tuple[float, float]:
    L = math.hypot(dx, dy) or 1.0
    return -dy / L, dx / L


def wobble_along_line(x0: float, y0: float, x1: float, y1: float, t: float, scale: float, phase: float) -> Point:
    dx, yd = x1 - x0, y1 - y0
    px, py = _perp(dx, yd)
    w = (
        math.sin(t * math.pi * 5 + phase) * 4.2 * scale
        + math.sin(t * math.pi * 13 + phase * 1.7) * 1.6 * scale
    )
    return x0 + dx * t + px * w, y0 + yd * t + py * w


def stroke_wobbly_line(
    draw: ImageDraw.ImageDraw,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    *,
    fill: Tuple[int, int, int, int],
    width: int,
    scale: float,
    steps: int = 28,
    phase: float = 0.0,
) -> None:
    pts: List[Point] = []
    for i in range(steps + 1):
        t = i / steps
        pts.append(wobble_along_line(x0, y0, x1, y1, t, scale, phase))
    draw.line(pts, fill=fill, width=width, joint="curve")


def stroke_wobbly_ellipse(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    *,
    fill: Tuple[int, int, int, int] | None,
    outline: Tuple[int, int, int, int],
    width: int,
    scale: float,
    segments: int = 56,
    phase: float = 0.0,
    wobble_mult: float = 1.0,
    tilt: float = 0.0,
) -> None:
    poly: List[Point] = []
    for i in range(segments + 1):
        ang = 2 * math.pi * i / segments
        w = (
            math.sin(ang * 3 + phase) * 3.8 * scale
            + math.sin(ang * 7 + phase * 2.1) * 1.4 * scale
            + math.sin(ang * 11 + phase * 0.9) * 2.8 * scale * max(0, wobble_mult - 1.0) * 0.35
        ) * wobble_mult
        rr = 1.0 + w * 0.014 / max(rx, ry, 1)
        ex = math.cos(ang) * rx * rr
        ey = math.sin(ang) * ry * rr
        ca, sa = math.cos(tilt), math.sin(tilt)
        poly.append((cx + ex * ca - ey * sa, cy + ex * sa + ey * ca))
    if fill is not None:
        draw.polygon(poly, fill=fill, outline=outline, width=width)
    else:
        draw.line(poly + [poly[0]], fill=outline, width=width, joint="curve")


def stroke_wobbly_round_rect(
    draw: ImageDraw.ImageDraw,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    radius: float,
    *,
    fill: Tuple[int, int, int, int] | None,
    outline: Tuple[int, int, int, int],
    width: int,
    scale: float,
    phase: float = 0.3,
) -> None:
    w, h = x1 - x0, y1 - y0
    r = min(radius, w / 2, h / 2)
    pts: List[Point] = []
    segs_arc = 12
    segs_side = 11

    def edge_top() -> None:
        for i in range(segs_side + 1):
            t = i / segs_side
            px = x0 + r + (w - 2 * r) * t
            py = y0 + math.sin(t * math.pi * 6 + phase) * 2.8 * scale
            pts.append((px, py))

    def arc(cx: float, cy: float, a0: float, a1: float) -> None:
        for i in range(1, segs_arc + 1):
            t = i / segs_arc
            ang = a0 + (a1 - a0) * t
            wb = math.sin(ang * 5 + phase) * 2.4 * scale
            rr = r + wb
            pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr))

    def edge_right() -> None:
        for i in range(1, segs_side + 1):
            t = i / segs_side
            px = x1 + math.sin(t * math.pi * 5 + phase * 1.1) * 2.6 * scale
            py = y0 + r + (h - 2 * r) * t
            pts.append((px, py))

    def edge_bottom() -> None:
        for i in range(1, segs_side + 1):
            t = i / segs_side
            px = x1 - r - (w - 2 * r) * t
            py = y1 - math.sin(t * math.pi * 6 + phase * 0.8) * 2.8 * scale
            pts.append((px, py))

    def edge_left() -> None:
        for i in range(1, segs_side + 1):
            t = i / segs_side
            px = x0 - math.sin(t * math.pi * 5 + phase * 1.3) * 2.6 * scale
            py = y1 - r - (h - 2 * r) * t
            pts.append((px, py))

    edge_top()
    arc(x1 - r, y0 + r, -math.pi / 2, 0)
    edge_right()
    arc(x1 - r, y1 - r, 0, math.pi / 2)
    edge_bottom()
    arc(x0 + r, y1 - r, math.pi / 2, math.pi)
    edge_left()
    arc(x0 + r, y0 + r, math.pi, 1.5 * math.pi)

    if fill is not None:
        draw.polygon(pts, fill=fill, outline=outline, width=width)
    else:
        draw.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def faint_breeze_arcs(
    draw: ImageDraw.ImageDraw,
    size: int,
    scale: float,
    color: Tuple[int, int, int, int],
    width: int,
) -> None:
    """Very soft sweeping curves — suggest air without drawing clouds."""
    s = size / 1024.0
    # Three loose arcs across upper/side areas
    for k, (cx, cy, r0, r1, start, span) in enumerate(
        [
            (0.22, 0.28, 0.18, 0.26, 0.1, 0.85),
            (0.78, 0.35, 0.15, 0.22, 0.55, 0.9),
            (0.5, 0.82, 0.2, 0.28, 0.15, 0.7),
        ]
    ):
        pts: List[Point] = []
        steps = 36
        for i in range(steps + 1):
            t = i / steps
            ang = start * math.pi + span * math.pi * t
            rr = (r0 + (r1 - r0) * t) * size
            w = math.sin(t * math.pi * 4 + k) * 5 * s * scale
            pts.append(
                (
                    cx * size + math.cos(ang) * rr + w,
                    cy * size + math.sin(ang) * rr * 0.55 + w * 0.4,
                )
            )
        draw.line(pts, fill=color, width=width, joint="curve")
