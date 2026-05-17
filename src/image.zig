const std = @import("std");

pub const DecodeError = error{ DecodeFailed, OutOfMemory };

pub const DecodedImage = struct {
    width: u32,
    height: u32,
    channels: u8,
    pixels: []u8,
    free_with: ?*const fn (pixels: []u8) void = null,

    pub fn deinit(self: *DecodedImage, allocator: std.mem.Allocator) void {
        if (self.free_with) |f| f(self.pixels) else allocator.free(self.pixels);
        self.* = undefined;
    }
};

pub const Decoder = struct {
    ctx: ?*anyopaque = null,
    decodeFn: *const fn (ctx: ?*anyopaque, allocator: std.mem.Allocator, bytes: []const u8) DecodeError!DecodedImage,

    pub fn decode(self: Decoder, allocator: std.mem.Allocator, bytes: []const u8) DecodeError!DecodedImage {
        return self.decodeFn(self.ctx, allocator, bytes);
    }
};
