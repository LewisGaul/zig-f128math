const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const math = std.math;
const inf_f128 = math.inf_f128;
const nan_f128 = math.nan_f128;

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
    Test( 0x0p+0,                  0x1p+0                  ),
    Test(-0x0p+0,                  0x1p+0                  ),
    Test( 0x1p-1074,               0x1p+0                  ), // Smallest denorm positive
    Test(-0x1p-1074,               0x1p+0                  ), // Smallest denorm negative
    Test( inf_f128,                inf_f128                ),
    Test(-inf_f128,                0x0p+0                  ),
    Test( nan_f128,                nan_f128                ),

    // Sanity cases
    Test(-0x1.02239f3c6a8f13dep+3, 0x1.e8d13c396f44f5p-9   ),
    Test( 0x1.161868e18bc67782p+2, 0x1.4536746bb6f139f4p+4 ),
    Test(-0x1.0c34b3e01e6e682cp+3, 0x1.890ca0c00b9a679cp-9 ),
    Test(-0x1.a206f0a19dcc3948p+2, 0x1.622d4b0ebc6c2e5ap-7 ),
    Test( 0x1.288bbb0d6a1e5bdap+3, 0x1.340ec7f3e607c5bep+9 ),
    Test( 0x1.52efd0cd80496a5ap-1, 0x1.950eef4bc5450eeap+0 ),
    Test(-0x1.a05cc754481d0bdp-2,  0x1.824056efc687c4f8p-1 ),
    Test( 0x1.1f9ef934745cad6p-1,  0x1.79dfa14ab121da5p+0  ),
    Test( 0x1.8c5db097f744257ep-1, 0x1.b5cead2247372396p+0 ),
    Test(-0x1.5b86ea8118a0e2bcp-1, 0x1.3fd8ba33216b93cep-1 ),

    // zig fmt: on
};

test {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u128, tc.input);
        const exp_output_bits = @bitCast(u128, tc.exp_output);
        const output: f128 = exp2_f128(tc.input);
        const output_bits = @bitCast(u128, output);
        const sign_pad = if ((input_bits & 0x80000000000000000000000000000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x80000000000000000000000000000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<30}{[3]s} {[2]s}{[0]e:<30}{[3]s} 0x{[1]x:0<32}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<30}  {[0]e:<30} 0x{[1]x:0<32}\n",
            .{ output, output_bits },
        );
        print(
            "exp:   {[0]x:<30}  {[0]e:<30} 0x{[1]x:0<32}\n",
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
