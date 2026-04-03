#!/usr/bin/env python3
"""Ledger app icon: hand-drawn wallet on blue–white gradient, black linework."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from icon_book_wallet import compose_ledger_wallet_icon  # noqa: E402


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "Ledger" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    base = compose_ledger_wallet_icon(1024)
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
