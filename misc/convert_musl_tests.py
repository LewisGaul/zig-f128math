#!/usr/bin/env python3

import logging
import re
import textwrap
from typing import Iterable, Optional


hex_float_decimals = {32: 6, 64: 13}
hex_float_regex = r"[- ]0x1\.[\da-f]+p[+-]\d+"

def get_bits(float: str) -> int:
    before, _ = float.split("p")
    hex_decimals = len(before) - len("-0x1.")
    return 32 if hex_decimals <= hex_float_decimals[32] else 64


def canonicalise_float(float: str, bits: Optional[int] = None) -> str:
    if float in ["nan", "inf", "-inf"]:
        if float[0] != "-":
            float = " " + float
        if bits:
            float += str(bits)
        return float
    before, after = float.split("p")
    hex_decimals = len(before) - len("-0x1.")
    if not bits:
        bits = get_bits(float)
    before = before + "0" * (hex_float_decimals[bits] - hex_decimals)
    return f"{before}p{after}"


def convert_line(line: str) -> Optional[str]:
    line = line.strip()
    match = re.match(rf"T\(RN,\s*({hex_float_regex}),\s*({hex_float_regex}|nan|-?inf),", line)
    if not match:
        logging.warning("Unrecognised line: %s", line)
        return None
    bits = get_bits(match.group(1))
    in_float = canonicalise_float(match.group(1), bits)
    out_float = canonicalise_float(match.group(2), bits)
    out_float_padding = " " * (len(in_float) - len(out_float))
    return f"tc{bits}({in_float}, {out_float}{out_float_padding}),"


if __name__ == "__main__":
    while True:
        lines = []
        while L := input():
            lines.append(L)

        for L in lines:
            if out := convert_line(L):
                print(textwrap.indent(out, " " * 8))

        print()
