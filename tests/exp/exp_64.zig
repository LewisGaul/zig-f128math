const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const math = std.math;
const inf_f64 = math.inf_f64;
const nan_f64 = math.nan_f64;

const f128math = @import("f128math");

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
    Test( 0x0p+0,                  0x1p+0                  ),
    Test(-0x0p+0,                  0x1p+0                  ),
    Test( 0x1p-1074,               0x1p+0                  ), // Smallest denorm positive
    Test(-0x1p-1074,               0x1p+0                  ), // Smallest denorm negative
    Test( inf_f64,                 inf_f64                 ),
    Test(-inf_f64,                 0x0p+0                  ),
    Test( nan_f64,                 nan_f64                 ),

    // Sanity cases
    Test(-0x1.02239f3c6a8f1p+3,    0x1.490327ea61235p-12   ),
    Test( 0x1.161868e18bc67p+2,    0x1.34712ed238c04p+6    ),
    Test(-0x1.0c34b3e01e6e7p+3,    0x1.e06b1b6c18e64p-13   ),
    Test(-0x1.a206f0a19dcc4p+2,    0x1.7dd47f810e68cp-10   ),
    Test( 0x1.288bbb0d6a1e6p+3,    0x1.4abc77496e07ep+13   ),
    Test( 0x1.52efd0cd80497p-1,    0x1.f04a9c10805p+0      ),
    Test(-0x1.a05cc754481d1p-2,    0x1.54f1e0fd3ea0dp-1    ),
    Test( 0x1.1f9ef934745cbp-1,    0x1.c0f6266a6a547p+0    ),
    Test( 0x1.8c5db097f7442p-1,    0x1.1599b1d4a25fbp+1    ),
    Test(-0x1.5b86ea8118a0ep-1,    0x1.03b5728a00229p-1    ),

    // Some boundary cases specific to the exp
    Test( 0x1.62e42fefa39efp+9,    0x1.fffffffffff2ap+1023 ), // The last value before the exp gets infinite
    Test( 0x1.62e42fefa39fp+9,     inf_f64                 ), // The first value that gives infinite exp
    Test(-0x1.74910d52d3051p+9,    0x1p-1074               ), // The last value before the exp flushes to zero
    Test(-0x1.74910d52d3052p+9,    0x0p+0                  ), // The first value at which the exp flushes to zero
    Test(-0x1.6232bdd7abcd2p+9,    0x1.000000000007cp-1022 ), // The last value before the exp flushes to subnormal
    Test(-0x1.6232bdd7abcd3p+9,    0x1.ffffffffffcf8p-1023 ), // The first value for which exp flushes to subnormal

    // zig fmt: on
};

test {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u64, tc.input);
        const exp_output_bits = @bitCast(u64, tc.exp_output);
        const output: f64 = math.exp(tc.input);
        const output_bits = @bitCast(u64, output);
        const sign_pad = if ((input_bits & 0x8000000000000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x8000000000000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<24}{[3]s} {[2]s}{[0]e:<24}{[3]s} 0x{[1]x:0<16}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<24}  {[0]e:<24} 0x{[1]x:0<16}\n",
            .{ output, output_bits },
        );
        print(
            "exp:   {[0]x:<24}  {[0]e:<24} 0x{[1]x:0<16}\n",
            .{ tc.exp_output, exp_output_bits },
        );
        if (output_bits != exp_output_bits) {
            print("FAILED\n", .{});
            failure = true;
        }
        print("\n", .{});
    }
    if (failure) return error.Failure;
}
