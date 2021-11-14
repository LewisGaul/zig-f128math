/* origin: FreeBSD /usr/src/lib/msun/src/e_expf.c */
/*
 * Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
 */
/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#include "math_private.h"
#include "util.h"

static const float32_t
    half[2] = {0.5,-0.5},
    ln2hi   = 6.9314575195e-1f,  /* 0x3f317200 */
    ln2lo   = 1.4286067653e-6f,  /* 0x35bfbe8e */
    invln2  = 1.4426950216e+0f,  /* 0x3fb8aa3b */
    /*
    * Domain [-0.34568, 0.34568], range ~[-4.278e-9, 4.447e-9]:
    * |x*(exp(x)+1)/(exp(x)-1) - p(x)| < 2**-27.74
    */
    P1 =  1.6666625440e-1f, /*  0xaaaa8f.0p-26 */
    P2 = -2.7667332906e-3f; /* -0xb55215.0p-32 */


float32_t
expf (float32_t x)
{
    float32_t hi, lo, c, xx, y;
    int k, sign;
    uint32_t hx;

    GET_FLOAT_WORD(hx, x);
    sign = hx >> 31;   /* sign bit of x */
    hx &= 0x7fffffff;  /* high word of |x| */

    /* special cases */
    if (hx >= 0x42aeac50) {  /* if |x| >= -87.33655f or NaN */
        if (hx > 0x7f800000) /* NaN */
            return x;
        if (hx >= 0x42b17218 && !sign) {  /* x >= 88.722839f */
            /* overflow */
            x *= 0x1p127f;
            return x;
        }
        if (sign) {
            /* underflow */
            FORCE_EVAL(-0x1p-149f/x);
            if (hx >= 0x42cff1b5)  /* x <= -103.972084f */
                return 0;
        }
    }

    /* argument reduction */
    if (hx > 0x3eb17218) {  /* if |x| > 0.5 ln2 */
        if (hx > 0x3f851592)  /* if |x| > 1.5 ln2 */
            k = invln2*x + half[sign];
        else
            k = 1 - sign - sign;
        hi = x - k*ln2hi;  /* k*ln2hi is exact here */
        lo = k*ln2lo;
        x = hi - lo;
    } else if (hx > 0x39000000) {  /* |x| > 2**-14 */
        k = 0;
        hi = x;
        lo = 0;
    } else {
        /* raise inexact */
        FORCE_EVAL(0x1p127f + x);
        return 1 + x;
    }

    /* x is now in primary range */
    xx = x*x;
    c = x - xx*(P1+xx*P2);
    y = 1 + (x*c/(2-c) - lo + hi);
    if (k == 0)
        return y;
    return scalbnf(y, k);
}


int
main ()
{
    float32_t vals[32] = {
        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.0223a0p+3,
         0x1.161868p+2,
        -0x1.0c34b4p+3,
        -0x1.a206f0p+2,
         0x1.288bbcp+3,
         0x1.52efd0p-1,
        -0x1.a05cc8p-2,
         0x1.1f9efap-1,
         0x1.8c5db0p-1,
        -0x1.5b86eap-1,
        // Boundary
         0x1.62e42ep+6,
         0x1.62e430p+6,
    };
    for (int i=0; i < sizeof(vals) / sizeof(vals[0]); i++) {
        float32_t input = vals[i];
        if (input == 0) break;
        uint32_t input_bits = *(uint32_t*)(&input);
        printf("IN:  "HEX32"  %+-f  %+-a\n", input_bits, input, input);
        float32_t output = expf(input);
        uint32_t output_bits = *(uint32_t*)(&output);
        printf("OUT: "HEX32"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
