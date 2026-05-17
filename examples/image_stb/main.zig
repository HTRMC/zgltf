const std = @import("std");
const Io = std.Io;
const decoder = @import("decoder.zig").decoder;

pub fn main(init: std.process.Init) !void {
    const gpa = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const w = &stdout_file_writer.interface;

    var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, gpa);
    defer it.deinit();
    _ = it.next();
    const path = it.next() orelse {
        try w.print("usage: image_stb <path-to-image>\n", .{});
        try w.flush();
        return;
    };

    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited);
    defer gpa.free(bytes);

    var img = try decoder.decode(gpa, bytes);
    defer img.deinit(gpa);

    try w.print("{s}: {d}x{d} ch={d} bytes={d}\n", .{
        path, img.width, img.height, img.channels, img.pixels.len,
    });
    try w.flush();
}
