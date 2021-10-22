const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const math = std.math;
const inf_f32 = math.inf_f32;
const nan_f32 = math.nan_f32;

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
    Test( 0x0p+0,          0x1p+0        ),
    Test(-0x0p+0,          0x1p+0        ),
    Test( 0x1p-1074,       0x1p+0        ), // Smallest denorm positive
    Test(-0x1p-1074,       0x1p+0        ), // Smallest denorm negative
    Test( inf_f32,         inf_f32       ),
    Test(-inf_f32,         0x0p+0        ),
    Test( nan_f32,         nan_f32       ),

    // Sanity cases
    Test(-0x1.0223ap+3,    0x1.e8d134p-9 ),
    Test( 0x1.161868p+2,   0x1.453672p+4 ),
    Test(-0x1.0c34b4p+3,   0x1.890cap-9  ),
    Test(-0x1.a206fp+2,    0x1.622d4ep-7 ),
    Test( 0x1.288bbcp+3,   0x1.340ecep+9 ),
    Test( 0x1.52efdp-1,    0x1.950eeep+0 ),
    Test(-0x1.a05cc8p-2,   0x1.824056p-1 ),
    Test( 0x1.1f9efap-1,   0x1.79dfa2p+0 ),
    Test( 0x1.8c5dbp-1,    0x1.b5ceacp+0 ),
    Test(-0x1.5b86eap-1,   0x1.3fd8bap-1 ),

    // zig fmt: on
};

test {
    var failure = false;
    for (test_cases) |tc| {
        const input_bits = @bitCast(u32, tc.input);
        const exp_output_bits = @bitCast(u32, tc.exp_output);
        const output: f32 = math.exp2(tc.input);
        const output_bits = @bitCast(u32, output);
        const sign_pad = if ((input_bits & 0x80000000) > 0) "" else " ";
        const no_sign_pad = if ((input_bits & 0x80000000) > 0) " " else "";
        print(
            " in:  {[2]s}{[0]x:<16}{[3]s} {[2]s}{[0]e:<16}{[3]s} 0x{[1]x:0<8}\n",
            .{ tc.input, input_bits, sign_pad, no_sign_pad },
        );
        print(
            "out:   {[0]x:<16}  {[0]e:<16} 0x{[1]x:0<8}\n",
            .{ output, output_bits },
        );
        print(
            "exp:   {[0]x:<16}  {[0]e:<16} 0x{[1]x:0<8}\n",
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
