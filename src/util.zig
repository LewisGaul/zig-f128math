const std = @import("std");

pub fn singleInputFuncMain(comptime func: @TypeOf(std.math.exp)) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var arg_iter = std.process.args();

    // Skip this exe name.
    _ = arg_iter.skip();

    var a = &arena.allocator;

    const input_arg = try (arg_iter.next(a) orelse {
        std.debug.print("Expected an input argument\n", .{});
        return error.InvalidArgs;
    });
    if (arg_iter.next(a)) |_| {
        std.debug.print("Expected exactly one input argument\n", .{});
        return error.InvalidArgs;
    }
    if (!std.mem.eql(u8, input_arg[0..2], "0x")) {
        std.debug.print("Expected input to start with '0x'\n", .{});
        return error.InvalidArgs;
    }

    const stdout = std.io.getStdOut().writer();
    if (input_arg.len == 10) {
        const input_bits = try std.fmt.parseUnsigned(u32, input_arg, 0);
        const input = @bitCast(f32, input_bits);
        std.debug.print(
            "IN:  0x{X:0>8}  {[1]x}  {[1]e}\n",
            .{ input_bits, input },
        );
        const result = func(input);
        const result_bits = @bitCast(u32, result);
        std.debug.print(
            "OUT: 0x{X:0>8}  {[1]x}  {[1]e}\n",
            .{ result_bits, result },
        );
        try stdout.print("0x{X:0>8}", .{@bitCast(u32, result)});
    } else if (input_arg.len == 18) {
        const input_bits = try std.fmt.parseUnsigned(u64, input_arg, 0);
        const input = @bitCast(f64, input_bits);
        std.debug.print(
            "IN:  0x{X:0>16}  {[1]x}  {[1]e}\n",
            .{ input_bits, input },
        );
        const result = func(input);
        const result_bits = @bitCast(u64, result);
        std.debug.print(
            "OUT: 0x{X:0>16}  {[1]x}  {[1]e}\n",
            .{ result_bits, result },
        );
        try stdout.print("0x{X:0>16}", .{@bitCast(u64, result)});
    } else if (input_arg.len == 34) {
        const input_bits = try std.fmt.parseUnsigned(u128, input_arg, 0);
        const input = @bitCast(f128, input_bits);
        std.debug.print(
            "IN:  0x{X:0>32}  {[1]x}  {[1]e}\n",
            .{ input_bits, input },
        );
        const result = func(input);
        const result_bits = @bitCast(u128, result);
        std.debug.print(
            "OUT: 0x{X:0>32}  {x}\n",
            .{ result_bits, result },
        );
        try stdout.print("0x{X:0>32}", .{@bitCast(u128, result)});
    } else {
        std.debug.print(
            "Unexpected input length {d} - expected a 32, 64, or 128-bit hex int\n",
            // "Unexpected input length {d} - expected a 32 or 64-bit hex int\n",
            .{input_arg.len},
        );
        return error.InvalidArgs;
    }
}
