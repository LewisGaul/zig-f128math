/// Can be run with:
///   zig0.9 test \
///     --pkg-begin f128math src/lib.zig --pkg-end \
///     tests/log2.zig
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

const TestcaseLog2_32 = test_util.Testcase(math.log2, "log2", f32);
const TestcaseLog2_64 = test_util.Testcase(math.log2, "log2", f64);
const TestcaseLog2_128 = test_util.Testcase(math.log2, "log2", f128);

fn tc32(input: f32, exp_output: f32) TestcaseLog2_32 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc64(input: f64, exp_output: f64) TestcaseLog2_64 {
    return .{ .input = input, .exp_output = exp_output };
}

fn tc128(input: f128, exp_output: f128) TestcaseLog2_128 {
    return .{ .input = input, .exp_output = exp_output };
}

const testcases32 = [_]TestcaseLog2_32{
    // zig fmt: off

    // Special cases
    tc32( 0,       -inf_f32 ),
    tc32(-0,       -inf_f32 ),
    tc32( 1,        0       ),
    tc32( 2,        1       ),
    tc32(-1,        nan_f32 ),
    tc32( inf_f32,  inf_f32 ),
    tc32(-inf_f32,  nan_f32 ),
    tc32( nan_f32,  nan_f32 ),
    tc32(-nan_f32,  nan_f32 ),
    // tc32( @bitCast(f32, @as(u32, 0x7ff01234)),  nan_f32 ),  // TODO
    tc32( @bitCast(f32, @as(u32, 0xfff01234)),  nan_f32 ),

    // Sanity cases
    tc32(-0x1.0223a0p+3,   nan_f32       ),
    tc32( 0x1.161868p+2,   0x1.0f49acp+1 ),
    tc32(-0x1.0c34b4p+3,   nan_f32       ),
    tc32(-0x1.a206f0p+2,   nan_f32       ),
    tc32( 0x1.288bbcp+3,   0x1.9b2676p+1 ),
    // tc32( 0x1.52efd0p-1,  -0x1.30b492p-1 ),  // TODO: one digit off
    tc32(-0x1.a05cc8p-2,   nan_f32       ),
    tc32( 0x1.1f9efap-1,  -0x1.a9f89ap-1 ),
    tc32( 0x1.8c5db0p-1,  -0x1.7a2c96p-2 ),
    tc32(-0x1.5b86eap-1,   nan_f32       ),

    // zig fmt: on
};

const testcases64 = [_]TestcaseLog2_64{
    // zig fmt: off

    // Special cases
    tc64( 0,       -inf_f64 ),
    tc64(-0,       -inf_f64 ),
    tc64( 1,        0       ),
    tc64( 2,        1       ),
    tc64(-1,        nan_f64 ),
    tc64( inf_f64,  inf_f64 ),
    tc64(-inf_f64,  nan_f64 ),
    tc64( nan_f64,  nan_f64 ),
    tc64(-nan_f64,  nan_f64 ),
    // tc64( @bitCast(f64, @as(u64, 0x7ff0123400000000)),  nan_f64 ),  // TODO
    tc64( @bitCast(f64, @as(u64, 0xfff0123400000000)),  nan_f64 ),

    // Sanity cases
    tc64(-0x1.02239f3c6a8f1p+3,  nan_f64              ),
    tc64( 0x1.161868e18bc67p+2,  0x1.0f49ac3838580p+1 ),
    tc64(-0x1.0c34b3e01e6e7p+3,  nan_f64              ),
    tc64(-0x1.a206f0a19dcc4p+2,  nan_f64              ),
    tc64( 0x1.288bbb0d6a1e6p+3,  0x1.9b26760c2a57ep+1 ),
    tc64( 0x1.52efd0cd80497p-1, -0x1.30b490ef684c7p-1 ),
    tc64(-0x1.a05cc754481d1p-2,  nan_f64              ),
    tc64( 0x1.1f9ef934745cbp-1, -0x1.a9f89b5f5acb8p-1 ),
    tc64( 0x1.8c5db097f7442p-1, -0x1.7a2c947173f06p-2 ),
    tc64(-0x1.5b86ea8118a0ep-1,  nan_f64              ),

    // zig fmt: on
};

const testcases128 = [_]TestcaseLog2_128{
    // zig fmt: off

    // Special cases
    tc128( 0,        -inf_f128 ),
    tc128(-0,        -inf_f128 ),
    tc128( 1,         0        ),
    tc128( 2,         1        ),
    tc128(-1,         nan_f128 ),
    tc128( inf_f128,  inf_f128 ),
    tc128(-inf_f128,  nan_f128 ),
    tc128( nan_f128,  nan_f128 ),
    tc128(-nan_f128,  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0x7fff1234000000000000000000000000)),  nan_f128 ),
    tc128( @bitCast(f128, @as(u128, 0xffff1234000000000000000000000000)),  nan_f128 ),

    // Sanity cases
    tc128(-0x1.02239f3c6a8f13dep+3,  nan_f128                ),
    tc128( 0x1.161868e18bc67782p+2,  0x1.0f49ac383858069cp+1 ),
    tc128(-0x1.0c34b3e01e6e682cp+3,  nan_f128                ),
    tc128(-0x1.a206f0a19dcc3948p+2,  nan_f128                ),
    tc128( 0x1.288bbb0d6a1e5bdap+3,  0x1.9b26760c2a57dff0p+1 ),
    tc128( 0x1.52efd0cd80496a5ap-1, -0x1.30b490ef684c81a0p-1 ),
    tc128(-0x1.a05cc754481d0bd0p-2,  nan_f128                ),
    tc128( 0x1.1f9ef934745cad60p-1, -0x1.a9f89b5f5acb87aap-1 ),
    tc128( 0x1.8c5db097f744257ep-1, -0x1.7a2c947173f0485cp-2 ),
    tc128(-0x1.5b86ea8118a0e2bcp-1,  nan_f128                ),

    // zig fmt: on
};

test "log2_32()" {
    try test_util.runTests(testcases32);
}

test "log2_64()" {
    try test_util.runTests(testcases64);
}

// test "log2_128()" {
//     try test_util.runTests(testcases128);
// }
