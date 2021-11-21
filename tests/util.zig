const std = @import("std");
const print = std.debug.print;

const verbose = true;

pub const FloatType = enum {
    Binary16,
    Binary32,
    Binary64,
    Binary128,
    // CLongDouble,

    pub fn bits(self: @This()) u8 {
        return switch (self) {
            .Binary16 => 16,
            .Binary32 => 32,
            .Binary64 => 64,
            .Binary128 => 128,
            // .CLongDouble => @compileError("c_longdouble not yet supported"),
        };
    }

    pub fn ftype(self: @This()) type {
        // TODO: Get this added to std?
        // return std.meta.Float(self.bits());
        return @Type(.{ .Float = .{ .bits = self.bits() } });
    }

    pub fn utype(self: @This()) type {
        return std.meta.Int(.unsigned, self.bits());
    }
};

pub fn Testcase(
    comptime func: @TypeOf(std.math.exp),
    comptime name: []const u8,
    comptime float_type: FloatType,
) type {
    return struct {
        const f: FloatType = float_type;

        input: f.ftype(),
        exp_output: f.ftype(),

        pub fn run(tc: @This()) !void {
            const hex_bits_fmt_size = switch (f) {
                .Binary16 => "4",
                .Binary32 => "8",
                .Binary64 => "16",
                .Binary128 => "32",
            };
            const hex_float_fmt_size = switch (f) {
                .Binary16 => "10",
                .Binary32 => "16",
                .Binary64 => "24",
                .Binary128 => "40",
            };
            const input_bits = @bitCast(f.utype(), tc.input);
            if (verbose) {
                print(
                    " IN:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ input_bits, tc.input },
                );
            }
            const output = func(tc.input);
            const output_bits = @bitCast(f.utype(), output);
            if (verbose) {
                print(
                    "OUT:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ output_bits, output },
                );
            }
            const exp_output_bits = @bitCast(f.utype(), tc.exp_output);
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
                    .{ name, tc.input, tc.exp_output, output, f.bits() },
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
