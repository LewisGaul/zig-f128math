/// Can be run with:
///   zig0.9 test \
///     --pkg-begin f128math src/lib.zig --pkg-end \
///     tests/exp2.zig
const std = @import("std");
const testing = std.testing;

const f128math = @import("f128math");
const math = f128math;
const inf_f32 = math.inf_f32;
const nan_f32 = math.qnan_f32;
const inf_f64 = math.inf_f64;
const nan_f64 = math.qnan_f64;
const inf_f128 = math.inf_f128;
const nan_f128 = math.qnan_f128;

const test_util = @import("util.zig");

const TestcaseExp2_32 = test_util.Testcase(math.exp2, "exp2", .Binary32);
const TestcaseExp2_64 = test_util.Testcase(math.exp2, "exp2", .Binary64);
const TestcaseExp2_128 = test_util.Testcase(math.exp2, "exp2", .Binary128);

fn tc32(input: f32, exp_output: f32) TestcaseExp2_32 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc64(input: f64, exp_output: f64) TestcaseExp2_64 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc128(input: f128, exp_output: f128) TestcaseExp2_128 {
    return .{ .input = input, .exp_output = exp_output };
}

const testcases32 = [_]TestcaseExp2_32{
    // zig fmt: off

    // Special cases
    tc32( 0,        1       ),
    tc32(-0,        1       ),
    tc32( 1,        2       ),
    tc32(-1,        0.5     ),
    tc32( inf_f32,  inf_f32 ),
    tc32(-inf_f32,  0       ),
    tc32( nan_f32,  nan_f32 ),
    tc32(-nan_f32,  nan_f32 ),
    tc32( @bitCast(f32, @as(u32, 0x7ff01234)),  nan_f32 ),
    tc32( @bitCast(f32, @as(u32, 0xfff01234)),  nan_f32 ),

    // Sanity cases
    tc32(-0x1.0223a0p+3,   0x1.e8d134p-9   ),
    tc32( 0x1.161868p+2,   0x1.453672p+4   ),
    tc32(-0x1.0c34b4p+3,   0x1.890ca0p-9   ),
    tc32(-0x1.a206f0p+2,   0x1.622d4ep-7   ),
    tc32( 0x1.288bbcp+3,   0x1.340ecep+9   ),
    tc32( 0x1.52efd0p-1,   0x1.950eeep+0   ),
    tc32(-0x1.a05cc8p-2,   0x1.824056p-1   ),
    tc32( 0x1.1f9efap-1,   0x1.79dfa2p+0   ),
    tc32( 0x1.8c5db0p-1,   0x1.b5ceacp+0   ),
    tc32(-0x1.5b86eap-1,   0x1.3fd8bap-1   ),

    // Boundary cases
    tc32( 0x1.fffffep+6,   0x1.ffff4ep+127 ), // The last value before the exp gets infinite
    tc32( 0x1.ff999ap+6,   0x1.ddb6a2p+127 ),
    tc32( 0x1p+7,          inf_f32         ), // The first value that gives infinite exp
    tc32( 0x1.003334p+7,   inf_f32         ),
    tc32(-0x1.2bccccp+7,   0x1p-149        ), // The last value before the exp flushes to zero
    tc32(-0x1.2ap+7,       0x1p-149        ),
    tc32(-0x1.2cp+7,       0               ), // The first value at which the exp flushes to zero
    tc32(-0x1.2c3334p+7,   0               ),
    tc32(-0x1.f8p+6,       0x1p-126        ), // The last value before the exp flushes to subnormal
    tc32(-0x1.f80002p+6,   0x1.ffff5p-127  ), // The first value for which exp flushes to subnormal
    tc32(-0x1.fcp+6,       0x1p-127        ),

    // zig fmt: on
};

const testcases64 = [_]TestcaseExp2_64{
    // zig fmt: off

    // Special cases
    tc64( 0,        1       ),
    tc64(-0,        1       ),
    tc64( 1,        2       ),
    tc64(-1,        0.5     ),
    tc64( inf_f64,  inf_f64 ),
    tc64(-inf_f64,  0       ),
    tc64( nan_f64,  nan_f64 ),
    tc64(-nan_f64,  nan_f64 ),
    tc64( @bitCast(f64, @as(u64, 0x7ff0123400000000)),  nan_f64 ),
    tc64( @bitCast(f64, @as(u64, 0xfff0123400000000)),  nan_f64 ),

    // Sanity cases
    tc64(-0x1.02239f3c6a8f1p+3,    0x1.e8d13c396f452p-9    ),
    tc64( 0x1.161868e18bc67p+2,    0x1.4536746bb6f12p+4    ),
    tc64(-0x1.0c34b3e01e6e7p+3,    0x1.890ca0c00b9a2p-9    ),
    tc64(-0x1.a206f0a19dcc4p+2,    0x1.622d4b0ebc6c1p-7    ),
    tc64( 0x1.288bbb0d6a1e6p+3,    0x1.340ec7f3e607ep+9    ),
    tc64( 0x1.52efd0cd80497p-1,    0x1.950eef4bc5451p+0    ),
    tc64(-0x1.a05cc754481d1p-2,    0x1.824056efc687cp-1    ),
    tc64( 0x1.1f9ef934745cbp-1,    0x1.79dfa14ab121ep+0    ),
    tc64( 0x1.8c5db097f7442p-1,    0x1.b5cead2247372p+0    ),
    tc64(-0x1.5b86ea8118a0ep-1,    0x1.3fd8ba33216b9p-1    ),

    // Boundary cases
    tc64( 0x1.fffffffffffffp+9,    0x1.ffffffffffd3ap+1023 ), // The last value before the exp gets infinite
    tc64( 0x1.fff3333333333p+9,    0x1.ddb680117aa8ep+1023 ),
    tc64( 0x1p+10,                 inf_f64                 ), // The first value that gives infinite exp
    tc64( 0x1.0006666666666p+10,   inf_f64                 ),
    tc64(-0x1.0cbffffffffffp+10,   0x1p-1074               ), // The last value before the exp flushes to zero
    tc64(-0x1.0c8p+10,             0x1p-1074               ),
    tc64(-0x1.0cap+10,             0x1p-1074               ),
    tc64(-0x1.0ccp+10,             0                       ), // The first value at which the exp flushes to zero
    tc64(-0x1p+11,                 0                       ),
    tc64(-0x1.ffp+9,               0x1p-1022               ), // The last value before the exp flushes to subnormal
    tc64(-0x1.fef3333333333p+9,    0x1.125fbee2506b0p-1022 ),
    tc64(-0x1.ff00000000001p+9,    0x1.ffffffffffd3ap-1023 ), // The first value for which exp flushes to subnormal
    tc64(-0x1.ff0cccccccccdp+9,    0x1.ddb680117aa8ep-1023 ),
    tc64(-0x1.ff4p+9,              0x1.6a09e667f3bccp-1023 ),
    tc64(-0x1.ff8p+9,              0x1p-1023               ),
    tc64(-0x1.ffcp+9,              0x1.6a09e667f3bccp-1024 ),
    tc64(-0x1p+10,                 0x1p-1024               ),

    // zig fmt: on
};

