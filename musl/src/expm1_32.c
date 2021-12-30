/* origin: FreeBSD /usr/src/lib/msun/src/s_expm1f.c */
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
    o_threshold = 8.8721679688e+01, /* 0x42b17180 */
    ln2_hi      = 6.9313812256e-01, /* 0x3f317180 */
    ln2_lo      = 9.0580006145e-06, /* 0x3717f7d1 */
    invln2      = 1.4426950216e+00, /* 0x3fb8aa3b */
    /*
    * Domain [-0.34568, 0.34568], range ~[-6.694e-10, 6.696e-10]:
    * |6 / x * (1 + 2 * (1 / (exp(x) - 1) - 1 / x)) - q(x)| < 2**-30.04
    * Scaled coefficients: Qn_here = 2**n * Qn_for_q (see s_expm1.c):
    */
    Q1 = -3.3333212137e-2, /* -0x888868.0p-28 */
    Q2 =  1.5807170421e-3; /*  0xcf3010.0p-33 */


float32_t
expm1f (float32_t x)
{
    float32_t y,hi,lo,c,t,e,hxs,hfx,r1,twopk;
    union {float32_t f; uint32_t i;} u = {x};
    uint32_t hx = u.i & 0x7fffffff;
    int k, sign = u.i >> 31;

    /* filter out huge and non-finite argument */
    if (hx >= 0x4195b844) {  /* if |x|>=27*ln2 */
        if (hx > 0x7f800000)  /* NaN */
            return x;
        if (sign)
            return -1;
        if (x > o_threshold) {
            x *= 0x1p127f;
            return x;
        }
    }

    /* argument reduction */
    if (hx > 0x3eb17218) {           /* if  |x| > 0.5 ln2 */
        if (hx < 0x3F851592) {       /* and |x| < 1.5 ln2 */
            if (!sign) {
                hi = x - ln2_hi;
                lo = ln2_lo;
                k =  1;
            } else {
                hi = x + ln2_hi;
                lo = -ln2_lo;
                k = -1;
            }
        } else {
            k  = invln2*x + (sign ? -0.5f : 0.5f);
            t  = k;
            hi = x - t*ln2_hi;      /* t*ln2_hi is exact here */
            lo = t*ln2_lo;
        }
        x = hi-lo;
        c = (hi-x)-lo;
    } else if (hx < 0x33000000) {  /* when |x|<2**-25, return x */
        if (hx < 0x00800000)
            FORCE_EVAL(x*x);
        return x;
    } else
        k = 0;

    /* x is now in primary range */
    hfx = 0.5f*x;
    hxs = x*hfx;
    r1 = 1.0f+hxs*(Q1+hxs*Q2);
    t  = 3.0f - r1*hfx;
    e  = hxs*((r1-t)/(6.0f - x*t));
    if (k == 0)  /* c is 0 */
        return x - (x*e-hxs);
    e  = x*(e-c) - c;
    e -= hxs;
    /* exp(x) ~ 2^k (x_reduced - e + 1) */
    if (k == -1)
        return 0.5f*(x-e) - 0.5f;
    if (k == 1) {
        if (x < -0.25f)
            return -2.0f*(e-(x+0.5f));
        return 1.0f + 2.0f*(x-e);
    }
    u.i = (0x7f+k)<<23;  /* 2^k */
    twopk = u.f;
    if (k < 0 || k > 56) {   /* suffice to return exp(x)-1 */
        y = x - e + 1.0f;
        if (k == 128)
            y = y*2.0f*0x1p127f;
        else
            y = y*twopk;
        return y - 1.0f;
    }
    u.i = (0x7f-k)<<23;  /* 2^-k */
    if (k < 23)
        y = (x-e+(1-u.f))*twopk;
    else
        y = (x-(e+u.f)+1)*twopk;
    return y;
}


int
main ()
{
    float32_t vals[64] = {
        -0x1.a05cc8p-2,
        -0x1.5b86eap-1,

        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.0223a0p+3, // -> -0x1.ffd6e0p-1
         0x1.161868p+2, // ->  0x1.30712ap+6
        -0x1.0c34b4p+3, // -> -0x1.ffe1fap-1
        -0x1.a206f0p+2, // -> -0x1.ff4116p-1
         0x1.288bbcp+3, // ->  0x1.4ab480p+13
         0x1.52efd0p-1, // ->  0x1.e09536p-1
        -0x1.a05cc8p-2, // -> -0x1.561c3ep-2
         0x1.1f9efap-1, // ->  0x1.81ec4ep-1
         0x1.8c5db0p-1, // ->  0x1.2b3364p+0
        -0x1.5b86eap-1, // -> -0x1.f8951ap-2
        // Boundary
         0x1.fffffep+127,
         0x1p-149,
        -0x1p-149,
         0x1p-126,
        -0x1p-126,
         0x1.62e300p+6,
         0x1.62e302p+6,
        -0x1.154244p+4,
        -0x1.154246p+4,
        // Special
        float32FromBits(0x7f801234), // sNaN
        float32FromBits(0x7fc01234), // qNaN
        float32FromBits(0xffc01234), // -qNaN
    };
    for (int i=0; i < sizeof(vals) / sizeof(vals[0]); i++) {
        float32_t input = vals[i];
        if (input == 0) break;
        uint32_t input_bits = *(uint32_t*)(&input);
        printf("IN:  "HEX32"  %+-f  %+-a\n", input_bits, input, input);
        float32_t output = expm1f(input);
        uint32_t output_bits = *(uint32_t*)(&output);
        printf("OUT: "HEX32"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
