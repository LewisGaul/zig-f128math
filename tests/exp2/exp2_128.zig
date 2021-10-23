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

    // Sanity cases
    Test(-0x1.02239f3c6a8f13dep+3, 0x1.e8d13c396f44f500bfc7cefe1304p-9 ),
    Test( 0x1.161868e18bc67782p+2, 0x1.4536746bb6f139f3c05f40f3758dp+4 ),
    Test(-0x1.0c34b3e01e6e682cp+3, 0x1.890ca0c00b9a679b66a1cc43e168p-9 ),
    Test(-0x1.a206f0a19dcc3948p+2, 0x1.622d4b0ebc6c2e5980cda14724e4p-7 ),
    Test( 0x1.288bbb0d6a1e5bdap+3, 0x1.340ec7f3e607c5bd584d33ade9aep+9 ),
    Test( 0x1.52efd0cd80496a5ap-1, 0x1.950eef4bc5450eeabc992d9ba86ap+0 ),
    Test(-0x1.a05cc754481d0bd0p-2, 0x1.824056efc687c4f8b3c7e1f4f9fbp-1 ),
    Test( 0x1.1f9ef934745cad60p-1, 0x1.79dfa14ab121da4f38057c8f9f2ep+0 ),
    Test( 0x1.8c5db097f744257ep-1, 0x1.b5cead22473723958363b617f84ep+0 ),
    Test(-0x1.5b86ea8118a0e2bcp-1, 0x1.3fd8ba33216b93ceab3a5697c480p-1 ),

    // Some boundary cases specific to exp2
    Test( 0x1p+14 - 0x1p-99,       0x1.ffffffffffffffffffffffffd3a3p+16383 ), // The last value before the exp gets infinite
    Test( 0x1p+14,                 inf_f128                                ), // The first value that gives infinite exp
    Test(-0x1.01b8p+14,            0x1p-16494                              ), // The last value before the exp flushes to zero
    Test(-0x1.01b8p+14 - 0x1p-98,  0x0p+0                                  ), // The first value at which the exp flushes to zero
    Test(-0x1.fffp+13,             0x1p-16382                              ), // The last value before the exp flushes to subnormal
    Test(-0x1.fffp+13 - 0x1p-99,   0x0.ffffffffffffffffffffffffe9d2p-16382 ), // The first value for which exp flushes to subnormal
    Test(-0x1.fff8p+13,            0x1p-16383                              ),

    // zig fmt: on
};

test "exp2_128()" {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u128, tc.input);
        const exp_output_bits = @bitCast(u128, tc.exp_output);
        const output: f128 = f128math.exp2(tc.input);
        const output_bits = @bitCast(u128, output);
        const sign_pad = if ((input_bits & 0x80000000000000000000000000000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x80000000000000000000000000000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<40}{[3]s} {[2]s}{[0]e:<40}{[3]s} 0x{[1]x:0>32}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<40}  {[0]e:<40} 0x{[1]x:0>32}\n",
            .{ output, output_bits },
        );
        print(
            "exp:   {[0]x:<40}  {[0]e:<40} 0x{[1]x:0>32}\n",
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
