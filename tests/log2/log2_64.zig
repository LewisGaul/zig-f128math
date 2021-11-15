const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const f128math = @import("f128math");
const math = f128math;
const inf_f64 = math.inf_f64;
const nan_f64 = math.qnan_f64;

const TestValue = struct {
    input: f64,
    exp_output: f64,
};

fn Test(input: f64, exp_output: f64) TestValue {
    return .{ .input = input, .exp_output = exp_output };
}

const test_cases = [_]TestValue{
    // zig fmt: off

    // Special cases
    Test(       0, -inf_f64 ),
    Test(      -0, -inf_f64 ),
    Test(       1,        0 ),
    Test(       2,        1 ),
    Test(      -1,  nan_f64 ),
    Test( inf_f64,  inf_f64 ),
    Test(-inf_f64,  nan_f64 ),
    Test( nan_f64,  nan_f64 ),
    Test(-nan_f64,  nan_f64 ),
    // Test( @bitCast(f64, @as(u64, 0x7ff0123400000000)),  nan_f64 ),  // TODO
    Test( @bitCast(f64, @as(u64, 0xfff0123400000000)),  nan_f64 ),

    // Sanity cases
    Test(-0x1.02239f3c6a8f1p+3,               nan_f64 ),
    Test( 0x1.161868e18bc67p+2,  0x1.0f49ac3838580p+1 ),
    Test(-0x1.0c34b3e01e6e7p+3,               nan_f64 ),
    Test(-0x1.a206f0a19dcc4p+2,               nan_f64 ),
    Test( 0x1.288bbb0d6a1e6p+3,  0x1.9b26760c2a57ep+1 ),
    Test( 0x1.52efd0cd80497p-1, -0x1.30b490ef684c7p-1 ),
    Test(-0x1.a05cc754481d1p-2,               nan_f64 ),
    Test( 0x1.1f9ef934745cbp-1, -0x1.a9f89b5f5acb8p-1 ),
    Test( 0x1.8c5db097f7442p-1, -0x1.7a2c947173f06p-2 ),
    Test(-0x1.5b86ea8118a0ep-1,               nan_f64 ),

    // Boundary cases
    // Test( 0x1.fffffffffffffp+9,    0x1.ffffffffffd3ap+1023 ), // The last value before the exp gets infinite
    // Test( 0x1.fff3333333333p+9,    0x1.ddb680117aa8ep+1023 ),
    // Test( 0x1p+10,                 inf_f64                 ), // The first value that gives infinite exp
    // Test( 0x1.0006666666666p+10,   inf_f64                 ),
    // Test(-0x1.0cbffffffffffp+10,   0x1p-1074               ), // The last value before the exp flushes to zero
    // Test(-0x1.0c8p+10,             0x1p-1074               ),
    // Test(-0x1.0cap+10,             0x1p-1074               ),
    // Test(-0x1.0ccp+10,             0x0p+0                  ), // The first value at which the exp flushes to zero
    // Test(-0x1p+11,                 0x0p+0                  ),
    // Test(-0x1.ffp+9,               0x1p-1022               ), // The last value before the exp flushes to subnormal
    // Test(-0x1.fef3333333333p+9,    0x1.125fbee2506b0p-1022 ),
    // Test(-0x1.ff00000000001p+9,    0x1.ffffffffffd3ap-1023 ), // The first value for which exp flushes to subnormal
    // Test(-0x1.ff0cccccccccdp+9,    0x1.ddb680117aa8ep-1023 ),
    // Test(-0x1.ff4p+9,              0x1.6a09e667f3bccp-1023 ),
    // Test(-0x1.ff8p+9,              0x1p-1023               ),
    // Test(-0x1.ffcp+9,              0x1.6a09e667f3bccp-1024 ),
    // Test(-0x1p+10,                 0x1p-1024               ),

    // zig fmt: on
};

test "log2_64()" {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u64, tc.input);
        const exp_output_bits = @bitCast(u64, tc.exp_output);
        const output: f64 = f128math.log2(tc.input);
        const output_bits = @bitCast(u64, output);
        const sign_pad = if ((input_bits & 0x8000000000000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x8000000000000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<24}{[3]s} {[2]s}{[0]e:<24}{[3]s} 0x{[1]x:0>16}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<24}  {[0]e:<24} 0x{[1]x:0>16}\n",
            .{ output, output_bits },
        );
        if (output_bits != exp_output_bits) {
            print(
                "exp:   {[0]x:<24}  {[0]e:<24} 0x{[1]x:0>16}\n",
                .{ tc.exp_output, exp_output_bits },
            );
            print("FAILED\n", .{});
            failure = true;
        }
        print("\n", .{});
    }
    if (failure) return error.Failure;
}
