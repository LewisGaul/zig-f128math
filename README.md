# Zig f128 math

128-bit float (aka binary128 or quadruple-precision) maths functions for Zig stdlib.


## Notes on floats

Floats (following the IEEE-754 spec) are implemented as follows:
```
sign     exponent            mantissa
  #    ############  #########################
  1         E                    M
```

There is a single 'sign' bit (+ve/-ve), an 'exponent' section, and a 'mantissa' (or 'fraction') section. The first bit of the exponent is the sign.

 bits |      aka            |  E |   M | decimal digits |     max
------|---------------------|---:|----:|:--------------:|:-------------:
 f32  | single precision    |  7 |  23 |    7.22        | 3.4 x 10^38
 f64  | double precision    | 11 |  52 |   15.95        | 3.2 x 10^616
 f128 | quadruple precision | 15 | 112 |   34.02        | 1.2 x 10^4932

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
 0.5       | `0x3F000000` | `0x3FF8000000000000`
 1.0000001 | `0x3F800001` | `0x3FF000001AD7F29B`
 1025      | `0x44802000` | `0x4090040000000000`

Special values:
- `+/- inf` is represented by the exponent being all 1s and the mantissa being all 0s
- `NaN` is represented by the exponent being all 1s with non-zero mantissa