const testcases128 = [_]TestcaseExp2_128{
    // zig fmt: off

    // Special cases
    tc128( 0,         1        ),
    tc128(-0,         1        ),
    tc128( 1,         2        ),
    tc128(-1,         0.5      ),
    tc128( inf_f128,  inf_f128 ),
    tc128(-inf_f128,  0        ),
    tc128( nan_f128,  nan_f128 ),
    tc128(-nan_f128,  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0x7fff1234000000000000000000000000)),  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0xffff1234000000000000000000000000)),  nan_f128 ),

    // Sanity cases
    tc128(-0x1.02239f3c6a8f13dep+3,  0x1.e8d13c396f44f500bfc7cefe1304p-9 ),
    tc128( 0x1.161868e18bc67782p+2,  0x1.4536746bb6f139f3c05f40f3758dp+4 ),
    tc128(-0x1.0c34b3e01e6e682cp+3,  0x1.890ca0c00b9a679b66a1cc43e168p-9 ),
    tc128(-0x1.a206f0a19dcc3948p+2,  0x1.622d4b0ebc6c2e5980cda14724e4p-7 ),
    tc128( 0x1.288bbb0d6a1e5bdap+3,  0x1.340ec7f3e607c5bd584d33ade9aep+9 ),
    tc128( 0x1.52efd0cd80496a5ap-1,  0x1.950eef4bc5450eeabc992d9ba86ap+0 ),
    tc128(-0x1.a05cc754481d0bd0p-2,  0x1.824056efc687c4f8b3c7e1f4f9fbp-1 ),
    tc128( 0x1.1f9ef934745cad60p-1,  0x1.79dfa14ab121da4f38057c8f9f2ep+0 ),
    tc128( 0x1.8c5db097f744257ep-1,  0x1.b5cead22473723958363b617f84ep+0 ),
    tc128(-0x1.5b86ea8118a0e2bcp-1,  0x1.3fd8ba33216b93ceab3a5697c480p-1 ),

    // Boundary cases
    tc128( 0x1p+14 - 0x1p-99,        0x1.ffffffffffffffffffffffffd3a3p+16383 ), // The last value before the exp gets infinite
    tc128( 0x1.ffff333333333334p+13, 0x1.ddb680117ab141f6da98f76d6b72p+16383 ),
    tc128( 0x1p+14,                  inf_f128                                ), // The first value that gives infinite exp
    tc128( 0x1.0000666666666666p+14, inf_f128                                ),
    tc128(-0x1.01bcp+14 + 0x1p-98,   0x1p-16494                              ), // The last value before the exp flushes to zero
    tc128(-0x1.00f799999999999ap+14, 0x1.125fbee25066p-16446                 ),
    tc128(-0x1.01bcp+14,             0                                       ), // The first value at which the exp flushes to zero
    tc128(-0x1.fffp+13,              0x1p-16382                              ), // The last value before the exp flushes to subnormal
    tc128(-0x1.fffp+13 - 0x1p-99,    0x0.ffffffffffffffffffffffffe9d2p-16382 ), // The first value for which exp flushes to subnormal
    tc128(-0x1.fff4p+13,             0x1.6a09e667f3bcc908b2fb1366ea94p-16383 ),
    tc128(-0x1.fff8p+13,             0x1p-16383                              ),
    tc128(-0x1.fffcp+13,             0x1.6a09e667f3bcc908b2fb1366ea94p-16384 ),
    tc128(-0x1p+14,                  0x1p-16384                              ),
    tc128( 0x1p-16384,               1                                       ), // Very close to zero

    // zig fmt: on
};

test "exp2_32()" {
    try test_util.runTests(testcases32);
}

test "exp2_64()" {
    try test_util.runTests(testcases64);
}

test "exp2_128()" {
    try test_util.runTests(testcases128);
}
