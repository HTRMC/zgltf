const std = @import("std");

pub const Asset = struct {
    version: []const u8,
    minVersion: ?[]const u8 = null,
    generator: ?[]const u8 = null,
    copyright: ?[]const u8 = null,
};

pub const ComponentType = enum(u32) {
    byte = 5120,
    unsigned_byte = 5121,
    short = 5122,
    unsigned_short = 5123,
    unsigned_int = 5125,
    float = 5126,

    pub fn byteSize(self: ComponentType) u32 {
        return switch (self) {
            .byte, .unsigned_byte => 1,
            .short, .unsigned_short => 2,
            .unsigned_int, .float => 4,
        };
    }
};

pub const AccessorType = enum {
    SCALAR,
    VEC2,
    VEC3,
    VEC4,
    MAT2,
    MAT3,
    MAT4,

    pub fn componentCount(self: AccessorType) u32 {
        return switch (self) {
            .SCALAR => 1,
            .VEC2 => 2,
            .VEC3 => 3,
            .VEC4, .MAT2 => 4,
            .MAT3 => 9,
            .MAT4 => 16,
        };
    }
};

pub const BufferViewTarget = enum(u32) {
    array_buffer = 34962,
    element_array_buffer = 34963,
};

pub const Buffer = struct {
    byteLength: u64,
    uri: ?[]const u8 = null,
    name: ?[]const u8 = null,
};

pub const BufferView = struct {
    buffer: u32,
    byteOffset: u32 = 0,
    byteLength: u64,
    byteStride: ?u32 = null,
    target: ?u32 = null,
    name: ?[]const u8 = null,
};

pub const SparseIndices = struct {
    bufferView: u32,
    byteOffset: u32 = 0,
    componentType: u32,
};

pub const SparseValues = struct {
    bufferView: u32,
    byteOffset: u32 = 0,
};

pub const Sparse = struct {
    count: u32,
    indices: SparseIndices,
    values: SparseValues,
};

pub const Accessor = struct {
    bufferView: ?u32 = null,
    byteOffset: u32 = 0,
    componentType: u32,
    normalized: bool = false,
    count: u32,
    type: AccessorType,
    max: ?[]f64 = null,
    min: ?[]f64 = null,
    sparse: ?Sparse = null,
    name: ?[]const u8 = null,
};

pub const Gltf = struct {
    asset: Asset,
    buffers: ?[]Buffer = null,
    bufferViews: ?[]BufferView = null,
    accessors: ?[]Accessor = null,
};

pub const ParseError = std.json.ParseError(std.json.Scanner);

pub fn parseSlice(allocator: std.mem.Allocator, bytes: []const u8) ParseError!std.json.Parsed(Gltf) {
    return std.json.parseFromSlice(Gltf, allocator, bytes, .{ .ignore_unknown_fields = true });
}

const testing = std.testing;

test "asset only" {
    const json =
        \\{"asset":{"version":"2.0","generator":"x","minVersion":"2.0","copyright":"c"}}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectEqualStrings("2.0", p.value.asset.version);
    try testing.expectEqualStrings("x", p.value.asset.generator.?);
    try testing.expectEqualStrings("2.0", p.value.asset.minVersion.?);
    try testing.expectEqualStrings("c", p.value.asset.copyright.?);
}

test "accessor defaults" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "accessors":[{"componentType":5126,"count":3,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const a = p.value.accessors.?[0];
    try testing.expectEqual(@as(u32, 0), a.byteOffset);
    try testing.expectEqual(false, a.normalized);
    try testing.expectEqual(@as(?u32, null), a.bufferView);
    try testing.expectEqual(AccessorType.VEC3, a.type);
}

test "component type byte sizes" {
    try testing.expectEqual(@as(u32, 1), ComponentType.byte.byteSize());
    try testing.expectEqual(@as(u32, 1), ComponentType.unsigned_byte.byteSize());
    try testing.expectEqual(@as(u32, 2), ComponentType.short.byteSize());
    try testing.expectEqual(@as(u32, 2), ComponentType.unsigned_short.byteSize());
    try testing.expectEqual(@as(u32, 4), ComponentType.unsigned_int.byteSize());
    try testing.expectEqual(@as(u32, 4), ComponentType.float.byteSize());
}

test "accessor type component counts" {
    try testing.expectEqual(@as(u32, 1), AccessorType.SCALAR.componentCount());
    try testing.expectEqual(@as(u32, 2), AccessorType.VEC2.componentCount());
    try testing.expectEqual(@as(u32, 3), AccessorType.VEC3.componentCount());
    try testing.expectEqual(@as(u32, 4), AccessorType.VEC4.componentCount());
    try testing.expectEqual(@as(u32, 4), AccessorType.MAT2.componentCount());
    try testing.expectEqual(@as(u32, 9), AccessorType.MAT3.componentCount());
    try testing.expectEqual(@as(u32, 16), AccessorType.MAT4.componentCount());
}

test "sparse accessor" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "accessors":[{
        \\   "componentType":5126,"count":10,"type":"VEC3",
        \\   "sparse":{
        \\     "count":2,
        \\     "indices":{"bufferView":0,"componentType":5123},
        \\     "values":{"bufferView":1}}}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const s = p.value.accessors.?[0].sparse.?;
    try testing.expectEqual(@as(u32, 2), s.count);
    try testing.expectEqual(@as(u32, 0), s.indices.bufferView);
    try testing.expectEqual(@as(u32, 5123), s.indices.componentType);
    try testing.expectEqual(@as(u32, 1), s.values.bufferView);
}

test "parse Triangle sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/Triangle/glTF/Triangle.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    try testing.expectEqualStrings("2.0", p.value.asset.version);
    try testing.expectEqual(@as(usize, 1), p.value.buffers.?.len);
    try testing.expectEqual(@as(u64, 44), p.value.buffers.?[0].byteLength);
    try testing.expectEqualStrings("Triangle.bin", p.value.buffers.?[0].uri.?);
    try testing.expectEqual(@as(usize, 2), p.value.bufferViews.?.len);
    try testing.expectEqual(@as(usize, 2), p.value.accessors.?.len);
    try testing.expectEqual(AccessorType.SCALAR, p.value.accessors.?[0].type);
    try testing.expectEqual(AccessorType.VEC3, p.value.accessors.?[1].type);
}
