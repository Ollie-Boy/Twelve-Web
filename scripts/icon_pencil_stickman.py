"""Pencil-style stick figures on a flat light-blue icon (~6 strokes, half / two-thirds body)."""

from __future__ import annotations

from typing import Tuple

from PIL import Image, ImageDraw

from icon_hand_drawn import stroke_wobbly_ellipse, stroke_wobbly_line

Ink = Tuple[int, int, int, int]

# 纯淡蓝色背景（无渐变、无装饰）
LIGHT_BLUE_BG: Tuple[int, int, int, int] = (222, 242, 255, 255)


def _lw(size: int, base: float) -> int:
    s = size / 1024.0
    return max(3, int(base * s))


def draw_diary_stickman(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    侧身行走（向右），动作清楚：摆臂 + 跨步。
    6 笔：头、躯干、前臂、后臂、前腿、后腿。
    """
    s = size / 1024.0
    scale = s * 0.85
    ink: Ink = (55, 68, 88, 255)
    line_w = _lw(size, 12)
    head_w = _lw(size, 10)

    # 面向右侧的剪影
    head_cx = size * 0.34
    head_cy = size * 0.29
    head_r = 0.082 * size
    stroke_wobbly_ellipse(
        draw,
        head_cx,
        head_cy,
        head_r,
        head_r * 1.05,
        fill=None,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=44,
        phase=0.5,
        wobble_mult=1.25,
        tilt=0.06,
    )

    neck_y = head_cy + head_r * 0.78
    shoulder = (head_cx + 0.045 * size, neck_y + 0.012 * size)
    hip = (head_cx + 0.11 * size, size * 0.52)
    stroke_wobbly_line(
        draw,
        shoulder[0],
        shoulder[1],
        hip[0],
        hip[1],
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=1.0,
    )

    sx, sy = shoulder
    # 前摆臂（向前）
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        sx + 0.16 * size,
        sy - 0.06 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=1.9,
    )
    # 后摆臂
    stroke_wobbly_line(
        draw,
        sx,
        sy,
        sx - 0.10 * size,
        sy + 0.08 * size,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=2.4,
    )

    hx, hy = hip
    # 前腿（迈出去）
    stroke_wobbly_line(
        draw,
        hx,
        hy,
        hx + 0.14 * size,
        size * 0.74,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.0,
    )
    # 后腿
    stroke_wobbly_line(
        draw,
        hx,
        hy,
        hx - 0.08 * size,
        size * 0.72,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=22,
        phase=3.45,
    )


def draw_ledger_stickman(draw: ImageDraw.ImageDraw, size: int) -> None:
    """
    正面站立，双手在身前汇合（捧账 / 单据），腿略分开站稳。
    6 笔：头、躯干、左臂、右臂、左腿、右腿。
    """
    s = size / 1024.0
    scale = s * 0.85
    ink: Ink = (50, 65, 85, 255)
    line_w = _lw(size, 12)
    head_w = _lw(size, 10)

    cx = size * 0.5
    head_cy = size * 0.30
    head_r = 0.084 * size
    stroke_wobbly_ellipse(
        draw,
        cx,
        head_cy,
        head_r * 1.02,
        head_r * 0.98,
        fill=None,
        outline=ink,
        width=head_w,
        scale=scale,
        segments=44,
        phase=0.25,
        wobble_mult=1.22,
        tilt=0.0,
    )

    neck_y = head_cy + head_r * 0.80
    shoulder_y = neck_y + 0.018 * size
    shoulder_half = 0.055 * size
    hip = (cx, size * 0.54)
    stroke_wobbly_line(
        draw,
        cx,
        shoulder_y,
        hip[0],
        hip[1],
        fill=ink,
        width=line_w,
        scale=scale,
        steps=24,
        phase=1.05,
    )

    hands_x = cx
    hands_y = size * 0.44
    # 左臂 → 身前中间
    stroke_wobbly_line(
        draw,
        cx - shoulder_half,
        shoulder_y + 0.01 * size,
        hands_x - 0.02 * size,
        hands_y,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=2.0,
    )
    # 右臂 → 身前中间
    stroke_wobbly_line(
        draw,
        cx + shoulder_half,
        shoulder_y + 0.01 * size,
        hands_x + 0.02 * size,
        hands_y,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=2.5,
    )

    foot_y = size * 0.74
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx - 0.09 * size,
        foot_y,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=3.05,
    )
    stroke_wobbly_line(
        draw,
        hip[0],
        hip[1],
        cx + 0.09 * size,
        foot_y,
        fill=ink,
        width=line_w,
        scale=scale,
        steps=20,
        phase=3.4,
    )


def compose_twelve_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), LIGHT_BLUE_BG)
    draw = ImageDraw.Draw(img)
    draw_diary_stickman(draw, size)
    return img


def compose_ledger_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), LIGHT_BLUE_BG)
    draw = ImageDraw.Draw(img)
    draw_ledger_stickman(draw, size)
    return img
