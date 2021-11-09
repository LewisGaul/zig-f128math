/* from: FreeBSD: head/lib/msun/ld128/s_expl.c 251345 2013-06-03 20:09:22Z kargl */

/*-
 * SPDX-License-Identifier: BSD-2-Clause-FreeBSD
 *
 * Copyright (c) 2009-2013 Steven G. Kargl
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice unmodified, this list of conditions, and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Optimized by Bruce D. Evans.
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#include "math_private.h"
#include "util.h"


/*
 * --------------------------------------------------------------
 * Start of k_expl.c
 */

/*
 * ld128 version of k_expl.h.  See ../ld80/s_expl.c for most comments.
 *
 * See ../src/e_exp.c and ../src/k_exp.h for precision-independent comments
 * about the secondary kernels.
 */

#define	INTERVALS	    128
#define	LOG2_INTERVALS	7
#define	BIAS	        (LDBL_MAX_EXP - 1)

static const float64_t
    /*
    * ln2/INTERVALS = L1+L2 (hi+lo decomposition for multiplication).  L1 must
    * have at least 22 (= log2(|LDBL_MIN_EXP-extras|) + log2(INTERVALS)) lowest
    * bits zero so that multiplication of it by n is exact.
    */
    INV_L = 1.8466496523378731e+2,		/*  0x171547652b82fe.0p-45 */
    L2 = -1.0253670638894731e-29;		/* -0x1.9ff0342542fc3p-97 */

static const float128_t
    /* 0x1.62e42fefa39ef35793c768000000p-8 */
    L1 =  5.41521234812457272982212595914567508e-3Q;

/*
 * XXX values in hex in comments have been lost (or were never present)
 * from here.
 */
static const float128_t
    /*
    * Domain [-0.002708, 0.002708], range ~[-2.4021e-38, 2.4234e-38]:
    * |exp(x) - p(x)| < 2**-124.9
    * (0.002708 is ln2/(2*INTERVALS) rounded up a little).
    *
    * XXX the coeffs aren't very carefully rounded, and I get 3.6 more bits.
    */
    A2  =  0.5,
    A3  =  1.66666666666666666666666666651085500e-1Q,
    A4  =  4.16666666666666666666666666425885320e-2Q,
    A5  =  8.33333333333333333334522877160175842e-3Q,
    A6  =  1.38888888888888888889971139751596836e-3Q;

static const float64_t
    A7  =  1.9841269841269470e-4,		/*  0x1.a01a01a019f91p-13 */
    A8  =  2.4801587301585286e-5,		/*  0x1.71de3ec75a967p-19 */
    A9  =  2.7557324277411235e-6,		/*  0x1.71de3ec75a967p-19 */
    A10 =  2.7557333722375069e-7;		/*  0x1.27e505ab56259p-22 */

