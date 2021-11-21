/// Can be run with:
///   zig0.9 test \
///     --pkg-begin f128math src/lib.zig --pkg-end \
///     tests/exp.zig
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

const TestcaseExp32 = test_util.Testcase(math.exp, "exp", .Binary32);
const TestcaseExp64 = test_util.Testcase(math.exp, "exp", .Binary64);
const TestcaseExp128 = test_util.Testcase(math.exp, "exp", .Binary128);

fn tc32(input: f32, exp_output: f32) TestcaseExp32 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc64(input: f64, exp_output: f64) TestcaseExp64 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc128(input: f128, exp_output: f128) TestcaseExp128 {
    return .{ .input = input, .exp_output = exp_output };
}

const testcases32 = [_]TestcaseExp32{
    // zig fmt: off

    // Special cases
    tc32( 0,        1       ),
    tc32(-0,        1       ),
    tc32( inf_f32,  inf_f32 ),
    tc32(-inf_f32,  0       ),
    tc32( nan_f32,  nan_f32 ),
    tc32(-nan_f32,  nan_f32 ),
    tc32( @bitCast(f32, @as(u32, 0x7ff01234)),  nan_f32 ),
    tc32( @bitCast(f32, @as(u32, 0xfff01234)),  nan_f32 ),

    // Sanity cases
    tc32(-0x1.0223a0p+3,  0x1.490320p-12 ),
    tc32( 0x1.161868p+2,  0x1.34712ap+6  ),
    tc32(-0x1.0c34b4p+3,  0x1.e06b1ap-13 ),
    tc32(-0x1.a206f0p+2,  0x1.7dd484p-10 ),
    tc32( 0x1.288bbcp+3,  0x1.4abc80p+13 ),
    tc32( 0x1.52efd0p-1,  0x1.f04a9cp+0  ),
    tc32(-0x1.a05cc8p-2,  0x1.54f1e0p-1  ),
    tc32( 0x1.1f9efap-1,  0x1.c0f628p+0  ),
    tc32( 0x1.8c5db0p-1,  0x1.1599b2p+1  ),
    tc32(-0x1.5b86eap-1,  0x1.03b572p-1  ),
    tc32(-0x1.57f25cp+2,  0x1.2fbea2p-8  ),
    tc32( 0x1.c7d310p+3,  0x1.76eefp+20  ),
    tc32( 0x1.19be70p+4,  0x1.52d3dep+25 ),
    tc32(-0x1.ab6d70p+3,  0x1.a88adep-20 ),
    tc32(-0x1.5ac18ep+2,  0x1.22b328p-8  ),
    tc32(-0x1.925982p-1,  0x1.d2acc0p-2  ),
    tc32( 0x1.7221cep+3,  0x1.9c2ceap+16 ),
    tc32( 0x1.11a0d4p+4,  0x1.980ee6p+24 ),
    tc32(-0x1.ae41a2p+1,  0x1.1c28d0p-5  ),
    tc32(-0x1.329154p+4,  0x1.47ef94p-28 ),

    // Boundary cases
    tc32( 0x1.62e42ep+6,   0x1.ffff08p+127 ), // The last value before the exp gets infinite
    tc32( 0x1.62e430p+6,   inf_f32         ), // The first value that gives infinite exp
    tc32( 0x1.fffffep+127, inf_f32         ), // Max input value
    tc32( 0x1p-149,        1               ), // Tiny input values
    tc32(-0x1p-149,        1               ),
    tc32( 0x1p-126,        1               ),
    tc32(-0x1p-126,        1               ),
    tc32(-0x1.9fe368p+6,   0x1p-149        ), // The last value before the exp flushes to zero
    tc32(-0x1.9fe36ap+6,   0               ), // The first value at which the exp flushes to zero
    tc32(-0x1.5d589ep+6,   0x1.00004cp-126 ), // The last value before the exp flushes to subnormal
    tc32(-0x1.5d58a0p+6,   0x1.ffff98p-127 ), // The first value for which exp flushes to subnormal

    // zig fmt: on
};

