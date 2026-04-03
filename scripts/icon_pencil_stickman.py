"""Pencil-style stick figures on sky-blue icons (~6 strokes, half / two-thirds body)."""

from __future__ import annotations

from typing import Tuple

from PIL import Image, ImageDraw

from icon_hand_drawn import faint_breeze_arcs, fill_sky_gradient, stroke_wobbly_ellipse, stroke_wobbly_line

Ink = Tuple[int, int, int, int]


def fill_sky_blue_icon(img, *, vivid: bool = True) -> None:
    """天蓝色 gradient (full icon background)."""
    if vivid:
        fill_sky_gradient(img, top=(165, 220, 252), bottom=(118, 188, 242))
    else:
        fill_sky_gradient(img, top=(175, 225, 255), bottom=(128, 198, 248))


def _lw(size: int, base: float) -> int:
    s = size / 1024.0
    return max(3, int(base * s))


def draw_diary_stickman(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    ~6 笔: 空心头、躯干、左臂(书写)、右臂(扬起)、双腿。
    """
    s = size / 1024.0
    scale = s
    ink: Ink = (58, 72, 92, 255)
    line_w = _lw(size, 13)
    head_w = _lw(size, 11)

    cx = size * 0.5
    head_r = 0.088 * size
    head_cy = size * 0.30

    stroke_wobbly_ellipse(
        draw,
        cx + 4 * s,
        head_cy,
        head_r * 0.96,
        head_r * 1.06,
        fill=None,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=48,
        phase=0.7,
        wobble_mult=1.45,
        tilt=0.09,
    )

    neck_y = head_cy + head_r * 0.82
    shoulder = (cx + 3 * s, neck_y + 0.018 * size)
    hip = (cx + 8 * s, size * 0.56)
    stroke_wobbly_line(
        draw,
        shoulder[0],
        shoulder[1],
        hip[0],
        hip[1],
        fill=ink,
        width=line_w,
        scale=scale,
        steps=26,
        phase=1.05,
    )

    sx, sy = shoulder
    # 左臂：向前下方，像在写字
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        cx + 0.20 * size,
        sy + 0.20 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=24,
        phase=2.0,
    )
    # 右臂：抬起挥手
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        cx - 0.17 * size,
        sy - 0.11 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=24,
        phase=2.65,
    )

    foot_y = size * 0.72
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx - 0.07 * size,
        foot_y,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.1,
    )
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx + 0.11 * size,
        foot_y + 6 * s,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.55,
    )


def draw_ledger_stickman(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    ~6 笔: 空心头、躯干、左臂平举(账本感)、右臂下垂、双腿(一腿略抬)。
    """
    s = size / 1024.0
    scale = s
    ink: Ink = (52, 68, 88, 255)
    line_w = _lw(size, 13)
    head_w = _lw(size, 11)

    cx = size * 0.52
    head_r = 0.086 * size
    head_cy = size * 0.31

    stroke_wobbly_ellipse(
        draw,
        cx - 2 * s,
        head_cy,
        head_r * 1.02,
        head_r * 0.98,
        fill=None,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=48,
        phase=0.35,
        wobble_mult=1.4,
        tilt=-0.07,
    )

    neck_y = head_cy + head_r * 0.80
    shoulder = (cx - 4 * s, neck_y + 0.020 * size)
    hip = (cx - 2 * s, size * 0.55)
    stroke_wobbly_line(
        draw,
        shoulder[0],
        shoulder[1],
        hip[0],
        hip[1],
        fill=ink,
        width=line_w,
        scale=scale,
        steps=26,
        phase=1.2,
    )

    sx, sy = shoulder
    # 左臂：水平伸出
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        cx - 0.24 * size,
        sy + 0.02 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=24,
        phase=2.15,
    )
    # 右臂：自然下垂略外张
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        cx + 0.10 * size,
        sy + 0.24 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=24,
        phase=2.7,
    )

    # 左腿承重
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx - 0.10 * size,
        size * 0.74,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.2,
    )
    # 右腿略抬：一笔斜线表现迈步
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx + 0.15 * size,
        size * 0.71,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.55,
    )


def compose_twelve_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_sky_blue_icon(img, vivid=True)
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    faint_breeze_arcs(draw, size, s, (255, 255, 255, 55), max(2, int(2.5 * s)))
    draw_diary_stickman(draw, size)
    return img


def compose_ledger_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_sky_blue_icon(img, vivid=True)
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    faint_breeze_arcs(draw, size, s, (255, 255, 255, 52), max(2, int(2.5 * s)))
    draw_ledger_stickman(draw, size)
    return img