static const struct {
	/*
	 * hi must be rounded to at most 106 bits so that multiplication
	 * by r1 in expm1l() is exact, but it is rounded to 88 bits due to
	 * historical accidents.
	 *
	 * XXX it is wasteful to use float128_t for both hi and lo.  ld128
	 * exp2l() uses only float32_t for lo (in a very differently organized
	 * table; ld80 exp2l() is different again.  It uses 2 doubles in a
	 * table organized like this one.  1 double and 1 float32_t would
	 * suffice).  There are different packing/locality/alignment/caching
	 * problems with these methods.
	 *
	 * XXX C's bad %a format makes the bits unreadable.  They happen
	 * to all line up for the hi values 1 before the point and 88
	 * in 22 nybbles, but for the low values the nybbles are shifted
	 * randomly.
	 */
	float128_t	hi;
	float128_t	lo;
} tbl[INTERVALS] = {
	0x1p0Q, 0x0p0Q,
	0x1.0163da9fb33356d84a66aep0Q, 0x3.36dcdfa4003ec04c360be2404078p-92Q,
	0x1.02c9a3e778060ee6f7cacap0Q, 0x4.f7a29bde93d70a2cabc5cb89ba10p-92Q,
	0x1.04315e86e7f84bd738f9a2p0Q, 0xd.a47e6ed040bb4bfc05af6455e9b8p-96Q,
	0x1.059b0d31585743ae7c548ep0Q, 0xb.68ca417fe53e3495f7df4baf84a0p-92Q,
	0x1.0706b29ddf6ddc6dc403a8p0Q, 0x1.d87b27ed07cb8b092ac75e311753p-88Q,
	0x1.0874518759bc808c35f25cp0Q, 0x1.9427fa2b041b2d6829d8993a0d01p-88Q,
	0x1.09e3ecac6f3834521e060cp0Q, 0x5.84d6b74ba2e023da730e7fccb758p-92Q,
	0x1.0b5586cf9890f6298b92b6p0Q, 0x1.1842a98364291408b3ceb0a2a2bbp-88Q,
	0x1.0cc922b7247f7407b705b8p0Q, 0x9.3dc5e8aac564e6fe2ef1d431fd98p-92Q,
	0x1.0e3ec32d3d1a2020742e4ep0Q, 0x1.8af6a552ac4b358b1129e9f966a4p-88Q,
	0x1.0fb66affed31af232091dcp0Q, 0x1.8a1426514e0b627bda694a400a27p-88Q,
	0x1.11301d0125b50a4ebbf1aep0Q, 0xd.9318ceac5cc47ab166ee57427178p-92Q,
	0x1.12abdc06c31cbfb92bad32p0Q, 0x4.d68e2f7270bdf7cedf94eb1cb818p-92Q,
	0x1.1429aaea92ddfb34101942p0Q, 0x1.b2586d01844b389bea7aedd221d4p-88Q,
	0x1.15a98c8a58e512480d573cp0Q, 0x1.d5613bf92a2b618ee31b376c2689p-88Q,
	0x1.172b83c7d517adcdf7c8c4p0Q, 0x1.0eb14a792035509ff7d758693f24p-88Q,
	0x1.18af9388c8de9bbbf70b9ap0Q, 0x3.c2505c97c0102e5f1211941d2840p-92Q,
	0x1.1a35beb6fcb753cb698f68p0Q, 0x1.2d1c835a6c30724d5cfae31b84e5p-88Q,
	0x1.1bbe084045cd39ab1e72b4p0Q, 0x4.27e35f9acb57e473915519a1b448p-92Q,
	0x1.1d4873168b9aa7805b8028p0Q, 0x9.90f07a98b42206e46166cf051d70p-92Q,
	0x1.1ed5022fcd91cb8819ff60p0Q, 0x1.121d1e504d36c47474c9b7de6067p-88Q,
	0x1.2063b88628cd63b8eeb028p0Q, 0x1.50929d0fc487d21c2b84004264dep-88Q,
	0x1.21f49917ddc962552fd292p0Q, 0x9.4bdb4b61ea62477caa1dce823ba0p-92Q,
	0x1.2387a6e75623866c1fadb0p0Q, 0x1.c15cb593b0328566902df69e4de2p-88Q,
	0x1.251ce4fb2a63f3582ab7dep0Q, 0x9.e94811a9c8afdcf796934bc652d0p-92Q,
	0x1.26b4565e27cdd257a67328p0Q, 0x1.d3b249dce4e9186ddd5ff44e6b08p-92Q,
	0x1.284dfe1f5638096cf15cf0p0Q, 0x3.ca0967fdaa2e52d7c8106f2e262cp-92Q,
	0x1.29e9df51fdee12c25d15f4p0Q, 0x1.a24aa3bca890ac08d203fed80a07p-88Q,
	0x1.2b87fd0dad98ffddea4652p0Q, 0x1.8fcab88442fdc3cb6de4519165edp-88Q,
	0x1.2d285a6e4030b40091d536p0Q, 0xd.075384589c1cd1b3e4018a6b1348p-92Q,
	0x1.2ecafa93e2f5611ca0f45cp0Q, 0x1.523833af611bdcda253c554cf278p-88Q,
	0x1.306fe0a31b7152de8d5a46p0Q, 0x3.05c85edecbc27343629f502f1af2p-92Q,
	0x1.32170fc4cd8313539cf1c2p0Q, 0x1.008f86dde3220ae17a005b6412bep-88Q,
	0x1.33c08b26416ff4c9c8610cp0Q, 0x1.96696bf95d1593039539d94d662bp-88Q,
	0x1.356c55f929ff0c94623476p0Q, 0x3.73af38d6d8d6f9506c9bbc93cbc0p-92Q,
	0x1.371a7373aa9caa7145502ep0Q, 0x1.4547987e3e12516bf9c699be432fp-88Q,
	0x1.38cae6d05d86585a9cb0d8p0Q, 0x1.bed0c853bd30a02790931eb2e8f0p-88Q,
	0x1.3a7db34e59ff6ea1bc9298p0Q, 0x1.e0a1d336163fe2f852ceeb134067p-88Q,
	0x1.3c32dc313a8e484001f228p0Q, 0xb.58f3775e06ab66353001fae9fca0p-92Q,
	0x1.3dea64c12342235b41223ep0Q, 0x1.3d773fba2cb82b8244267c54443fp-92Q,
	0x1.3fa4504ac801ba0bf701aap0Q, 0x4.1832fb8c1c8dbdff2c49909e6c60p-92Q,
	0x1.4160a21f72e29f84325b8ep0Q, 0x1.3db61fb352f0540e6ba05634413ep-88Q,
	0x1.431f5d950a896dc7044394p0Q, 0x1.0ccec81e24b0caff7581ef4127f7p-92Q,
	0x1.44e086061892d03136f408p0Q, 0x1.df019fbd4f3b48709b78591d5cb5p-88Q,
	0x1.46a41ed1d005772512f458p0Q, 0x1.229d97df404ff21f39c1b594d3a8p-88Q,
	0x1.486a2b5c13cd013c1a3b68p0Q, 0x1.062f03c3dd75ce8757f780e6ec99p-88Q,
	0x1.4a32af0d7d3de672d8bcf4p0Q, 0x6.f9586461db1d878b1d148bd3ccb8p-92Q,
	0x1.4bfdad5362a271d4397afep0Q, 0xc.42e20e0363ba2e159c579f82e4b0p-92Q,
	0x1.4dcb299fddd0d63b36ef1ap0Q, 0x9.e0cc484b25a5566d0bd5f58ad238p-92Q,
	0x1.4f9b2769d2ca6ad33d8b68p0Q, 0x1.aa073ee55e028497a329a7333dbap-88Q,
	0x1.516daa2cf6641c112f52c8p0Q, 0x4.d822190e718226177d7608d20038p-92Q,
	0x1.5342b569d4f81df0a83c48p0Q, 0x1.d86a63f4e672a3e429805b049465p-88Q,
	0x1.551a4ca5d920ec52ec6202p0Q, 0x4.34ca672645dc6c124d6619a87574p-92Q,
	0x1.56f4736b527da66ecb0046p0Q, 0x1.64eb3c00f2f5ab3d801d7cc7272dp-88Q,
	0x1.58d12d497c7fd252bc2b72p0Q, 0x1.43bcf2ec936a970d9cc266f0072fp-88Q,
	0x1.5ab07dd48542958c930150p0Q, 0x1.91eb345d88d7c81280e069fbdb63p-88Q,
	0x1.5c9268a5946b701c4b1b80p0Q, 0x1.6986a203d84e6a4a92f179e71889p-88Q,
	0x1.5e76f15ad21486e9be4c20p0Q, 0x3.99766a06548a05829e853bdb2b52p-92Q,
	0x1.605e1b976dc08b076f592ap0Q, 0x4.86e3b34ead1b4769df867b9c89ccp-92Q,
	0x1.6247eb03a5584b1f0fa06ep0Q, 0x1.d2da42bb1ceaf9f732275b8aef30p-88Q,
	0x1.6434634ccc31fc76f8714cp0Q, 0x4.ed9a4e41000307103a18cf7a6e08p-92Q,
	0x1.66238825522249127d9e28p0Q, 0x1.b8f314a337f4dc0a3adf1787ff74p-88Q,
	0x1.68155d44ca973081c57226p0Q, 0x1.b9f32706bfe4e627d809a85dcc66p-88Q,
	0x1.6a09e667f3bcc908b2fb12p0Q, 0x1.66ea957d3e3adec17512775099dap-88Q,
	0x1.6c012750bdabeed76a9980p0Q, 0xf.4f33fdeb8b0ecd831106f57b3d00p-96Q,
	0x1.6dfb23c651a2ef220e2cbep0Q, 0x1.bbaa834b3f11577ceefbe6c1c411p-92Q,
	0x1.6ff7df9519483cf87e1b4ep0Q, 0x1.3e213bff9b702d5aa477c12523cep-88Q,
	0x1.71f75e8ec5f73dd2370f2ep0Q, 0xf.0acd6cb434b562d9e8a20adda648p-92Q,
	0x1.73f9a48a58173bd5c9a4e6p0Q, 0x8.ab1182ae217f3a7681759553e840p-92Q,
	0x1.75feb564267c8bf6e9aa32p0Q, 0x1.a48b27071805e61a17b954a2dad8p-88Q,
	0x1.780694fde5d3f619ae0280p0Q, 0x8.58b2bb2bdcf86cd08e35fb04c0f0p-92Q,
	0x1.7a11473eb0186d7d51023ep0Q, 0x1.6cda1f5ef42b66977960531e821bp-88Q,
	0x1.7c1ed0130c1327c4933444p0Q, 0x1.937562b2dc933d44fc828efd4c9cp-88Q,
	0x1.7e2f336cf4e62105d02ba0p0Q, 0x1.5797e170a1427f8fcdf5f3906108p-88Q,
	0x1.80427543e1a11b60de6764p0Q, 0x9.a354ea706b8e4d8b718a672bf7c8p-92Q,
	0x1.82589994cce128acf88afap0Q, 0xb.34a010f6ad65cbbac0f532d39be0p-92Q,
	0x1.8471a4623c7acce52f6b96p0Q, 0x1.c64095370f51f48817914dd78665p-88Q,
	0x1.868d99b4492ec80e41d90ap0Q, 0xc.251707484d73f136fb5779656b70p-92Q,
	0x1.88ac7d98a669966530bcdep0Q, 0x1.2d4e9d61283ef385de170ab20f96p-88Q,
	0x1.8ace5422aa0db5ba7c55a0p0Q, 0x1.92c9bb3e6ed61f2733304a346d8fp-88Q,
	0x1.8cf3216b5448bef2aa1cd0p0Q, 0x1.61c55d84a9848f8c453b3ca8c946p-88Q,
	0x1.8f1ae991577362b982745cp0Q, 0x7.2ed804efc9b4ae1458ae946099d4p-92Q,
	0x1.9145b0b91ffc588a61b468p0Q, 0x1.f6b70e01c2a90229a4c4309ea719p-88Q,
	0x1.93737b0cdc5e4f4501c3f2p0Q, 0x5.40a22d2fc4af581b63e8326efe9cp-92Q,
	0x1.95a44cbc8520ee9b483694p0Q, 0x1.a0fc6f7c7d61b2b3a22a0eab2cadp-88Q,
	0x1.97d829fde4e4f8b9e920f8p0Q, 0x1.1e8bd7edb9d7144b6f6818084cc7p-88Q,
	0x1.9a0f170ca07b9ba3109b8cp0Q, 0x4.6737beb19e1eada6825d3c557428p-92Q,
	0x1.9c49182a3f0901c7c46b06p0Q, 0x1.1f2be58ddade50c217186c90b457p-88Q,
	0x1.9e86319e323231824ca78ep0Q, 0x6.4c6e010f92c082bbadfaf605cfd4p-92Q,
	0x1.a0c667b5de564b29ada8b8p0Q, 0xc.ab349aa0422a8da7d4512edac548p-92Q,
	0x1.a309bec4a2d3358c171f76p0Q, 0x1.0daad547fa22c26d168ea762d854p-88Q,
	0x1.a5503b23e255c8b424491cp0Q, 0xa.f87bc8050a405381703ef7caff50p-92Q,
	0x1.a799e1330b3586f2dfb2b0p0Q, 0x1.58f1a98796ce8908ae852236ca94p-88Q,
	0x1.a9e6b5579fdbf43eb243bcp0Q, 0x1.ff4c4c58b571cf465caf07b4b9f5p-88Q,
	0x1.ac36bbfd3f379c0db966a2p0Q, 0x1.1265fc73e480712d20f8597a8e7bp-88Q,
	0x1.ae89f995ad3ad5e8734d16p0Q, 0x1.73205a7fbc3ae675ea440b162d6cp-88Q,
	0x1.b0e07298db66590842acdep0Q, 0x1.c6f6ca0e5dcae2aafffa7a0554cbp-88Q,
	0x1.b33a2b84f15faf6bfd0e7ap0Q, 0x1.d947c2575781dbb49b1237c87b6ep-88Q,
	0x1.b59728de559398e3881110p0Q, 0x1.64873c7171fefc410416be0a6525p-88Q,
	0x1.b7f76f2fb5e46eaa7b081ap0Q, 0xb.53c5354c8903c356e4b625aacc28p-92Q,
	0x1.ba5b030a10649840cb3c6ap0Q, 0xf.5b47f297203757e1cc6eadc8bad0p-92Q,
	0x1.bcc1e904bc1d2247ba0f44p0Q, 0x1.b3d08cd0b20287092bd59be4ad98p-88Q,
	0x1.bf2c25bd71e088408d7024p0Q, 0x1.18e3449fa073b356766dfb568ff4p-88Q,
	0x1.c199bdd85529c2220cb12ap0Q, 0x9.1ba6679444964a36661240043970p-96Q,
	0x1.c40ab5fffd07a6d14df820p0Q, 0xf.1828a5366fd387a7bdd54cdf7300p-92Q,
	0x1.c67f12e57d14b4a2137fd2p0Q, 0xf.2b301dd9e6b151a6d1f9d5d5f520p-96Q,
	0x1.c8f6d9406e7b511acbc488p0Q, 0x5.c442ddb55820171f319d9e5076a8p-96Q,
	0x1.cb720dcef90691503cbd1ep0Q, 0x9.49db761d9559ac0cb6dd3ed599e0p-92Q,
	0x1.cdf0b555dc3f9c44f8958ep0Q, 0x1.ac51be515f8c58bdfb6f5740a3a4p-88Q,
	0x1.d072d4a07897b8d0f22f20p0Q, 0x1.a158e18fbbfc625f09f4cca40874p-88Q,
	0x1.d2f87080d89f18ade12398p0Q, 0x9.ea2025b4c56553f5cdee4c924728p-92Q,
	0x1.d5818dcfba48725da05aeap0Q, 0x1.66e0dca9f589f559c0876ff23830p-88Q,
	0x1.d80e316c98397bb84f9d04p0Q, 0x8.805f84bec614de269900ddf98d28p-92Q,
	0x1.da9e603db3285708c01a5ap0Q, 0x1.6d4c97f6246f0ec614ec95c99392p-88Q,
	0x1.dd321f301b4604b695de3cp0Q, 0x6.30a393215299e30d4fb73503c348p-96Q,
	0x1.dfc97337b9b5eb968cac38p0Q, 0x1.ed291b7225a944efd5bb5524b927p-88Q,
	0x1.e264614f5a128a12761fa0p0Q, 0x1.7ada6467e77f73bf65e04c95e29dp-88Q,
	0x1.e502ee78b3ff6273d13014p0Q, 0x1.3991e8f49659e1693be17ae1d2f9p-88Q,
	0x1.e7a51fbc74c834b548b282p0Q, 0x1.23786758a84f4956354634a416cep-88Q,
	0x1.ea4afa2a490d9858f73a18p0Q, 0xf.5db301f86dea20610ceee13eb7b8p-92Q,
	0x1.ecf482d8e67f08db0312fap0Q, 0x1.949cef462010bb4bc4ce72a900dfp-88Q,
	0x1.efa1bee615a27771fd21a8p0Q, 0x1.2dac1f6dd5d229ff68e46f27e3dfp-88Q,
	0x1.f252b376bba974e8696fc2p0Q, 0x1.6390d4c6ad5476b5162f40e1d9a9p-88Q,
	0x1.f50765b6e4540674f84b76p0Q, 0x2.862baff99000dfc4352ba29b8908p-92Q,
	0x1.f7bfdad9cbe138913b4bfep0Q, 0x7.2bd95c5ce7280fa4d2344a3f5618p-92Q,
	0x1.fa7c1819e90d82e90a7e74p0Q, 0xb.263c1dc060c36f7650b4c0f233a8p-92Q,
	0x1.fd3c22b8f71f10975ba4b2p0Q, 0x1.2bcf3a5e12d269d8ad7c1a4a8875p-88Q
};

