"""
Hypothesis tests for the various maths functions.

Compares output between Zig and C.

Run with pytest.

"""

import pathlib
import subprocess

import hypothesis
import pytest
from hypothesis import strategies as st

ROOT_DIR = pathlib.Path("__file__").resolve().parent.parent
UNDER_TEST_BIN_DIR = ROOT_DIR
TRUSTED_BIN_DIR = ROOT_DIR / "quadmath"


st_uint32 = st.integers(min_value=0, max_value=0xFFFF_FFFF)
st_uint64 = st.integers(min_value=0, max_value=0xFFFF_FFFF_FFFF_FFFF)
st_uint128 = st.integers(min_value=0, max_value=0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF)


@hypothesis.given(st_uint32)
def test_exp_32(input: int):
    # TODO: Found failures:
    #   0x3EBE501C
    #   0x3EBE011C
    #   0x3E01011A
    #   0x420201FF
    #   0x7F800002  (NaN)
    input_hex = f"0x{input:08X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st_uint64)
def test_exp_64(input: int):
    # TODO: Found failures:
    #   0x3F71DD0666FCF1BB
    #   0x3F71DD0666FCF1B9
    #   0x3F71DD0666FCF1B7
    #   ...
    #   0x3EB1721900000001
    #   0x3EB1721900000000
    input_hex = f"0x{input:016X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp", input_hex])
    assert actual.upper() == expected.upper()


@pytest.mark.skip("exp_128() not implemented in Zig yet")
@hypothesis.given(st_uint128)
def test_exp_128(input: int):
    input_hex = f"0x{input:032X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st_uint32)
def test_exp2_32(input: int):
    input_hex = f"0x{input:08X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st_uint64)
def test_exp2_64(input: int):
    input_hex = f"0x{input:016X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st_uint128)
def test_exp2_128(input: int):
    input_hex = f"0x{input:032X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()
