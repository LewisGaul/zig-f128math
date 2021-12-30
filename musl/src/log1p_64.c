/* origin: FreeBSD /usr/src/lib/msun/src/s_log1p.c */
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
/* float64_t log1p(float64_t x)
 * Return the natural logarithm of 1+x.
 *
 * Method :
 *   1. Argument Reduction: find k and f such that
 *                      1+x = 2^k * (1+f),
 *         where  sqrt(2)/2 < 1+f < sqrt(2) .
 *
 *      Note. If k=0, then f=x is exact. However, if k!=0, then f
 *      may not be representable exactly. In that case, a correction
 *      term is need. Let u=1+x rounded. Let c = (1+x)-u, then
 *      log(1+x) - log(u) ~ c/u. Thus, we proceed to compute log(u),
 *      and add back the correction term c/u.
 *      (Note: when x > 2**53, one can simply return log(x))
 *
 *   2. Approximation of log(1+f): See log.c
 *
 *   3. Finally, log1p(x) = k*ln2 + log(1+f) + c/u. See log.c
 *
 * Special cases:
 *      log1p(x) is NaN with signal if x < -1 (including -INF) ;
 *      log1p(+INF) is +INF; log1p(-1) is -INF with signal;
 *      log1p(NaN) is that NaN with no signal.
 *
 * Accuracy:
 *      according to an error analysis, the error is always less than
 *      1 ulp (unit in the last place).
 *
 * Constants:
 * The hexadecimal values are the intended ones for the following
 * constants. The decimal values may be used, provided that the
 * compiler will convert from decimal to binary accurately enough
 * to produce the hexadecimal values shown.
 *
 * Note: Assuming log() return accurate answer, the following
 *       algorithm can be used to compute log1p(x) to within a few ULP:
 *
 *              u = 1+x;
 *              if(u==1.0) return x ; else
 *                         return log(u)*(x/(u-1.0));
 *
 *       See HP-15C Advanced Functions Handbook, p.193.
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#include "math_private.h"
#include "util.h"

static const float64_t
    ln2_hi = 6.93147180369123816490e-01,  /* 3fe62e42 fee00000 */
    ln2_lo = 1.90821492927058770002e-10,  /* 3dea39ef 35793c76 */
    Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
    Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
    Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
    Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
    Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
    Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
    Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

float64_t
log1p (float64_t x)
{
	union {float64_t f; uint64_t i;} u = {x};
	float64_t hfsq,f,c,s,z,R,w,t1,t2,dk;
	uint32_t hx,hu;
	int k;

	hx = u.i>>32;
	k = 1;
	if (hx < 0x3fda827a || hx>>31) {  /* 1+x < sqrt(2)+ */
		if (hx >= 0xbff00000) {  /* x <= -1.0 */
			if (x == -1)
				return x/0.0; /* log1p(-1) = -inf */
			return (x-x)/0.0;     /* log1p(x<-1) = NaN */
		}
		if (hx<<1 < 0x3ca00000<<1) {  /* |x| < 2**-53 */
			/* underflow if subnormal */
			if ((hx&0x7ff00000) == 0)
				FORCE_EVAL((float)x);
			return x;
		}
		if (hx <= 0xbfd2bec4) {  /* sqrt(2)/2- <= 1+x < sqrt(2)+ */
			k = 0;
			c = 0;
			f = x;
		}
	} else if (hx >= 0x7ff00000)
		return x;
	if (k) {
		u.f = 1 + x;
		hu = u.i>>32;
		hu += 0x3ff00000 - 0x3fe6a09e;
		k = (int)(hu>>20) - 0x3ff;
		/* correction term ~ log(1+x)-log(u), avoid underflow in c/u */
		if (k < 54) {
			c = k >= 2 ? 1-(u.f-x) : x-(u.f-1);
			c /= u.f;
		} else
			c = 0;
		/* reduce u into [sqrt(2)/2, sqrt(2)] */
		hu = (hu&0x000fffff) + 0x3fe6a09e;
		u.i = (uint64_t)hu<<32 | (u.i&0xffffffff);
		f = u.f - 1;
	}
	hfsq = 0.5*f*f;
	s = f/(2.0+f);
	z = s*s;
	w = z*z;
	t1 = w*(Lg2+w*(Lg4+w*Lg6));
	t2 = z*(Lg1+w*(Lg3+w*(Lg5+w*Lg7)));
	R = t2 + t1;
	dk = k;
	return s*(hfsq+R) + (dk*ln2_lo+c) - hfsq + f + dk*ln2_hi;
}


int
main ()
{
    float64_t vals[32] = {
        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.02239f3c6a8f1p+3, // ->  nan64
         0x1.161868e18bc67p+2, // ->  0x1.ad1bdd1e9e687p+0
        -0x1.0c34b3e01e6e7p+3, // ->  nan64
        -0x1.a206f0a19dcc4p+2, // ->  nan64
         0x1.288bbb0d6a1e6p+3, // ->  0x1.2a1ab8365b56fp+1
         0x1.52efd0cd80497p-1, // ->  0x1.041a4ec2a680ap-1
        -0x1.a05cc754481d1p-2, // -> -0x1.0b3595423aec1p-1
         0x1.1f9ef934745cbp-1, // ->  0x1.c8834348a846ep-2
         0x1.8c5db097f7442p-1, // ->  0x1.258a8e8a35bbfp-1
        -0x1.5b86ea8118a0ep-1, // -> -0x1.22b5426327502p+0
        // Boundary
         0x1.fffffffffffffp+1023,
         0x1p-1074,
        -0x1p-1074,
         0x1p-1022,
        -0x1p-1022,
        -0x1.0000000000001p+0,
        -0x1.fffffffffffffp-1,
        // Special
        float64FromBits(0x7ff0123400000000), // sNaN
        float64FromBits(0x7ff8123400000000), // qNaN
        float64FromBits(0xfff8123400000000), // -qNaN
    };
    for (int i=0; i < sizeof(vals) / sizeof(vals[0]); i++) {
        float64_t input = vals[i];
        if (input == 0) break;
        uint64_t input_bits = *(uint64_t*)(&input);
        printf("IN:  "HEX64"  %+-f  %+-a\n", input_bits, input, input);
        float64_t output = log1p(input);
        uint64_t output_bits = *(uint64_t*)(&output);
        printf("OUT: "HEX64"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
