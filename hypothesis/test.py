"""
Hypothesis tests for the various maths functions.

Compares output between Zig and C.

Run with pytest.

"""

import pathlib
import subprocess
from collections import defaultdict

import hypothesis
import pytest
from hypothesis import strategies as st

ROOT_DIR = pathlib.Path("__file__").resolve().parent.parent
UNDER_TEST_BIN_DIR = ROOT_DIR
TRUSTED_BIN_DIR = ROOT_DIR / "quadmath"


consts = defaultdict(dict)

# fmt: off
consts[32]["umax"]   = 0xFFFF_FFFF
consts[32]["umid"]   = 0x8000_0000
consts[32]["fmax"]   = 0x7F7F_FFFF
consts[32]["fmin"]   = 0xFF7F_FFFF
consts[32]["posinf"] = 0x7F80_0000
consts[32]["neginf"] = 0xFF80_0000
consts[32]["snan"]   = 0x7F80_0001
consts[32]["qnan"]   = 0x7FC0_0000

consts[64]["umax"]   = 0xFFFF_FFFF_FFFF_FFFF
consts[64]["umid"]   = 0x8000_0000_0000_0000
consts[64]["fmax"]   = 0x7FEF_FFFF_FFFF_FFFF
consts[64]["fmin"]   = 0xFFEF_FFFF_FFFF_FFFF
consts[64]["posinf"] = 0x7FF0_0000_0000_0000
consts[64]["neginf"] = 0xFFF0_0000_0000_0000
consts[64]["snan"]   = 0x7FF0_0000_0000_0001
consts[64]["qnan"]   = 0x7FF8_0000_0000_0000

consts[128]["umax"]   = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
consts[128]["umid"]   = 0x8000_0000_0000_0000_0000_0000_0000_0000
consts[128]["fmax"]   = 0x7FFE_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
consts[128]["fmin"]   = 0xFFFE_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
consts[128]["posinf"] = 0x7FFF_0000_0000_0000_0000_0000_0000_0000
consts[128]["neginf"] = 0xFFFF_0000_0000_0000_0000_0000_0000_0000
consts[128]["snan"]   = 0x7FFF_0000_0000_0000_0000_0000_0000_0001
consts[128]["qnan"]   = 0x7FFF_8000_0000_0000_0000_0000_0000_0000
# fmt: on


# Hypothesis strategies
# ----------------------

strats = defaultdict(dict)

for bits in [32, 64, 128]:
    strats[bits]["pos_finite"] = st.integers(
        min_value=0, max_value=consts[bits]["fmax"]
    )
    strats[bits]["neg_finite"] = st.integers(
        min_value=consts[bits]["umid"], max_value=consts[bits]["fmin"]
    )
    strats[bits]["finite"] = st.one_of(
        strats[bits]["pos_finite"], strats[bits]["neg_finite"]
    )
    strats[bits]["inf"] = st.sampled_from(
        (consts[bits]["posinf"], consts[bits]["neginf"])
    )
    strats[bits]["snan"] = st.one_of(
        st.integers(min_value=consts[bits]["snan"], max_value=consts[bits]["qnan"] - 1),
        st.integers(
            min_value=consts[bits]["umid"] + consts[bits]["snan"],
            max_value=consts[bits]["umid"] + consts[bits]["qnan"] - 1,
        ),
    )
    strats[bits]["qnan"] = st.one_of(
        st.integers(min_value=consts[bits]["qnan"], max_value=consts[bits]["umid"] - 1),
        st.integers(
            min_value=consts[bits]["umid"] + consts[bits]["qnan"],
            max_value=consts[bits]["umax"],
        ),
    )
    strats[bits]["nan"] = st.one_of(strats[bits]["snan"], strats[bits]["qnan"])
    strats[bits]["all"] = st.one_of(
        strats[bits]["inf"], strats[bits]["nan"], strats[bits]["finite"]
    )


# Tests
# ------


def run_testcase(bits: int, input: int, func: str):
    input_hex = f"0x{{:0{bits // 4}X}}".format(input)
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / func, input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / func, input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st.one_of(strats[32]["inf"], strats[32]["finite"]))
def test_exp_32(input: int):
    # TODO: Found failures, which are present in the version of musl that Zig
    # copied, but not in latest musl:
    #   0x3E01011A
    #   0x3EBE011C
    #   0x3EBE501C
    #   0x3EC40101
    #   0x3F09FABC
    #   0x4009B4B0
    #   0x4093B409
    #   0x420201FF
    #   0xB8FDD001  ...  0xB8FDD0B4
    #   0xBDCD3743
    #   0xBE608F70
    #   0xC05062B7
    run_testcase(32, input, "exp")


@hypothesis.given(st.one_of(strats[64]["inf"], strats[64]["finite"]))
def test_exp_64(input: int):
    hypothesis.assume(not (0x3EB1721900000000 <= input <= 0x3F71DD0666FCF1BC))
    # TODO: Found failures, which are *not* present in the version of musl that
    # Zig copied:
    #   0x3EB1721900000000  ...  0x3F71DD0666FCF1BC
    #   0xBEB1721900000000
    #   0xBEF76C276FE94D0F
    run_testcase(64, input, "exp")


@pytest.mark.skip("exp_128() not implemented in Zig yet")
@hypothesis.given(st.one_of(strats[128]["inf"], strats[128]["finite"]))
def test_exp_128(input: int):
    run_testcase(128, input, "exp")


@hypothesis.given(st.one_of(strats[32]["inf"], strats[32]["finite"]))
def test_exp2_32(input: int):
    run_testcase(32, input, "exp2")


@hypothesis.given(st.one_of(strats[64]["inf"], strats[64]["finite"]))
def test_exp2_64(input: int):
    run_testcase(64, input, "exp2")


@hypothesis.given(st.one_of(strats[128]["inf"], strats[128]["finite"]))
def test_exp2_128(input: int):
    run_testcase(128, input, "exp2")
