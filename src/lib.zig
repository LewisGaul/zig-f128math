const std = @import("std");

// Import/expose everything from std.math so that this package can take its place.
pub const e = std.math.e;
pub const pi = std.math.pi;
pub const phi = std.math.phi;
pub const tau = std.math.tau;
pub const log2e = std.math.log2e;
pub const log10e = std.math.log10e;
pub const ln2 = std.math.ln2;
pub const ln10 = std.math.ln10;
pub const two_sqrtpi = std.math.two_sqrtpi;
pub const sqrt2 = std.math.sqrt2;
pub const sqrt1_2 = std.math.sqrt1_2;
pub const f128_true_min = std.math.f128_true_min;
pub const f128_min = std.math.f128_min;
pub const f128_max = std.math.f128_max;
pub const f128_epsilon = std.math.f128_epsilon;
pub const f128_toint = std.math.f128_toint;
pub const f64_true_min = std.math.f64_true_min;
pub const f64_min = std.math.f64_min;
pub const f64_max = std.math.f64_max;
pub const f64_epsilon = std.math.f64_epsilon;
pub const f64_toint = std.math.f64_toint;
pub const f32_true_min = std.math.f32_true_min;
pub const f32_min = std.math.f32_min;
pub const f32_max = std.math.f32_max;
pub const f32_epsilon = std.math.f32_epsilon;
pub const f32_toint = std.math.f32_toint;
pub const f16_true_min = std.math.f16_true_min;
pub const f16_min = std.math.f16_min;
pub const f16_max = std.math.f16_max;
pub const f16_epsilon = std.math.f16_epsilon;
pub const f16_toint = std.math.f16_toint;

pub const epsilon = std.math.epsilon;

// pub const nan_u16 = std.math.nan_u16;
// pub const nan_f16 = std.math.nan_f16;
// pub const qnan_u16 = std.math.qnan_u16;
// pub const qnan_f16 = std.math.qnan_f16;
pub const inf_u16 = std.math.inf_u16;
pub const inf_f16 = std.math.inf_f16;
// pub const nan_u32 = std.math.nan_u32;
// pub const nan_f32 = std.math.nan_f32;
// pub const qnan_u32 = std.math.qnan_u32;
// pub const qnan_f32 = std.math.qnan_f32;
pub const inf_u32 = std.math.inf_u32;
pub const inf_f32 = std.math.inf_f32;
// pub const nan_u64 = std.math.nan_u64;
// pub const nan_f64 = std.math.nan_f64;
// pub const qnan_u64 = std.math.qnan_u64;
// pub const qnan_f64 = std.math.qnan_f64;
pub const inf_u64 = std.math.inf_u64;
pub const inf_f64 = std.math.inf_f64;
// pub const nan_u128 = std.math.nan_u128;
// pub const nan_f128 = std.math.nan_f128;
// pub const qnan_u128 = std.math.qnan_u128;
// pub const qnan_f128 = std.math.qnan_f128;
pub const inf_u128 = std.math.inf_u128;
pub const inf_f128 = std.math.inf_f128;

pub const inf = std.math.inf;

pub const isNan = std.math.isNan;
pub const isSignalNan = std.math.isSignalNan;
pub const fabs = std.math.fabs;
pub const ceil = std.math.ceil;
pub const floor = std.math.floor;
pub const trunc = std.math.trunc;
pub const round = std.math.round;
pub const frexp = std.math.frexp;
pub const Frexp = std.math.Frexp;
pub const modf = std.math.modf;
pub const modf32_result = std.math.modf32_result;
pub const modf64_result = std.math.modf64_result;
pub const copysign = std.math.copysign;
pub const isFinite = std.math.isFinite;
pub const isInf = std.math.isInf;
pub const isPositiveInf = std.math.isPositiveInf;
pub const isNegativeInf = std.math.isNegativeInf;
pub const isNormal = std.math.isNormal;
pub const signbit = std.math.signbit;
pub const scalbn = std.math.scalbn;
pub const pow = std.math.pow;
pub const powi = std.math.powi;
pub const sqrt = std.math.sqrt;
pub const cbrt = std.math.cbrt;
pub const acos = std.math.acos;
pub const asin = std.math.asin;
pub const atan = std.math.atan;
pub const atan2 = std.math.atan2;
pub const hypot = std.math.hypot;
// pub const exp = std.math.exp;
// pub const exp2 = std.math.exp2;
pub const expm1 = std.math.expm1;
pub const ilogb = std.math.ilogb;
pub const ln = std.math.ln;
pub const log = std.math.log;
pub const log2 = std.math.log2;
pub const log10 = std.math.log10;
pub const log1p = std.math.log1p;
pub const fma = std.math.fma;
pub const asinh = std.math.asinh;
pub const acosh = std.math.acosh;
pub const atanh = std.math.atanh;
pub const sinh = std.math.sinh;
pub const cosh = std.math.cosh;
pub const tanh = std.math.tanh;
pub const cos = std.math.cos;
pub const sin = std.math.sin;
pub const tan = std.math.tan;

