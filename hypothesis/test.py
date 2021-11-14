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


# fmt: off
u32_max    = 0xFFFF_FFFF
u32_mid    = 0x8000_0000
f32_max    = 0x7F7F_FFFF
f32_min    = 0xFF7F_FFFF
f32_posinf = 0x7F80_0000
f32_neginf = 0xFF80_0000
f32_snan   = 0x7F80_0001
f32_qnan   = 0x7FC0_0000

u64_max    = 0xFFFF_FFFF_FFFF_FFFF
u64_mid    = 0x8000_0000_0000_0000
f64_max    = 0x7FEF_FFFF_FFFF_FFFF
f64_min    = 0xFFEF_FFFF_FFFF_FFFF
f64_posinf = 0x7FF0_0000_0000_0000
f64_neginf = 0xFFF0_0000_0000_0000
f64_snan   = 0x7FF0_0000_0000_0001
f64_qnan   = 0x7FF8_0000_0000_0000

u128_max    = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
u128_mid    = 0x8000_0000_0000_0000_0000_0000_0000_0000
f128_max    = 0x7FFE_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
f128_min    = 0xFFFE_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
f128_posinf = 0x7FFF_0000_0000_0000_0000_0000_0000_0000
f128_neginf = 0xFFFF_0000_0000_0000_0000_0000_0000_0000
f128_snan   = 0x7FFF_0000_0000_0000_0000_0000_0000_0001
f128_qnan   = 0x7FFF_8000_0000_0000_0000_0000_0000_0000
# fmt: on


# Hypothesis strategies
# ----------------------

st_u32 = st.integers(min_value=0, max_value=u32_max)
st_u64 = st.integers(min_value=0, max_value=u64_max)
st_u128 = st.integers(min_value=0, max_value=u128_max)

st_f32_pos_finite = st.integers(min_value=0, max_value=f32_max)
st_f32_neg_finite = st.integers(min_value=u32_mid, max_value=f32_min)
st_f32_finite = st.one_of(st_f32_pos_finite, st_f32_neg_finite)
st_f32_inf = st.sampled_from((f32_posinf, f32_neginf))
st_f32_snan = st.one_of(
    st.integers(min_value=f32_snan, max_value=f32_qnan - 1),
    st.integers(min_value=u32_mid + f32_snan, max_value=u32_mid + f32_qnan - 1),
)
st_f32_qnan = st.one_of(
    st.integers(min_value=f32_qnan, max_value=u32_mid),
    st.integers(min_value=u32_mid + f32_qnan, max_value=u32_max),
)
st_f32_nan = st.one_of(st_f32_snan, st_f32_qnan)
st_f32_all = st.one_of(st_f32_inf, st_f32_nan, st_f32_finite)

st_f64_pos_finite = st.integers(min_value=0, max_value=f64_max)
st_f64_neg_finite = st.integers(min_value=u64_mid, max_value=f64_min)
st_f64_finite = st.one_of(st_f64_pos_finite, st_f64_neg_finite)
st_f64_inf = st.sampled_from((f64_posinf, f64_neginf))
st_f64_snan = st.one_of(
    st.integers(min_value=f64_snan, max_value=f64_qnan - 1),
    st.integers(min_value=u64_mid + f64_snan, max_value=u64_mid + f64_qnan - 1),
)
st_f64_qnan = st.one_of(
    st.integers(min_value=f64_qnan, max_value=u64_mid),
    st.integers(min_value=u64_mid + f64_qnan, max_value=u64_max),
)
st_f64_nan = st.one_of(st_f64_snan, st_f64_qnan)
st_f64_all = st.one_of(st_f64_inf, st_f64_nan, st_f64_finite)

st_f128_pos_finite = st.integers(min_value=0, max_value=f128_max)
st_f128_neg_finite = st.integers(min_value=u128_mid, max_value=f128_min)
st_f128_finite = st.one_of(st_f128_pos_finite, st_f128_neg_finite)
st_f128_inf = st.sampled_from((f128_posinf, f128_neginf))
st_f128_snan = st.one_of(
    st.integers(min_value=f128_snan, max_value=f128_qnan - 1),
    st.integers(min_value=u128_mid + f128_snan, max_value=u128_mid + f128_qnan - 1),
)
st_f128_qnan = st.one_of(
    st.integers(min_value=f128_qnan, max_value=u128_mid),
    st.integers(min_value=u128_mid + f128_qnan, max_value=u128_max),
)
st_f128_nan = st.one_of(st_f128_snan, st_f128_qnan)
st_f128_all = st.one_of(st_f128_inf, st_f128_nan, st_f128_finite)


# Tests
# ------


@hypothesis.given(st.one_of(st_f32_inf, st_f32_finite))
def test_exp_32(input: int):
    # Bug in GCC where signalling NaNs are not converted to quiet NaNs.
    hypothesis.assume(not (0x7F800002 < input < 0x7FBFFFFF))
    # TODO: Found failures:
    #   0x3EBE501C
    #   0x3EBE011C
    #   0x3E01011A
    #   0x3F09FABC
    #   0x420201FF
    #   0xBE608F70
    #   0xC05062B7
    input_hex = f"0x{input:08X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st.one_of(st_f64_inf, st_f64_finite))
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
@hypothesis.given(st.one_of(st_f128_inf, st_f128_finite))
def test_exp_128(input: int):
    input_hex = f"0x{input:032X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st.one_of(st_f32_inf, st_f32_finite))
def test_exp2_32(input: int):
    input_hex = f"0x{input:08X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st.one_of(st_f64_inf, st_f64_finite))
def test_exp2_64(input: int):
    input_hex = f"0x{input:016X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()


@hypothesis.given(st.one_of(st_f128_inf, st_f128_finite))
def test_exp2_128(input: int):
    input_hex = f"0x{input:032X}"
    hypothesis.note(f"Input: {input_hex}")
    expected = subprocess.check_output([TRUSTED_BIN_DIR / "exp2", input_hex])
    actual = subprocess.check_output([UNDER_TEST_BIN_DIR / "exp2", input_hex])
    assert actual.upper() == expected.upper()
