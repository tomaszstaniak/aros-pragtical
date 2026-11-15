#!/usr/bin/env python3
"""Write an AROS PNG icon (.info) from a PNG picture.

    scripts/make-icon.py <picture.png> <out.info> --type tool --stack 8000000
    scripts/make-icon.py <picture.png> <out.info> --type drawer

An AROS PNG icon is an ordinary PNG file with one more chunk, `icOn`, placed
before `IEND`. The chunk holds big-endian records of an attribute identifier
followed by a 32-bit value. The picture is used as it is; scale it first.
"""
import argparse
import struct
import zlib
from pathlib import Path

ATTR_STACKSIZE = 0x80001009
ATTR_TYPE = 0x8000100F
ATTR_FRAMELESS = 0x80001010
TYPES = {"disk": 1, "drawer": 2, "tool": 3, "project": 4}
SIGNATURE = b"\x89PNG\r\n\x1a\n"


def chunk(kind, body):
    crc = zlib.crc32(kind + body) & 0xFFFFFFFF
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", crc)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("picture")
    parser.add_argument("out")
    parser.add_argument("--type", default="tool", choices=sorted(TYPES))
    parser.add_argument("--stack", type=int, default=0)
    args = parser.parse_args()

    png = Path(args.picture).read_bytes()
    if png[:8] != SIGNATURE:
        raise SystemExit(f"make-icon: {args.picture} is not a PNG file")

    body = struct.pack(">II", ATTR_FRAMELESS, 1)
    if args.stack:
        body += struct.pack(">II", ATTR_STACKSIZE, args.stack)
    body += struct.pack(">II", ATTR_TYPE, TYPES[args.type])

    out = bytearray(png[:8])
    position = 8
    placed = False
    while position < len(png):
        length = struct.unpack(">I", png[position:position + 4])[0]
        kind = png[position + 4:position + 8]
        end = position + 12 + length
        if kind == b"icOn":
            position = end
            continue
        if kind == b"IEND":
            out += chunk(b"icOn", body)
            placed = True
        out += png[position:end]
        position = end
    if not placed:
        raise SystemExit(f"make-icon: {args.picture} has no IEND chunk")
    Path(args.out).write_bytes(out)


if __name__ == "__main__":
    main()
