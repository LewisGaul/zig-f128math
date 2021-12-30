#!/usr/bin/env python3

import argparse
import enum
import logging
import os.path
import re
import sys
import textwrap
from typing import Optional, NamedTuple, Tuple

import tabulate


tabulate.PRESERVE_WHITESPACE = True


class FloatType(enum.Enum):
    F16 = enum.auto()
    F32 = enum.auto()
    F64 = enum.auto()
    F128 = enum.auto()
    C_LONGDOUBLE = enum.auto()

    @property
    def bits(self) -> int:
        if re.match(r"F\d+", self.name):
            return int(self.name[1:])
        else:
            assert self is FloatType.C_LONGDOUBLE
            return 80

    @property
    def exp_bits(self) -> int:
        if self is FloatType.F16:
            return 5
        elif self is FloatType.F32:
            return 8
        elif self is FloatType.F64:
            return 11
        elif self is FloatType.F128:
            return 15
        elif self is FloatType.C_LONGDOUBLE:
            return 16
        else:
            assert False

    @property
    def mantissa_bits(self) -> int:
        if self is FloatType.F16:
            return 10
        elif self is FloatType.F32:
            return 23
        elif self is FloatType.F64:
            return 52
        elif self is FloatType.F128:
            return 112
        elif self is FloatType.C_LONGDOUBLE:
            return 63
        else:
            assert False

    @property
    def num_hex_digits(self) -> int:
        return (self.mantissa_bits - 1) // 4 + 1


class RoundingMode(enum.Flag):
    RN = enum.auto()
    RU = enum.auto()
    RD = enum.auto()
    RZ = enum.auto()
    ALL = RN | RU | RD | RZ

    def __str__(self):
        return self.name


class FloatExcFlag(enum.Flag):
    NONE = 0
    INVALID = enum.auto()
    INEXACT = enum.auto()
    DIVBYZERO = enum.auto()
    OVERFLOW = enum.auto()
    UNDERFLOW = enum.auto()

    @classmethod
    def from_str(cls, string: str) -> "FloatExcFlag":
        if string == "0":
            return cls.NONE
        flag = cls.NONE
        for f in string.split("|"):
            flag |= getattr(cls, f)
        return flag

    def __str__(self):
        flags = []
        for mode in FloatExcFlag:
            if mode in self and mode is not FloatExcFlag.NONE:
                flags.append(mode)
        if flags:
            return "|".join(f.name for f in flags)
        else:
            return "NONE"


hex_float_regex = r"-?0x1(?:\.[\da-f]+)?p[+-]\d+[LQ]?"
hex_float_regex_plus_zero = rf"{hex_float_regex}|-?0x0p\+0[LQ]?"
hex_float_regex_all = rf"{hex_float_regex_plus_zero}|-?inf|nan"
rounding_mode_regex = "|".join(f.name for f in RoundingMode)
exc_flag_regex = "|".join(f.name for f in FloatExcFlag)
exc_flag_regex_all = rf"0|(?:(?:{exc_flag_regex})(?:\|(?:{exc_flag_regex}))*)"


def canonicalise_float(fstr: str, ftype: FloatType) -> str:
    if re.fullmatch(r"-?inf|nan", fstr):
        return fstr
    # If the number is just a small int, convert to basic int format.
    if m := re.fullmatch(r"-?0x(\d)(?:\.0)?p\+0[LQ]?", fstr):
        return m.group(1)
    # If no decimal places, just return what we have.
    if m := re.fullmatch(r"(-?0x1p[+-]\d+)[LQ]?", fstr):
        return m.group(1)

    match = re.fullmatch(r"-?0x1\.([\da-f]+)p([+-]\d+)[LQ]?", fstr)
    assert match is not None
    maybe_sign = "-" if fstr[0] == "-" else ""
    after_point_digits = match.group(1)
    if ftype.num_hex_digits - len(after_point_digits) < 2:
        after_point_digits += "0" * (ftype.num_hex_digits - len(after_point_digits))
    after_p_exp = match.group(2)

    return f"{maybe_sign}0x1.{after_point_digits}p{after_p_exp}"


class Testcase(NamedTuple):
    rounding_mode: RoundingMode
    input: str
    output: str
    err: str
    exc_flags: FloatExcFlag
    comment: Optional[str]

    def to_row(self) -> Tuple[str, ...]:
        return (
            ".{",
            str(self.rounding_mode) + ",",
            (" " if self.input[0] != "-" else "") + self.input + ",",
            (" " if self.output[0] != "-" else "") + self.output + ",",
            (" " if self.err[0] != "-" else "") + self.err + ",",
            str(self.exc_flags),
            "},",
            "// " + self.comment if self.comment else "",
        )


