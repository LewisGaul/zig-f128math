# Zig f128 math

128-bit float (aka binary128 or [quadruple-precision](https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format)) maths functions for Zig stdlib.


## Notes on floats

See <https://en.wikipedia.org/wiki/IEEE_754>.

Floats (following the IEEE-754 spec) are implemented as follows:
```
sign     exponent            mantissa
  #    ############  #########################
  1         E                    M
```

There is a single 'sign' bit (+ve/-ve), an 'exponent' section, and a 'mantissa' (or 'fraction') section. The first bit of the exponent is the sign.

 bits | precision | C name      |  E |   M | decimal digits |     max
------|-----------|-------------|---:|----:|:--------------:|:-------------:
 f32  | single    | float       |  7 |  23 |    7.22        | 3.4 x 10^38
 f64  | double    | double      | 11 |  52 |   15.95        | 3.2 x 10^616
 f128 | quadruple | long double | 15 | 112 |   34.02        | 1.2 x 10^4932

Number of digits is given by `(M+1)/log2(10)`, max value is given by `10^(2^E/log2(10))`.


Some examples (try out <https://babbage.cs.qc.cuny.edu/IEEE-754/>):

 decimal   | f32          | f64
:---------:|--------------|------------------
 0         | `0x00000000` | `0x0000000000000000`
 2         | `0x40000000` | `0x4000000000000000`
 3         | `0x40400000` | `0x4008000000000000`
 1         | `0x3F800000` | `0x3FF0000000000000`
 -1        | `0xBF800000` | `0xBFF0000000000000`
 1.5       | `0x3FC00000` | `0x3FF8000000000000`
 0.5       | `0x3F000000` | `0x3FE0000000000000`
 1.0000001 | `0x3F800001` | `0x3FF000001AD7F29B`
 1025      | `0x44802000` | `0x4090040000000000`

Special values:
- `+/-inf` is represented by the exponent being all 1s and the mantissa being all 0s
- `NaN` is represented by the exponent being all 1s with non-zero mantissa

Note the following exceptions defined in IEEE-754: <https://www.gnu.org/software/libc/manual/html_node/FP-Exceptions.html>.


## Implementation of maths functions

The Zig issue tracking addition of support for `f128` in the stdlib maths functions is [#40126](https://github.com/ziglang/zig/issues/4026). The original issue that tracked the initial work is [#374](https://github.com/ziglang/zig/issues/374), and the work was done on [tiehuis/zig-fmath](https://github.com/tiehuis/zig-fmath).

Inspiration taken from:
- Zig: [lib/std/math/](https://github.com/ziglang/zig/tree/master/lib/std/math)
- Musl: [src/math/](https://git.musl-libc.org/cgit/musl/tree/src/math)
- Go: [src/math/](https://github.com/golang/go/tree/master/src/math)
- GCC: [libquadmath/math/](https://github.com/gcc-mirror/gcc/tree/master/libquadmath/math)
- FreeBSD: [lib/msun/](https://cgit.freebsd.org/src/tree/lib/msun)
- OpenLibm (built for Julia lang): <https://github.com/JuliaMath/openlibm>

The error of function implementations is often quoted in terms of 'ULP', which stands for 'Units in the Last Place', i.e. a multiple of the smallest unit of precision that can be represented by a given number of bytes. If the error of a function is higher than 0.5 ULP then the result may be wrong in the last digit.


### Resources

- Tang, P. "Table-driven Implementation of the Exponential Function in IEEE Floating-Point Arithmetic". TOMS 15(2), 144-157 (1989).
- Gal, S. and Bachelis, B. "An Accurate Elementary Mathematical Library	for the IEEE Floating Point Standard". TOMS 17(1), 26-46 (1991).
- Abraham Ziv, "Fast Evaluation of Elementary Mathematical Functions with Correctly Rounded Last Bit". ACM Trans. Math. Soft., 17 (3), 410-423, (1991).


### Function: `exp2(x: float) -> float`

Return the result of `2` raised to the given argument.

We approach this as follows:
- Handle special cases:
  - `exp2(nan) -> nan`
  - `exp2(+inf) -> +inf`
  - `exp2(-inf) -> 0`
  - Input is sufficiently large/small such that we get an overflow/underflow (to `inf` or `0`)
- Reduce using table of values
- Approximate solution using Chebyshev polynomial on a narrowed range

Single and double precision are implemented based on the *old* Musl implementation (mid Sept 2017), which appeared to be based on FreeBSD. There is a new implementation in Musl based on <https://github.com/ARM-software/optimized-routines> (for single/double precision only) since 2017/18.

Quadruple precision will be based on *current* Musl, since this still matches FreeBSD and uses the same method as double precision.

#### GCC approach

[quadruple precision](https://github.com/gcc-mirror/gcc/blob/master/libquadmath/math/exp2q.c)

GCC calculates `exp2()` using `exp()` (base `e`). I'm not sure why it's done this way round, as I would have thought base 2 would be the more natural one to implement... See `exp()` section below.

#### Musl approach

[single precision](https://git.musl-libc.org/cgit/musl/tree/src/math/exp2f.c)

Using a different method to others - based on <https://github.com/ARM-software/optimized-routines/tree/master/math> (since commit `3f94c648`, 2017). Claims to achieve 1.8x with `-O3` for `expf()` (not as good for `exp2()`).

[double precision](https://git.musl-libc.org/cgit/musl/tree/src/math/exp2.c)

Also based on the above (since commit `e16f7b3c0`, 2018). Claims to achieve similar (slightly better) improvements to single precision.

[quadruple precision](https://git.musl-libc.org/cgit/musl/tree/src/math/exp2l.c)

The implementation of quadruple precision comes from FreeBSD (`lib/msun/ld80/s_exp2l.c` and `lib/msun/ld128/s_exp2l.c`) - implementation depends on choice of format for `long double` via a `#ifdef`.

#### FreeBSD approach

[single precision](https://cgit.freebsd.org/src/tree/lib/msun/src/s_exp2f.c)

> Accuracy: Peak error `< 0.501 ulp`; location of peak: `-0.030110927`.
>
> Method: (equally-spaced tables)
>
>   Reduce `x`:
>     `x = 2**k + y`, for integer `k` and `|y| <= 1/2`.
>     Thus we have `exp2(x) = 2**k * exp2(y)`.
>
>   Reduce `y`:
>     `y = i/TBLSIZE + z` for integer `i` near `y * TBLSIZE`.
>     Thus we have `exp2(y) = exp2(i/TBLSIZE) * exp2(z)`,
>     with `|z| <= 2**-(TBLSIZE+1)`.
>
>   We compute `exp2(i/TBLSIZE)` via table lookup and `exp2(z)` via a
>   degree-4 minimax polynomial with maximum error under `1.4 * 2**-33`.
>   Using double precision for everything except the reduction makes
>   roundoff error insignificant and simplifies the scaling step.
>
>   This method is due to Tang, but I do not use his suggested parameters:
>
>	Tang, P.  Table-driven Implementation of the Exponential Function
>	in IEEE Floating-Point Arithmetic.  TOMS 15(2), 144-157 (1989).

[double precision](https://cgit.freebsd.org/src/tree/lib/msun/src/s_exp2.c)

> Accuracy: Peak error `< 0.503 ulp` for normalized results.
>
> Method: (accurate tables)
>
>   Reduce `x`:
>     `x = 2**k + y`, for integer `k` and `|y| <= 1/2`.
>     Thus we have `exp2(x) = 2**k * exp2(y)`.
>
>   Reduce `y`:
>     `y = i/TBLSIZE + z - eps[i]` for integer `i` near `y * TBLSIZE`.
>     Thus we have `exp2(y) = exp2(i/TBLSIZE) * exp2(z - eps[i])`,
>     with `|z - eps[i]| <= 2**-9 + 2**-39` for the table used.
>
>   We compute `exp2(i/TBLSIZE)` via table lookup and `exp2(z - eps[i])` via
>   a degree-5 minimax polynomial with maximum error under `1.3 * 2**-61`.
>   The values in `exp2t[]` and `eps[]` are chosen such that
>   `exp2t[i] = exp2(i/TBLSIZE + eps[i])`, and `eps[i]` is a small offset such
>   that `exp2t[i]` is accurate to `2**-64`.
>
>   Note that the range of `i` is `+-TBLSIZE/2`, so we actually index the tables
>   by `i0 = i + TBLSIZE/2`. For cache efficiency, `exp2t[]` and `eps[]` are
>   virtual tables, interleaved in the real table `tbl[]`.
>
>   This method is due to Gal, with many details due to Gal and Bachelis:
>
>	Gal, S. and Bachelis, B.  An Accurate Elementary Mathematical Library
>	for the IEEE Floating Point Standard.  TOMS 17(1), 26-46 (1991).

[quadruple precision](https://cgit.freebsd.org/src/tree/lib/msun/ld128/s_exp2l.c)

> Accuracy: Peak error `< 0.502 ulp`.
>
> Method: (accurate tables)
>
>   Reduce `x`:
>     `x = 2**k + y`, for integer `k` and `|y| <= 1/2`.
>     Thus we have `exp2(x) = 2**k * exp2(y)`.
>
>   Reduce `y`:
>     `y = i/TBLSIZE + z - eps[i]` for integer `i` near `y * TBLSIZE`.
>     Thus we have `exp2(y) = exp2(i/TBLSIZE) * exp2(z - eps[i])`,
>     with `|z - eps[i]| <= 2**-8 + 2**-98` for the table used.
>
>   We compute `exp2(i/TBLSIZE)` via table lookup and `exp2(z - eps[i])` via
>   a degree-10 minimax polynomial with maximum error under `2**-120`.
>   The values in `exp2t[]` and `eps[]` are chosen such that
>   `exp2t[i] = exp2(i/TBLSIZE + eps[i])`, and `eps[i]` is a small offset such
>   that `exp2t[i]` is accurate to `2**-122`.
>
>   Note that the range of `i` is `+-TBLSIZE/2`, so we actually index the tables
>   by `i0 = i + TBLSIZE/2`.
>
>   This method is due to Gal, with many details due to Gal and Bachelis:
>
>	Gal, S. and Bachelis, B.  An Accurate Elementary Mathematical Library
>	for the IEEE Floating Point Standard.  TOMS 17(1), 26-46 (1991).

#### OpenLibm approach

The same as FreeBSD.

#### Go approach

<https://github.com/golang/go/blob/master/src/math/exp.go>

Appears to be based on Sun Microsystems. Only has double precision implementation, doesn't use table of values?

#### Tang

Used by:
- FreeBSD, OpenLibm (single precision)

#### Gal & Bachelis

Used by:
- FreeBSD, OpenLibm (double/quadruple precision), Musl (quadruple precision)
  - 10-degree polynomial for quad

A detailed description of the approach is given below for the range of 'normal' values, following the code snippet given.
```zig
fn exp2_64(x: f64) f64 {
    const tblsiz = @intCast(u32, exp2dt.len / 2);
    const redux: f64 = 0x1.8p52 / @intToFloat(f64, tblsiz);
    const P1: f64 = 0x1.62e42fefa39efp-1;
    const P2: f64 = 0x1.ebfbdff82c575p-3;
    const P3: f64 = 0x1.c6b08d704a0a6p-5;
    const P4: f64 = 0x1.3b2ab88f70400p-7;
    const P5: f64 = 0x1.5d88003875c74p-10;

    const ux = @bitCast(u64, x);
    const ix = @intCast(u32, ux >> 32) & 0x7FFFFFFF;

    // reduce x
    var uf: f64 = x + redux;
    // NOTE: musl performs an implicit 64-bit to 32-bit u32 truncation here
    var i_0: u32 = @truncate(u32, @bitCast(u64, uf));
    _ = @addWithOverflow(u32, i_0, tblsiz / 2, &i_0);

    const k: u32 = i_0 / tblsiz * tblsiz;
    const ik: i32 = @bitCast(i32, k / tblsiz);
    i_0 %= tblsiz;
    uf -= redux;

    // r = exp2(y) = exp2t[i_0] * p(z - eps[i])
    var z: f64 = x - uf;
    const t: f64 = exp2dt[@intCast(usize, 2 * i_0)];
    z -= exp2dt[@intCast(usize, 2 * i_0 + 1)];
    const r: f64 = t + t * z * (P1 + z * (P2 + z * (P3 + z * (P4 + z * P5))));

    return math.scalbn(r, ik);
}
```

* Where does the `redux` value `0x1.8p52` come from?
  * This is setting the top two bits (1.1000...), with the exponent set to the size of the mantissa (52 bits) and only the top bit in the mantissa set.
  * When you add `x` this will discard any part of `x` that is too small to fit in the mantissa with the high-bit set.
* Examples of the first step, where `redux=@bitCast(f64,0x42b8000000000000)` is added (with table size 256):
  * `x=1`: `uf=0x42b8000000000100` - no reduction
  * `x=0.511`: `uf=0x42b8000000000083` - the `0.01` is removed
* ... TODO ...

#### Other

Used by:
- Musl (single/double precision)
  - Based on <https://github.com/ARM-software/optimized-routines>
- GCC (quadruple precision)
  - Uses `exp()`, which uses Abraham Ziv's method


### Function: `exp(x: float) -> float`

Return the result of `e` raised to the given argument.


#### GCC approach

<https://github.com/gcc-mirror/gcc/blob/master/libquadmath/math/expq.c>

The design is taken from Abraham Ziv, "Fast Evaluation of Elementary Mathematical Functions with Correctly Rounded Last Bit", ACM Trans. Math. Soft., 17 (3), September 1991, pp. 410-423.

The input is split into a high part and a low part. Calculations with the high part must be exact.

The input value is written as

`x = n * ln(2)_0 + arg1[t1]_0 + arg2[t2]_0 + x - n * ln(2)_1 + arg1[t1]_1 + arg2[t2]_1 + xl`

where:
- `n` is an integer, `16384 >= n >= -16495`
- `ln(2)_0` is the first 93 bits of `ln(2)`, and `|ln(2)_0-ln(2)-ln(2)_1| < 2^-205`
- `t1` is an integer, `89 >= t1 >= -89`
- `t2` is an integer, `65 >= t2 >= -65`
- `|arg1[t1]-t1/256.0| < 2^-53`
- `|arg2[t2]-t2/32768.0| < 2^-53`
- `x + xl` is whatever is left, `|x + xl| < 2^-16 + 2^-53`

Then `e^x` is approximated as

`e^x = 2^n_1 ( 2^n_0 e^(arg1[t1]_0 + arg1[t1]_1) e^(arg2[t2]_0 + arg2[t2]_1) + 2^n_0 e^(arg1[t1]_0 + arg1[t1]_1) e^(arg2[t2]_0 + arg2[t2]_1) * p (x + xl + n * ln(2)_1))`

where:
- `p(x)` is a polynomial approximating `e(x)-1`
- `e^(arg1[t1]_0 + arg1[t1]_1)` is obtained from a table
- `e^(arg2[t2]_0 + arg2[t2]_1)` likewise
- `n_1 + n_0 = n`, so that `|n_0| < -FLT128_MIN_EXP-1`

In most cases `n_1 == 0`, meaning there is a multiplication that can be omitted.
