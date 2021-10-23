const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    // Tests
    // -------
    var tests = b.addTest("tests/tests.zig");
    tests.addPackagePath("f128math", "src/lib.zig");

    // Define the 'test' subcommand.
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
