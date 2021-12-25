/* origin: FreeBSD /usr/src/lib/msun/src/s_log1pf.c */
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
    ln2_hi = 6.9313812256e-01, /* 0x3f317180 */
    ln2_lo = 9.0580006145e-06, /* 0x3717f7d1 */
    /* |(log(1+s)-log(1-s))/s - Lg(s)| < 2**-34.24 (~[-4.95e-11, 4.97e-11]). */
    Lg1 = 0xaaaaaa.0p-24, /* 0.66666662693 */
    Lg2 = 0xccce13.0p-25, /* 0.40000972152 */
    Lg3 = 0x91e9ee.0p-25, /* 0.28498786688 */
    Lg4 = 0xf89e26.0p-26; /* 0.24279078841 */

float32_t
log1pf (float32_t x)
{
	union {float32_t f; uint32_t i;} u = {x};
	float32_t hfsq,f,c,s,z,R,w,t1,t2,dk;
	uint32_t ix,iu;
	int k;

	ix = u.i;
	k = 1;
	if (ix < 0x3ed413d0 || ix>>31) {  /* 1+x < sqrt(2)+  */
		if (ix >= 0xbf800000) {  /* x <= -1.0 */
			if (x == -1)
				return x/0.0f; /* log1p(-1)=+inf */
			return (x-x)/0.0f;     /* log1p(x<-1)=NaN */
		}
		if (ix<<1 < 0x33800000<<1) {   /* |x| < 2**-24 */
			/* underflow if subnormal */
			if ((ix&0x7f800000) == 0)
				FORCE_EVAL(x*x);
			return x;
		}
		if (ix <= 0xbe95f619) { /* sqrt(2)/2- <= 1+x < sqrt(2)+ */
			k = 0;
			c = 0;
			f = x;
		}
	} else if (ix >= 0x7f800000)
		return x;
	if (k) {
		u.f = 1 + x;
		iu = u.i;
		iu += 0x3f800000 - 0x3f3504f3;
		k = (int)(iu>>23) - 0x7f;
		/* correction term ~ log(1+x)-log(u), avoid underflow in c/u */
		if (k < 25) {
			c = k >= 2 ? 1-(u.f-x) : x-(u.f-1);
			c /= u.f;
		} else
			c = 0;
		/* reduce u into [sqrt(2)/2, sqrt(2)] */
		iu = (iu&0x007fffff) + 0x3f3504f3;
		u.i = iu;
		f = u.f - 1;
	}
	s = f/(2.0f + f);
	z = s*s;
	w = z*z;
	t1= w*(Lg2+w*Lg4);
	t2= z*(Lg1+w*Lg3);
	R = t2 + t1;
	hfsq = 0.5f*f*f;
	dk = k;
	return s*(hfsq+R) + (dk*ln2_lo+c) - hfsq + f + dk*ln2_hi;
}


int
main ()
{
    float32_t vals[32] = {
        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.0223a0p+3, // ->  nan32
         0x1.161868p+2, // ->  0x1.ad1bdcp+0
        -0x1.0c34b4p+3, // ->  nan32
        -0x1.a206f0p+2, // ->  nan32
         0x1.288bbcp+3, // ->  0x1.2a1ab8p+1
         0x1.52efd0p-1, // ->  0x1.041a4ep-1
        -0x1.a05cc8p-2, // -> -0x1.0b3596p-1
         0x1.1f9efap-1, // ->  0x1.c88344p-2
         0x1.8c5db0p-1, // ->  0x1.258a8ep-1
        -0x1.5b86eap-1, // -> -0x1.22b542p+0
        // Boundary
         0x1.fffffep+127,
         0x1p-149,
        -0x1p-149,
         0x1p-126,
        -0x1p-126,
        -0x1.000002p+0,
        -0x1.fffffep-1,
        // Special
        float32FromBits(0x7ff01234),
        float32FromBits(0xfff01234),
    };
    for (int i=0; i < sizeof(vals) / sizeof(vals[0]); i++) {
        float32_t input = vals[i];
        if (input == 0) break;
        uint32_t input_bits = *(uint32_t*)(&input);
        printf("IN:  "HEX32"  %+-f  %+-a\n", input_bits, input, input);
        float32_t output = log1pf(input);
        uint32_t output_bits = *(uint32_t*)(&output);
        printf("OUT: "HEX32"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
