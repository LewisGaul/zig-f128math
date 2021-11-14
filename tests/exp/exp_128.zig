const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const f128math = @import("f128math");
const math = f128math;
const inf_f128 = math.inf_f128;
const nan_f128 = math.qnan_f128;


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
    Test( inf_f128,  inf_f128 ),
    Test(-inf_f128,  0x0p+0   ),
    Test( nan_f128,  nan_f128 ),
    Test(-nan_f128,  nan_f128 ),
    Test( @bitCast(f128, @as(u128, 0x7fff1234000000000000000000000000)),  nan_f128 ),
    Test( @bitCast(f128, @as(u128, 0xffff1234000000000000000000000000)),  nan_f128 ),

    // Sanity cases
    Test(-0x1.02239f3c6a8f13dep+3,  0x1.490327ea61232c65cff53beed777p-12 ),
    Test( 0x1.161868e18bc67782p+2,  0x1.34712ed238c064a14a59ddb90119p+6  ),
    Test(-0x1.0c34b3e01e6e682cp+3,  0x1.e06b1b6c18e6b9852676f1295765p-13 ),
    Test(-0x1.a206f0a19dcc3948p+2,  0x1.7dd47f810e68efcaa7504b9387d0p-10 ),
    Test( 0x1.288bbb0d6a1e5bdap+3,  0x1.4abc77496e07b24ad548e9379bcap+13 ),
    Test( 0x1.52efd0cd80496a5ap-1,  0x1.f04a9c1080500277b844a5191ca4p+0  ),
    Test(-0x1.a05cc754481d0bd0p-2,  0x1.54f1e0fd3ea0d31771802892d4e9p-1  ),
    Test( 0x1.1f9ef934745cad60p-1,  0x1.c0f6266a6a5473f6d16e0140d987p+0  ),
    Test( 0x1.8c5db097f744257ep-1,  0x1.1599b1d4a25fb7c587a30b9ea597p+1  ),
    Test(-0x1.5b86ea8118a0e2bcp-1,  0x1.03b5728a0022870d16a9c4217353p-1  ),

    // Boundary cases
    Test( 0x1.62e42fefa39ef35793c7673007e5p+13,   0x1.ffffffffffffffffffffffffc4a8p+16383 ), // The last value before the exp gets infinite
    Test( 0x1.62e42fefa39ef35793c7673007e6p+13,   inf_f128                                ), // The first value that gives infinite exp
    Test(-0x1.654bb3b2c73ebb059fabb506ff33p+13,   0x1p-16494                              ), // The last value before the exp flushes to zero
    Test(-0x1.654bb3b2c73ebb059fabb506ff34p+13,   0x0p+0                                  ), // The first value at which the exp flushes to zero
    Test(-0x1.62d918ce2421d65ff90ac8f4ce65p+13,   0x1.00000000000000000000000015c6p-16382 ), // The last value before the exp flushes to subnormal
    Test(-0x1.62d918ce2421d65ff90ac8f4ce66p+13,   0x1.ffffffffffffffffffffffffeb8cp-16383 ), // The first value for which exp flushes to subnormal

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
