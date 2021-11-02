const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const math = std.math;
const inf_f32 = math.inf_f32;
const nan_f32 = math.nan_f32;

const f128math = @import("f128math");

const TestValue = struct {
    input: f32,
    exp_output: f32,
};

fn Test(input: f32, exp_output: f32) TestValue {
    return .{ .input = input, .exp_output = exp_output };
}

const test_cases = [_]TestValue{
    // zig fmt: off

    // Special cases
    Test( 0x0p+0,   0x1p+0  ),
    Test(-0x0p+0,   0x1p+0  ),
    Test( 0x1p+0,   0x1p+1  ),
    Test(-0x1p+0,   0x1p-1  ),
    Test( inf_f32,  inf_f32 ),
    Test(-inf_f32,  0x0p+0  ),
    Test( nan_f32,  nan_f32 ),
    Test(-nan_f32,  nan_f32 ),
    Test( @bitCast(f32, @as(u32, 0x7ff01234)),  nan_f32 ),
    Test( @bitCast(f32, @as(u32, 0xfff01234)),  nan_f32 ),

    // Sanity cases

    // Some boundary cases specific to exp2
    // Test( 0x1.fffffep+6,   0x1.ffff4ep+127 ), // The last value before the exp gets infinite
    // Test( 0x1.ff999ap+6,   0x1.ddb6a2p+127 ),
    // Test( 0x1p+7,          inf_f32         ), // The first value that gives infinite exp
    // Test( 0x1.003334p+7,   inf_f32         ),
    // Test(-0x1.2bccccp+7,   0x1p-149        ), // The last value before the exp flushes to zero
    // Test(-0x1.2ap+7,       0x1p-149        ),
    // Test(-0x1.2cp+7,       0x0p+0          ), // The first value at which the exp flushes to zero
    // Test(-0x1.2c3334p+7,   0x0p+0          ),
    // Test(-0x1.f8p+6,       0x1p-126        ), // The last value before the exp flushes to subnormal
    // Test(-0x1.f80002p+6,   0x1.ffff5p-127  ), // The first value for which exp flushes to subnormal
    // Test(-0x1.fcp+6,       0x1p-127        ),

    // zig fmt: on
};

test "exp_32()" {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u32, tc.input);
        const exp_output_bits = @bitCast(u32, tc.exp_output);
        const output: f32 = f128math.exp(tc.input);
        const output_bits = @bitCast(u32, output);
        const sign_pad = if ((input_bits & 0x80000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x80000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<16}{[3]s} {[2]s}{[0]e:<16}{[3]s} 0x{[1]x:0>8}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<16}  {[0]e:<16} 0x{[1]x:0>8}\n",
            .{ output, output_bits },
        );
        if (output_bits != exp_output_bits) {
            print(
                "exp:   {[0]x:<16}  {[0]e:<16} 0x{[1]x:0>8}\n",
                .{ tc.exp_output, exp_output_bits },
            );
            print("FAILED\n", .{});
            failure = true;
        }
        print("\n", .{});
    }
    if (failure) return error.Failure;
}