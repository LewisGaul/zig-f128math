const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Tests
    // -------
    var tests = b.addTest("tests/exp2/exp2_128.zig");
    tests.addPackagePath("f128math", "src/lib.zig");

    // Define the 'test' subcommand.
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
