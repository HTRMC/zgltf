const std = @import("std");
const image = @import("zgltf").image;

const c = @cImport({
    @cInclude("stb_image.h");
});

fn stbFree(pixels: []u8) void {
    c.stbi_image_free(pixels.ptr);
}

fn decode(_: ?*anyopaque, _: std.mem.Allocator, bytes: []const u8) image.DecodeError!image.DecodedImage {
    var w: c_int = 0;
    var h: c_int = 0;
    var n: c_int = 0;
    const ptr = c.stbi_load_from_memory(
        bytes.ptr,
        @intCast(bytes.len),
        &w,
        &h,
        &n,
        0,
    ) orelse return error.DecodeFailed;
    const len: usize = @as(usize, @intCast(w)) * @as(usize, @intCast(h)) * @as(usize, @intCast(n));
    return .{
        .width = @intCast(w),
        .height = @intCast(h),
        .channels = @intCast(n),
        .pixels = ptr[0..len],
        .free_with = stbFree,
    };
}

pub const decoder: image.Decoder = .{ .decodeFn = decode };

const testing = std.testing;

test "decode png via stb" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/BoxTextured/glTF/CesiumLogoFlat.png",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var img = try decoder.decode(testing.allocator, bytes);
    defer img.deinit(testing.allocator);
    try testing.expect(img.width > 0);
    try testing.expect(img.height > 0);
    try testing.expect(img.channels >= 3 and img.channels <= 4);
    try testing.expectEqual(@as(usize, @intCast(img.width)) * img.height * img.channels, img.pixels.len);
}

test "decode invalid bytes" {
    const bad = [_]u8{ 0, 0, 0, 0 };
    try testing.expectError(error.DecodeFailed, decoder.decode(testing.allocator, &bad));
}
