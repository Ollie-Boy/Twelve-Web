#!/usr/bin/env python3
"""Twelve app icon: minimal hand-drawn book on white."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from icon_book_wallet import compose_twelve_book_icon  # noqa: E402


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "Twelve" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    base = compose_twelve_book_icon(1024)
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
