/* origin: FreeBSD /usr/src/lib/msun/src/e_log2.c */
/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunSoft, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */
/*
 * Return the base 2 logarithm of x.  See log.c for most comments.
 *
 * Reduce x to 2^k (1+f) and calculate r = log(1+f) - f + f*f/2
 * as in log.c, then combine and scale in extra precision:
 *    log2(x) = (f - f*f/2 + r)/log(2) + k
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#include "math_private.h"
#include "util.h"

static const float64_t
    ivln2hi = 1.44269504072144627571e+00, /* 0x3ff71547, 0x65200000 */
    ivln2lo = 1.67517131648865118353e-10, /* 0x3de705fc, 0x2eefa200 */
    Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
    Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
    Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
    Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
    Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
    Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
    Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

float64_t log2(float64_t x)
{
	union {float64_t f; uint64_t i;} u = {x};
	float64_t hfsq,f,s,z,R,w,t1,t2,y,hi,lo,val_hi,val_lo;
	uint32_t hx;
	int k;

	hx = u.i>>32;
	k = 0;
	if (hx < 0x00100000 || hx>>31) {
		if (u.i<<1 == 0)
			return -1/(x*x);  /* log(+-0)=-inf */
		if (hx>>31)
			return (x-x)/0.0; /* log(-#) = NaN */
		/* subnormal number, scale x up */
		k -= 54;
		x *= 0x1p54;
		u.f = x;
		hx = u.i>>32;
	} else if (hx >= 0x7ff00000) {
		return x;
	} else if (hx == 0x3ff00000 && u.i<<32 == 0)
		return 0;

	/* reduce x into [sqrt(2)/2, sqrt(2)] */
	hx += 0x3ff00000 - 0x3fe6a09e;
	k += (int)(hx>>20) - 0x3ff;
	hx = (hx&0x000fffff) + 0x3fe6a09e;
	u.i = (uint64_t)hx<<32 | (u.i&0xffffffff);
	x = u.f;

	f = x - 1.0;
	hfsq = 0.5*f*f;
	s = f/(2.0+f);
	z = s*s;
	w = z*z;
	t1 = w*(Lg2+w*(Lg4+w*Lg6));
	t2 = z*(Lg1+w*(Lg3+w*(Lg5+w*Lg7)));
	R = t2 + t1;

	/*
	 * f-hfsq must (for args near 1) be evaluated in extra precision
	 * to avoid a large cancellation when x is near sqrt(2) or 1/sqrt(2).
	 * This is fairly efficient since f-hfsq only depends on f, so can
	 * be evaluated in parallel with R.  Not combining hfsq with R also
	 * keeps R small (though not as small as a true `lo' term would be),
	 * so that extra precision is not needed for terms involving R.
	 *
	 * Compiler bugs involving extra precision used to break Dekker's
	 * theorem for spitting f-hfsq as hi+lo, unless float64_t was used
	 * or the multi-precision calculations were avoided when float64_t
	 * has extra precision.  These problems are now automatically
	 * avoided as a side effect of the optimization of combining the
	 * Dekker splitting step with the clear-low-bits step.
	 *
	 * y must (for args near sqrt(2) and 1/sqrt(2)) be added in extra
	 * precision to avoid a very large cancellation when x is very near
	 * these values.  Unlike the above cancellations, this problem is
	 * specific to base 2.  It is strange that adding +-1 is so much
	 * harder than adding +-ln2 or +-log10_2.
	 *
	 * This uses Dekker's theorem to normalize y+val_hi, so the
	 * compiler bugs are back in some configurations, sigh.  And I
	 * don't want to used float64_t to avoid them, since that gives a
	 * pessimization and the support for avoiding the pessimization
	 * is not yet available.
	 *
	 * The multi-precision calculations for the multiplications are
	 * routine.
	 */

	/* hi+lo = f - hfsq + s*(hfsq+R) ~ log(1+f) */
	hi = f - hfsq;
	u.f = hi;
	u.i &= (uint64_t)-1<<32;
	hi = u.f;
	lo = f - hi - hfsq + s*(hfsq+R);

	val_hi = hi*ivln2hi;
	val_lo = (lo+hi)*ivln2lo + lo*ivln2hi;

	/* spadd(val_hi, val_lo, y), except for not using float64_t: */
	y = k;
	w = y + val_hi;
	val_lo += (y - w) + val_hi;
	val_hi = w;

	return val_lo + val_hi;
}


int
main ()
{
    float64_t vals[32] = {
        1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.02239f3c6a8f1p+3, // ->  nan64
         0x1.161868e18bc67p+2, // ->  0x1.0f49ac3838580p+1
        -0x1.0c34b3e01e6e7p+3, // ->  nan64
        -0x1.a206f0a19dcc4p+2, // ->  nan64
         0x1.288bbb0d6a1e6p+3, // ->  0x1.9b26760c2a57ep+1
         0x1.52efd0cd80497p-1, // -> -0x1.30b490ef684c7p-1
        -0x1.a05cc754481d1p-2, // ->  nan64
         0x1.1f9ef934745cbp-1, // -> -0x1.a9f89b5f5acb8p-1
         0x1.8c5db097f7442p-1, // -> -0x1.7a2c947173f06p-2
        -0x1.5b86ea8118a0ep-1, // ->  nan64
        // Boundary
         0x1.fffffffffffffp+1023,
         0x1p-1074,
        -0x1p-1074,
         0x1p-1022,
        -0x1p-1022,
         0x1.0000000000001p+0,
         0x1.fffffffffffffp-1,
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
        float64_t output = log2(input);
        uint64_t output_bits = *(uint64_t*)(&output);
        printf("OUT: "HEX64"  %+-f  %+-a\n\n", output_bits, output, output);
    }
}
