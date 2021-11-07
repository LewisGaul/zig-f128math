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
    Test( inf_f32,  inf_f32 ),
    Test(-inf_f32,  0x0p+0  ),
    Test( nan_f32,  nan_f32 ),
    Test(-nan_f32,  nan_f32 ),
    Test( @bitCast(f32, @as(u32, 0x7ff01234)),  nan_f32 ),
    Test( @bitCast(f32, @as(u32, 0xfff01234)),  nan_f32 ),

    // Sanity cases
    Test(-0x1.0223a0p+3,  0x1.490320p-12 ),
    Test( 0x1.161868p+2,  0x1.34712ap+6  ),
    Test(-0x1.0c34b4p+3,  0x1.e06b1ap-13 ),
    Test(-0x1.a206f0p+2,  0x1.7dd484p-10 ),
    Test( 0x1.288bbcp+3,  0x1.4abc80p+13 ),
    Test( 0x1.52efd0p-1,  0x1.f04a9cp+0  ),
    Test(-0x1.a05cc8p-2,  0x1.54f1e0p-1  ),
    Test( 0x1.1f9efap-1,  0x1.c0f628p+0  ),
    Test( 0x1.8c5db0p-1,  0x1.1599b2p+1  ),
    Test(-0x1.5b86eap-1,  0x1.03b572p-1  ),
    Test(-0x1.57f25cp+2,  0x1.2fbea2p-8  ),
    Test( 0x1.c7d310p+3,  0x1.76eefp+20  ),
    Test( 0x1.19be70p+4,  0x1.52d3dep+25 ),
    Test(-0x1.ab6d70p+3,  0x1.a88adep-20 ),
    Test(-0x1.5ac18ep+2,  0x1.22b328p-8  ),
    Test(-0x1.925982p-1,  0x1.d2acc0p-2  ),
    Test( 0x1.7221cep+3,  0x1.9c2ceap+16 ),
    Test( 0x1.11a0d4p+4,  0x1.980ee6p+24 ),
    Test(-0x1.ae41a2p+1,  0x1.1c28d0p-5  ),
    Test(-0x1.329154p+4,  0x1.47ef94p-28 ),

    // Some boundary cases specific to exp2
    Test( 0x1.62e42ep+6,   0x1.ffff08p+127 ), // The last value before the exp gets infinite
    Test( 0x1.62e430p+6,   inf_f32         ), // The first value that gives infinite exp
    Test( 0x1.fffffep+127, inf_f32         ), // Max input value
    Test( 0x1p-149,        0x1p+0          ), // Tiny input values
    Test(-0x1p-149,        0x1p+0          ),
    Test( 0x1p-126,        0x1p+0          ),
    Test(-0x1p-126,        0x1p+0          ),
    Test(-0x1.9fe368p+6,   0x1p-149        ), // The last value before the exp flushes to zero
    Test(-0x1.9fe36ap+6,   0x0p+0          ), // The first value at which the exp flushes to zero
    Test(-0x1.5d589ep+6,   0x1.00004cp-126 ), // The last value before the exp flushes to subnormal
    Test(-0x1.5d58a0p+6,   0x1.ffff98p-127 ), // The first value for which exp flushes to subnormal

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