const testcases64 = [_]TestcaseExp64{
    // zig fmt: off

    // Special cases
    tc64( 0,          1       ),
    tc64(-0,          1       ),
    tc64( 0x1p-1074,  1       ), // Smallest denorm positive
    tc64(-0x1p-1074,  1       ), // Smallest denorm negative
    tc64( inf_f64,    inf_f64 ),
    tc64(-inf_f64,    0       ),
    tc64( nan_f64,    nan_f64 ),

    // Sanity cases
    tc64(-0x1.02239f3c6a8f1p+3,  0x1.490327ea61235p-12 ),
    tc64( 0x1.161868e18bc67p+2,  0x1.34712ed238c04p+6  ),
    tc64(-0x1.0c34b3e01e6e7p+3,  0x1.e06b1b6c18e64p-13 ),
    tc64(-0x1.a206f0a19dcc4p+2,  0x1.7dd47f810e68cp-10 ),
    tc64( 0x1.288bbb0d6a1e6p+3,  0x1.4abc77496e07ep+13 ),
    tc64( 0x1.52efd0cd80497p-1,  0x1.f04a9c1080500p+0  ),
    tc64(-0x1.a05cc754481d1p-2,  0x1.54f1e0fd3ea0dp-1  ),
    tc64( 0x1.1f9ef934745cbp-1,  0x1.c0f6266a6a547p+0  ),
    tc64( 0x1.8c5db097f7442p-1,  0x1.1599b1d4a25fbp+1  ),
    tc64(-0x1.5b86ea8118a0ep-1,  0x1.03b5728a00229p-1  ),
    tc64(-0x1.57f25b2b5006dp+2,  0x1.2fbea6a01cab9p-8  ),
    tc64( 0x1.c7d30fb825911p+3,  0x1.76eeed45a0634p+20 ),
    tc64( 0x1.19be709de7505p+4,  0x1.52d3eb7be6844p+25 ),
    tc64(-0x1.ab6d6fba96889p+3,  0x1.a88ae12f985d6p-20 ),
    tc64(-0x1.5ac18e27084ddp+2,  0x1.22b327da9cca6p-8  ),
    tc64(-0x1.925981b093c41p-1,  0x1.d2acc046b55f7p-2  ),
    tc64( 0x1.7221cd18455f5p+3,  0x1.9c2cde8699cfbp+16 ),
    tc64( 0x1.11a0d4a51b239p+4,  0x1.980ef612ff182p+24 ),
    tc64(-0x1.ae41a1079de4dp+1,  0x1.1c28d16bb3222p-5  ),
    tc64(-0x1.329153103b871p+4,  0x1.47efa6ddd0d22p-28 ),

    // Boundary cases
    tc64( 0x1.62e42fefa39efp+9,    0x1.fffffffffff2ap+1023 ), // The last value before the exp gets infinite
    tc64( 0x1.62e42fefa39f0p+9,    inf_f64                 ), // The first value that gives infinite exp
    tc64( 0x1.fffffffffffffp+127,  inf_f64                 ), // Max input value
    tc64( 0x1p-1074,               1                       ), // Tiny input values
    tc64(-0x1p-1074,               1                       ),
    tc64( 0x1p-1022,               1                       ),
    tc64(-0x1p-1022,               1                       ),
    tc64(-0x1.74910d52d3051p+9,    0x1p-1074               ), // The last value before the exp flushes to zero
    tc64(-0x1.74910d52d3052p+9,    0                       ), // The first value at which the exp flushes to zero
    tc64(-0x1.6232bdd7abcd2p+9,    0x1.000000000007cp-1022 ), // The last value before the exp flushes to subnormal
    tc64(-0x1.6232bdd7abcd3p+9,    0x1.ffffffffffcf8p-1023 ), // The first value for which exp flushes to subnormal

    // zig fmt: on
};

const testcases128 = [_]TestcaseExp128{
    // zig fmt: off

    // Special cases
    tc128( 0,         1        ),
    tc128(-0,         1        ),
    tc128( inf_f128,  inf_f128 ),
    tc128(-inf_f128,  0        ),
    tc128( nan_f128,  nan_f128 ),
    tc128(-nan_f128,  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0x7fff1234000000000000000000000000)),  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0xffff1234000000000000000000000000)),  nan_f128 ),

    // Sanity cases
    tc128(-0x1.02239f3c6a8f13dep+3,  0x1.490327ea61232c65cff53beed777p-12 ),
    tc128( 0x1.161868e18bc67782p+2,  0x1.34712ed238c064a14a59ddb90119p+6  ),
    tc128(-0x1.0c34b3e01e6e682cp+3,  0x1.e06b1b6c18e6b9852676f1295765p-13 ),
    tc128(-0x1.a206f0a19dcc3948p+2,  0x1.7dd47f810e68efcaa7504b9387d0p-10 ),
    tc128( 0x1.288bbb0d6a1e5bdap+3,  0x1.4abc77496e07b24ad548e9379bcap+13 ),
    tc128( 0x1.52efd0cd80496a5ap-1,  0x1.f04a9c1080500277b844a5191ca4p+0  ),
    tc128(-0x1.a05cc754481d0bd0p-2,  0x1.54f1e0fd3ea0d31771802892d4e9p-1  ),
    tc128( 0x1.1f9ef934745cad60p-1,  0x1.c0f6266a6a5473f6d16e0140d987p+0  ),
    tc128( 0x1.8c5db097f744257ep-1,  0x1.1599b1d4a25fb7c587a30b9ea597p+1  ),
    tc128(-0x1.5b86ea8118a0e2bcp-1,  0x1.03b5728a0022870d16a9c4217353p-1  ),

    // Boundary cases
    tc128( 0x1.62e42fefa39ef35793c7673007e5p+13,   0x1.ffffffffffffffffffffffffc4a8p+16383 ), // The last value before the exp gets infinite
    tc128( 0x1.62e42fefa39ef35793c7673007e6p+13,   inf_f128                                ), // The first value that gives infinite exp
    tc128(-0x1.654bb3b2c73ebb059fabb506ff33p+13,   0x1p-16494                              ), // The last value before the exp flushes to zero
    tc128(-0x1.654bb3b2c73ebb059fabb506ff34p+13,   0                                       ), // The first value at which the exp flushes to zero
    tc128(-0x1.62d918ce2421d65ff90ac8f4ce65p+13,   0x1.00000000000000000000000015c6p-16382 ), // The last value before the exp flushes to subnormal
    tc128(-0x1.62d918ce2421d65ff90ac8f4ce66p+13,   0x1.ffffffffffffffffffffffffeb8cp-16383 ), // The first value for which exp flushes to subnormal

    // zig fmt: on
};

test "exp32()" {
    try test_util.runTests(testcases32);
}

test "exp64()" {
    try test_util.runTests(testcases64);
}

test "exp128()" {
    try test_util.runTests(testcases128);
}
