const std = @import("std");
const Io = std.Io;
const zgltf = @import("zgltf");

const sample =
    \\{
    \\  "asset": { "version": "2.0", "generator": "zgltf demo" },
    \\  "buffers": [
    \\    { "byteLength": 44, "uri": "tri.bin" }
    \\  ],
    \\  "bufferViews": [
    \\    { "buffer": 0, "byteOffset": 0,  "byteLength": 36, "target": 34962 },
    \\    { "buffer": 0, "byteOffset": 36, "byteLength": 6,  "target": 34963 }
    \\  ],
    \\  "accessors": [
    \\    { "bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3",
    \\      "min": [0.0, 0.0, 0.0], "max": [1.0, 1.0, 0.0] },
    \\    { "bufferView": 1, "componentType": 5123, "count": 3, "type": "SCALAR" }
    \\  ]
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
    const g = parsed.value;

    try w.print("version: {s}\n", .{g.asset.version});
    if (g.asset.generator) |gen| try w.print("generator: {s}\n", .{gen});

    if (g.buffers) |bs| try w.print("buffers: {d}\n", .{bs.len});
    if (g.bufferViews) |vs| try w.print("bufferViews: {d}\n", .{vs.len});
    if (g.accessors) |as| {
        try w.print("accessors: {d}\n", .{as.len});
        for (as, 0..) |a, i| {
            const ct: zgltf.ComponentType = @enumFromInt(a.componentType);
            try w.print("  [{d}] type={t} componentType={t} count={d} bytes={d}\n", .{
                i, a.type, ct, a.count, ct.byteSize() * a.type.componentCount() * a.count,
            });
        }
    }

    try w.flush();
}