/*
 * Kernel for expl(x).  x must be finite and not tiny or huge.
 * "tiny" is anything that would make us underflow (|A6*x^6| < ~LDBL_MIN).
 * "huge" is anything that would make fn*L1 inexact (|x| > ~2**17*ln2).
 */
static inline void
__k_expq (float128_t  x,
          float128_t *hip,
          float128_t *lop,
          int         *kp)
{
	float128_t q, r, r1, t;
	float64_t dr, fn, r2;
	int n, n2;

	/* Reduce x to (k*ln2 + endpoint[n2] + r1 + r2). */
	fn = rnint((float64_t)x * INV_L);
	n = irint(fn);
	n2 = (unsigned)n % INTERVALS;
	/* Depend on the sign bit being propagated: */
	*kp = n >> LOG2_INTERVALS;
	r1 = x - fn * L1;
	r2 = fn * -L2;
	r = r1 + r2;

	/* Evaluate expl(endpoint[n2] + r1 + r2) = tbl[n2] * expl(r1 + r2). */
	dr = r;
	q = r2 + r * r * (A2 + r * (A3 + r * (A4 + r * (A5 + r * (A6 +
	    dr * (A7 + dr * (A8 + dr * (A9 + dr * A10))))))));
	t = tbl[n2].lo + tbl[n2].hi;
	*hip = tbl[n2].hi;
	*lop = tbl[n2].lo + t * (q + r1);
}


