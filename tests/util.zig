const std = @import("std");
const print = std.debug.print;

const verbose = true;

pub fn Testcase(
    comptime func: @TypeOf(std.math.exp),
    comptime name: []const u8,
    comptime float_type: type,
) type {
    if (@typeInfo(float_type) != .Float) @compileError("Expected float type");

    return struct {
        const F: type = float_type;

        input: F,
        exp_output: F,

        const bits = std.meta.bitCount(F);
        const U: type = std.meta.Int(.unsigned, bits);

        pub fn run(tc: @This()) !void {
            const hex_bits_fmt_size = comptime std.fmt.comptimePrint("{d}", .{bits / 4});
            const hex_float_fmt_size = switch (bits) {
                16 => "10",
                32 => "16",
                64 => "24",
                128 => "40",
                else => unreachable,
            };
            const input_bits = @bitCast(U, tc.input);
            if (verbose) {
                print(
                    " IN:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ input_bits, tc.input },
                );
            }
            const output = func(tc.input);
            const output_bits = @bitCast(U, output);
            if (verbose) {
                print(
                    "OUT:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ output_bits, output },
                );
            }
            const exp_output_bits = @bitCast(U, tc.exp_output);
            // Compare bits rather than values so that NaN compares correctly.
            if (output_bits != exp_output_bits) {
                if (verbose) {
                    print(
                        "EXP:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                            "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                        .{ exp_output_bits, tc.exp_output },
                    );
                }
                std.debug.print(
                    "FAILURE: expected {s}({x})->{x}, got {x} ({d}-bit)\n",
                    .{ name, tc.input, tc.exp_output, output, bits },
                );
                return error.TestExpectedEqual;
            }
        }
    };
}

pub fn runTests(tests: anytype) !void {
    var failures: usize = 0;
    print("\n", .{});
    for (tests) |tc| {
        tc.run() catch {
            failures += 1;
        };
        print("\n", .{});
    }
    if (failures > 0) return error.Failure;
}