def parse_line(
    line: str,
    float_type: FloatType,
    rounding_modes: RoundingMode,
) -> Optional[Testcase]:
    line = line.strip()
    if line.startswith("//") or not line:
        return None

    match = re.match(
        rf"T\(\s*"
        rf"({rounding_mode_regex}),\s*"
        rf"({hex_float_regex_all}),\s*"
        rf"({hex_float_regex_all}),\s*"
        rf"({hex_float_regex_plus_zero}),\s*"
        rf"({exc_flag_regex_all})\s*"
        rf"\)\s*"
        rf"(?://\s*(.+?)\s*)?",
        line,
    )
    if not match:
        logging.warning("Unrecognised line: %s", line)
        return None

    rounding_mode = getattr(RoundingMode, match.group(1))
    if rounding_mode not in rounding_modes:
        logging.debug("Skipping testcase with rounding mode %r", rounding_mode.name)
        return None
    f_input = canonicalise_float(match.group(2), float_type)
    f_output = canonicalise_float(match.group(3), float_type)
    f_err = canonicalise_float(match.group(4), FloatType.F32)
    exc_flags = FloatExcFlag.from_str(match.group(5))
    comment = match.group(6)

    return Testcase(rounding_mode, f_input, f_output, f_err, exc_flags, comment)


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose",
                        action="store_true",
                        help="Enable debug logging")
    parser.add_argument("-a", "--all",
                        action="store_true",
                        help="Include tests for all rounding modes")
    parser.add_argument("file",
                        metavar="PATH",
                        help="Path to file of tests to parse")
    return parser.parse_args(argv)


def main(argv) -> None:
    args = parse_args(argv)
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    with open(args.file, "r") as f:
        lines = f.readlines()

    # We assume the given file corresponds to tests of a single float size,
    # which we try to work out now.
    float_type = None
    # First look for suffixes ('L' for long double, 'Q' for quad).
    for L in lines:
        if re.search(r"T\(.*0x1\.\d+p[+-]?\d+Q", L):
            float_type = FloatType.F128
            break
        if re.search(r"T\(.*0x1\.\d+p[+-]?\d+L", L):
            float_type = FloatType.F64
            break
    if not float_type:
        # Then look for values that don't fit in smaller float sizes.
        for L in lines:
            if m := re.search(r"T\(.*0x1\.(\d+)p[+-]?(\d+)", L):
                if len(m.group(1)) > 6 or int(m.group(2)) > 127:
                    float_type = FloatType.F64
                    break
    if not float_type:
        # Finally, assume f32.
        float_type = FloatType.F32

    rounding_modes = RoundingMode.ALL if args.all else RoundingMode.RN

    testcase_lines = {
        i: tc.to_row()
        for i, L in enumerate(lines)
        if (tc := parse_line(L, float_type, rounding_modes))
    }
    table = tabulate.tabulate(testcase_lines.values(), tablefmt="plain")
    table = re.sub(r" {2}(\S)", r" \1", table)  # Reduce space between columns
    table_lines = iter(table.splitlines())
    first_table_line_idx = list(testcase_lines)[0]

    print(textwrap.dedent(f"""\
        // This file has been automatically generated from the libc-test suite by
        // the {os.path.basename(sys.argv[0])} script. Comments in the original file (including
        // copyright) have all been kept intact.

        const math = @import("../../math.zig");
        const inf = math.inf({float_type.name.lower()});
        const nan = math.nan({float_type.name.lower()});

        // zig fmt: off

        // TODO: Better handling for the exception bitfield and rounding mode enum.
        const RN = 0x0;
        const RD = 0x1;
        const RU = 0x2;
        const RZ = 0x3;

        const NONE      = 0x00;
        const INVALID   = 0x01;
        const INEXACT   = 0x02;
        const DIVBYZERO = 0x04;
        const OVERFLOW  = 0x08;
        const UNDERFLOW = 0x10;

    """))
    if first_table_line_idx > 0:
        print("".join(lines[:first_table_line_idx]))
        print()
    print("const testcases = .{")
    for i, L in enumerate(lines[first_table_line_idx:], start=first_table_line_idx):
        if i in testcase_lines:
            print(" " * 4 + next(table_lines).rstrip())
        elif parse_line(L, float_type, RoundingMode.ALL):
            continue
        else:
            line = lines[i].strip()
            if line:
                print(" " * 4 + line)
            else:
                print()
    print("};")


if __name__ == "__main__":
    main(sys.argv[1:])