/*
 * --------------------------------------------------------------
 * Start of s_expl.c
 */

/* XXX Prevent compilers from erroneously constant folding these: */
static const volatile float128_t
    huge = 0x1p10000Q,
    tiny = 0x1p-10000Q;

static const float128_t
    twom10000 = 0x1p-10000Q;

static const float128_t
    /* log(2**16384 - 0.5) rounded towards zero: */
    /* log(2**16384 - 0.5 + 1) rounded towards zero for expm1l() is the same: */
    o_threshold =  11356.523406294143949491931077970763428Q,
    /* log(2**(-16381-64-1)) rounded towards zero: */
    u_threshold = -11433.462743336297878837243843452621503Q;

float128_t
expq (float128_t x)
{
	union IEEEl2bits u;
	float128_t hi, lo, t, twopk;
	int k;
	uint16_t hx, ix;

	// DOPRINT_START(&x);

	/* Filter out exceptional cases. */
	u.e = x;
	hx = u.xbits.expsign;
	ix = hx & 0x7fff;
	if (ix >= BIAS + 13) {		/* |x| >= 8192 or x is NaN */
		if (ix == BIAS + LDBL_MAX_EXP) {
			if (hx & 0x8000)  /* x is -Inf or -NaN */
				return (-1 / x);
			return (x + x);	/* x is +Inf or +NaN */
		}
		if (x > o_threshold)
			return (huge * huge);
		if (x < u_threshold)
			return (tiny * tiny);
	} else if (ix < BIAS - 114) {	/* |x| < 0x1p-114 */
		return (1);		/* 1 with inexact iff x != 0 */
	}

	// ENTERI();

	twopk = 1;
	__k_expq(x, &hi, &lo, &k);
	t = hi + lo;

	/* Scale by 2**k. */
	/*
	 * XXX sparc64 multiplication was so slow that scalbnl() is faster,
	 * but performance on aarch64 and riscv hasn't yet been quantified.
	 */
	if (k >= LDBL_MIN_EXP) {
		if (k == LDBL_MAX_EXP)
			return (t * 2 * 0x1p16383Q);
		SET_LDBL_EXPSIGN(twopk, BIAS + k);
		return (t * twopk);
	} else {
		SET_LDBL_EXPSIGN(twopk, BIAS + k + 10000);
		return (t * twopk * twom10000);
	}
}