pub const complex = std.math.complex;
pub const Complex = complex.Complex;

pub const big = std.math.big;

pub const approxEqAbs = std.math.approxEqAbs;
pub const approxEqRel = std.math.approxEqRel;
pub const doNotOptimizeAway = std.math.doNotOptimizeAway;
pub const raiseInvalid = std.math.raiseInvalid;
pub const raiseUnderflow = std.math.raiseUnderflow;
pub const raiseOverflow = std.math.raiseOverflow;
pub const raiseInexact = std.math.raiseInexact;
pub const raiseDivByZero = std.math.raiseDivByZero;
pub const floatMantissaBits = std.math.floatMantissaBits;
pub const floatExponentBits = std.math.floatExponentBits;
pub const Min = std.math.Min;
pub const min = std.math.min;
pub const min3 = std.math.min3;
pub const max = std.math.max;
pub const max3 = std.math.max3;
pub const clamp = std.math.clamp;
pub const mul = std.math.mul;
pub const add = std.math.add;
pub const sub = std.math.sub;
pub const negate = std.math.negate;
pub const shlExact = std.math.shlExact;
pub const shl = std.math.shl;
pub const shr = std.math.shr;
pub const rotr = std.math.rotr;
pub const rotl = std.math.rotl;
pub const Log2Int = std.math.Log2Int;
pub const Log2IntCeil = std.math.Log2IntCeil;
pub const IntFittingRange = std.math.IntFittingRange;
pub const absInt = std.math.absInt;
pub const divTrunc = std.math.divTrunc;
pub const divFloor = std.math.divFloor;
pub const divCeil = std.math.divCeil;
pub const divExact = std.math.divExact;
pub const mod = std.math.mod;
pub const rem = std.math.rem;
pub const absCast = std.math.absCast;
pub const negateCast = std.math.negateCast;
pub const cast = std.math.cast;
pub const alignCast = std.math.alignCast;
pub const isPowerOfTwo = std.math.isPowerOfTwo;
pub const floorPowerOfTwo = std.math.floorPowerOfTwo;
pub const ceilPowerOfTwoPromote = std.math.ceilPowerOfTwoPromote;
pub const ceilPowerOfTwo = std.math.ceilPowerOfTwo;
pub const ceilPowerOfTwoAssert = std.math.ceilPowerOfTwoAssert;
pub const log2_int = std.math.log2_int;
pub const log2_int_ceil = std.math.log2_int_ceil;
pub const lossyCast = std.math.lossyCast;
pub const maxInt = std.math.maxInt;
pub const minInt = std.math.minInt;
pub const mulWide = std.math.mulWide;
pub const order = std.math.order;
pub const compare = std.math.compare;
pub const comptimeMod = std.math.comptimeMod;

// Stuff that's been rewritten/modified within the package.
pub const exp = @import("exp.zig").exp;
pub const exp2 = @import("exp2.zig").exp2;
pub const nan = @import("nan.zig").nan;
pub const snan = @import("nan.zig").snan;

pub const snan_u16 = @import("nan.zig").snan_u16;
pub const snan_f16 = @import("nan.zig").snan_f16;
pub const qnan_u16 = @import("nan.zig").qnan_u16;
pub const qnan_f16 = @import("nan.zig").qnan_f16;
pub const snan_u32 = @import("nan.zig").snan_u32;
pub const snan_f32 = @import("nan.zig").snan_f32;
pub const qnan_u32 = @import("nan.zig").qnan_u32;
pub const qnan_f32 = @import("nan.zig").qnan_f32;
pub const snan_u64 = @import("nan.zig").snan_u64;
pub const snan_f64 = @import("nan.zig").snan_f64;
pub const qnan_u64 = @import("nan.zig").qnan_u64;
pub const qnan_f64 = @import("nan.zig").qnan_f64;
pub const snan_u128 = @import("nan.zig").snan_u128;
pub const snan_f128 = @import("nan.zig").snan_f128;
pub const qnan_u128 = @import("nan.zig").qnan_u128;
pub const qnan_f128 = @import("nan.zig").qnan_f128;

pub fn singleInputFuncMain(comptime func: @TypeOf(exp)) !void {
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
            "Unexpected input length {d} - expected a 32 or 64-bit hex int\n",
            .{input_arg.len},
        );
        return error.InvalidArgs;
    }
}
