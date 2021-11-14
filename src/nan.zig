
pub const snan_u16 = @as(u16, 0x7C01);
pub const snan_f16 = @bitCast(f16, snan_u16);

pub const qnan_u16 = @as(u16, 0x7E00);
pub const qnan_f16 = @bitCast(f16, qnan_u16);

pub const snan_u32 = @as(u32, 0x7F800001);
pub const snan_f32 = @bitCast(f32, snan_u32);

pub const qnan_u32 = @as(u32, 0x7FC00000);
pub const qnan_f32 = @bitCast(f32, qnan_u32);

pub const snan_u64 = @as(u64, 0x7FF << 52) | 1;
pub const snan_f64 = @bitCast(f64, snan_u64);

pub const qnan_u64 = @as(u64, 0x7FF8 << 48);
pub const qnan_f64 = @bitCast(f64, qnan_u64);

pub const snan_u128 = @as(u128, 0x7FFF << 112) | 1;
pub const snan_f128 = @bitCast(f128, snan_u128);

pub const qnan_u128 = @as(u128, 0x7FFF8 << 108);
pub const qnan_f128 = @bitCast(f128, qnan_u128);

/// Returns the quiet nan representation for type T.
pub fn nan(comptime T: type) T {
    return switch (T) {
        f16 => qnan_f16,
        f32 => qnan_f32,
        f64 => qnan_f64,
        f128 => qnan_f128,
        else => @compileError("nan not implemented for " ++ @typeName(T)),
    };
}

/// Returns the signalling nan representation for type T.
pub fn snan(comptime T: type) T {
    return switch (T) {
        f16 => @bitCast(f16, snan_u16),
        f32 => @bitCast(f32, snan_u32),
        f64 => @bitCast(f64, snan_u64),
        else => @compileError("snan not implemented for " ++ @typeName(T)),
    };
}