int
main ()
{
    printf("%d %d %d\n\n", LDBL_MIN_EXP, LDBL_MAX_EXP, BIAS);

    float128_t vals[64] = {
		1, 2, -1, 0.5, 0.511,
        // Sanity
        -0x1.02239f3c6a8f13dep+3Q,
         0x1.161868e18bc67782p+2Q,
        -0x1.0c34b3e01e6e682cp+3Q,
        -0x1.a206f0a19dcc3948p+2Q,
         0x1.288bbb0d6a1e5bdap+3Q,
         0x1.52efd0cd80496a5ap-1Q,
        -0x1.a05cc754481d0bd0p-2Q,
         0x1.1f9ef934745cad60p-1Q,
         0x1.8c5db097f744257ep-1Q,
        -0x1.5b86ea8118a0e2bcp-1Q,
        // Boundary
         0x1.62e42fefa39ef35793c7673007e5p+13Q,
         0x1.62e42fefa39ef35793c7673007e6p+13Q,
        -0x1.654bb3b2c73ebb059fabb506ff33p+13Q,
        -0x1.654bb3b2c73ebb059fabb506ff34p+13Q,
        -11355.137111933024058873096613727848253Q,
	};

    char buf[256];
    for (int i=0; i < sizeof(vals) / sizeof(vals[0]); i++) {
        float128_t input = vals[i];
        if (input == 0) break;
        uint128_t input_bits = *(uint128_t*)(&input);
        printf("IN:  "HEX128,
               (uint64_t)(input_bits >> 64),
               (uint64_t)input_bits);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qf", input);
        printf("  %s", buf);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qa", input);
        printf("  %s\n", buf);

        float128_t output = expq(input);
        uint128_t output_bits = *(uint128_t*)(&output);
        printf("OUT: "HEX128,
               (uint64_t)(output_bits >> 64),
               (uint64_t)output_bits);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qf", output);
        printf("  %s", buf);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qa", output);
        printf("  %s\n\n", buf);
    }
}
