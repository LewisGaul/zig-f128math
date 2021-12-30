/* origin: FreeBSD /usr/src/lib/msun/src/e_log2f.c */
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
/*
 * See comments in log2.c.
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#include "math_private.h"
#include "util.h"

static const float32_t
    ivln2hi =  1.4428710938e+00, /* 0x3fb8b000 */
    ivln2lo = -1.7605285393e-04, /* 0xb9389ad4 */
    /* |(log(1+s)-log(1-s))/s - Lg(s)| < 2**-34.24 (~[-4.95e-11, 4.97e-11]). */
    Lg1 = 0xaaaaaa.0p-24, /* 0.66666662693 */
    Lg2 = 0xccce13.0p-25, /* 0.40000972152 */
    Lg3 = 0x91e9ee.0p-25, /* 0.28498786688 */
    Lg4 = 0xf89e26.0p-26; /* 0.24279078841 */

float32_t
log2f (float32_t x)
{
	union {float32_t f; uint32_t i;} u = {x};
	float32_t hfsq,f,s,z,R,w,t1,t2,hi,lo;
	uint32_t ix;
	int k;

	ix = u.i;
	k = 0;
	if (ix < 0x00800000 || ix>>31) {  /* x < 2**-126  */
		if (ix<<1 == 0)
			return -1/(x*x);  /* log(+-0)=-inf */
		if (ix>>31)
			return (x-x)/0.0f; /* log(-#) = NaN */
		/* subnormal number, scale up x */
		k -= 25;
		x *= 0x1p25f;
		u.f = x;
		ix = u.i;
	} else if (ix >= 0x7f800000) {
		return x;
	} else if (ix == 0x3f800000)
		return 0;

	/* reduce x into [sqrt(2)/2, sqrt(2)] */
	ix += 0x3f800000 - 0x3f3504f3;
	k += (int)(ix>>23) - 0x7f;
	ix = (ix&0x007fffff) + 0x3f3504f3;
	u.i = ix;
	x = u.f;

	f = x - 1.0f;
	s = f/(2.0f + f);
	z = s*s;
	w = z*z;
	t1= w*(Lg2+w*Lg4);
	t2= z*(Lg1+w*Lg3);
	R = t2 + t1;
	hfsq = 0.5f*f*f;

	hi = f - hfsq;
	u.f = hi;
	u.i &= 0xfffff000;
	hi = u.f;
	lo = f - hi - hfsq + s*(hfsq+R);
	return (lo+hi)*ivln2lo + lo*ivln2hi + hi*ivln2hi + k;
}


int
main ()
{
    float32_t vals[32] = {
        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.0223a0p+3, // -> nan32
         0x1.161868p+2, // -> 0x1.0f49acp+1
        -0x1.0c34b4p+3, // -> nan32
        -0x1.a206f0p+2, // -> nan32
         0x1.288bbcp+3, // -> 0x1.9b2676p+1
         0x1.52efd0p-1, // ->-0x1.30b492p-1
        -0x1.a05cc8p-2, // -> nan32
         0x1.1f9efap-1, // ->-0x1.a9f89ap-1
         0x1.8c5db0p-1, // ->-0x1.7a2c96p-2
        -0x1.5b86eap-1, // -> nan32
        // Boundary
         0x1.fffffep+127,
         0x1p-149,
        -0x1p-149,
         0x1p-126,
        -0x1p-126,
         0x1.000002p+0,
         0x1.fffffep-1,
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
        float32_t output = log2f(input);
        uint32_t output_bits = *(uint32_t*)(&output);
        printf("OUT: "HEX32"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
