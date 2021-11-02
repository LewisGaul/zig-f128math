const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const math = std.math;
const inf_f128 = math.inf_f128;
const nan_f128 = math.nan_f128;

const f128math = @import("f128math");


const TestValue = struct {
    input: f128,
    exp_output: f128,
};

fn Test(input: f128, exp_output: f128) TestValue {
    return .{ .input = input, .exp_output = exp_output };
}

const test_cases = [_]TestValue{
    // zig fmt: off

    // Special cases
    Test( 0x0p+0,    0x1p+0   ),
    Test(-0x0p+0,    0x1p+0   ),
    Test( 0x1p+0,    0x1p+1   ),
    Test(-0x1p+0,    0x1p-1   ),
    Test( inf_f128,  inf_f128 ),
    Test(-inf_f128,  0x0p+0   ),
    Test( nan_f128,  nan_f128 ),
    Test(-nan_f128,  nan_f128 ),
    Test( @bitCast(f128, @as(u128, 0x7fff1234000000000000000000000000)),  nan_f128 ),
    Test( @bitCast(f128, @as(u128, 0xffff1234000000000000000000000000)),  nan_f128 ),

    // Sanity cases

    // Some boundary cases specific to exp2
    // Test( 0x1p+14 - 0x1p-99,        0x1.ffffffffffffffffffffffffd3a3p+16383 ), // The last value before the exp gets infinite
    // Test( 0x1.ffff333333333334p+13, 0x1.ddb680117ab141f6da98f76d6b72p+16383 ),
    // Test( 0x1p+14,                  inf_f128                                ), // The first value that gives infinite exp
    // Test( 0x1.0000666666666666p+14, inf_f128                                ),
    // Test(-0x1.01bcp+14 + 0x1p-98,   0x1p-16494                              ), // The last value before the exp flushes to zero
    // Test(-0x1.00f799999999999ap+14, 0x1.125fbee25066p-16446                 ),
    // Test(-0x1.01bcp+14,             0x0p+0                                  ), // The first value at which the exp flushes to zero
    // Test(-0x1.fffp+13,              0x1p-16382                              ), // The last value before the exp flushes to subnormal
    // Test(-0x1.fffp+13 - 0x1p-99,    0x0.ffffffffffffffffffffffffe9d2p-16382 ), // The first value for which exp flushes to subnormal
    // Test(-0x1.fff4p+13,             0x1.6a09e667f3bcc908b2fb1366ea94p-16383 ),
    // Test(-0x1.fff8p+13,             0x1p-16383                              ),
    // Test(-0x1.fffcp+13,             0x1.6a09e667f3bcc908b2fb1366ea94p-16384 ),
    // Test(-0x1p+14,                  0x1p-16384                              ),
    // Test( 0x1p-16384,               0x1p+0                                  ), // Very close to zero

    // zig fmt: on
};

test "exp_128()" {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u128, tc.input);
        const exp_output_bits = @bitCast(u128, tc.exp_output);
        const output: f128 = f128math.exp(tc.input);
        const output_bits = @bitCast(u128, output);
        const sign_pad = if ((input_bits >> 127) > 0) "" else " ";
        const no_sign_pad = if ((input_bits >> 127) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<40}{[3]s} {[2]s}{[0]e:<40}{[3]s} 0x{[1]x:0>32}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<40}  {[0]e:<40} 0x{[1]x:0>32}\n",
            .{ output, output_bits },
        );
        if (output_bits != exp_output_bits) {
            print(
                "exp:   {[0]x:<40}  {[0]e:<40} 0x{[1]x:0>32}\n",
                .{ tc.exp_output, exp_output_bits },
            );
            print("FAILED\n", .{});
            failure = true;
        }
        print("\n", .{});
    }
    if (failure) return error.Failure;
}
