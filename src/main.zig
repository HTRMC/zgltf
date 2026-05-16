const std = @import("std");
const Io = std.Io;
const zgltf = @import("zgltf");

const sample =
    \\{
    \\  "asset": {
    \\    "version": "2.0",
    \\    "generator": "zgltf demo"
    \\  }
    \\}
;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const w = &stdout_file_writer.interface;

    var parsed = try zgltf.parseSlice(arena, sample);
    defer parsed.deinit();

    const a = parsed.value.asset;
    try w.print("version: {s}\n", .{a.version});
    if (a.generator) |g| try w.print("generator: {s}\n", .{g});
    if (a.minVersion) |m| try w.print("minVersion: {s}\n", .{m});
    if (a.copyright) |c| try w.print("copyright: {s}\n", .{c});

    try w.flush();
}
