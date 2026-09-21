#!/usr/bin/env python3
from __future__ import annotations
import math
import struct
import zlib
from pathlib import Path

W = H = 1024
OUT = Path(__file__).resolve().parent / "FamilyBible" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def px(x: int, y: int) -> tuple[int, int, int]:
    nx, ny = x / W, y / H
    # linen backdrop
    wash = 0.55 * nx + 0.45 * ny
    bg = mix((214, 196, 168), (236, 222, 196), wash)
    # closed family Bible, slightly turned with page block on the right
    left, right, top, bot = 0.18, 0.78, 0.16, 0.86
    pages_r = 0.84
    if left <= nx <= pages_r and top <= ny <= bot:
        # page edge
        if nx > right:
            t = (nx - right) / (pages_r - right)
            return mix((236, 226, 204), (196, 178, 142), t)
        # leather cover
        u = (nx - left) / (right - left)
        v = (ny - top) / (bot - top)
        leather = mix((86, 28, 24), (132, 46, 36), 0.35 + 0.4 * u + 0.15 * (1 - v))
        # inset gold frame
        inset = 0.07
        on_frame = (
            inset < u < 1 - inset
            and inset < v < 1 - inset
            and (u < inset + 0.035 or u > 1 - inset - 0.035 or v < inset + 0.03 or v > 1 - inset - 0.03)
        )
        if on_frame:
            return (212, 168, 78)
        # gold cross
        cx, cy = 0.50, 0.46
        dx, dy = (nx - cx) / 0.22, (ny - cy) / 0.22
        vertical = abs(dx) < 0.11 and -0.55 < dy < 0.72
        horizontal = abs(dy + 0.08) < 0.11 and -0.42 < dx < 0.42
        if vertical or horizontal:
            return (228, 186, 86)
        # title bar
        if 0.28 < u < 0.72 and 0.78 < v < 0.86:
            return mix((196, 150, 64), (168, 118, 48), u)
        return leather
    # soft shadow under the book
    if 0.20 < nx < 0.86 and 0.84 < ny < 0.90:
        return mix(bg, (120, 90, 70), 0.25)
    return bg


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


rows = []
for y in range(H):
    row = b"\x00"
    for x in range(W):
        row += bytes(px(x, y))
    rows.append(row)
png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
png += chunk(b"IEND", b"")
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_bytes(png)
print(OUT, OUT.stat().st_size)
