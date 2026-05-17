const std = @import("std");

pub const Extras = std.json.Value;
pub const Extensions = std.json.ArrayHashMap(std.json.Value);

pub const Asset = struct {
    version: []const u8,
    minVersion: ?[]const u8 = null,
    generator: ?[]const u8 = null,
    copyright: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
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
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const BufferView = struct {
    buffer: u32,
    byteOffset: u32 = 0,
    byteLength: u64,
    byteStride: ?u32 = null,
    target: ?u32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const SparseIndices = struct {
    bufferView: u32,
    byteOffset: u32 = 0,
    componentType: u32,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const SparseValues = struct {
    bufferView: u32,
    byteOffset: u32 = 0,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Sparse = struct {
    count: u32,
    indices: SparseIndices,
    values: SparseValues,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
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
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const CameraKind = enum { perspective, orthographic };

pub const PerspectiveCamera = struct {
    aspectRatio: ?f32 = null,
    yfov: f32,
    zfar: ?f32 = null,
    znear: f32,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const OrthographicCamera = struct {
    xmag: f32,
    ymag: f32,
    zfar: f32,
    znear: f32,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Camera = struct {
    type: CameraKind,
    perspective: ?PerspectiveCamera = null,
    orthographic: ?OrthographicCamera = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Skin = struct {
    inverseBindMatrices: ?u32 = null,
    skeleton: ?u32 = null,
    joints: []u32,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Interpolation = enum { LINEAR, STEP, CUBICSPLINE };

pub const AnimationPathCore = enum { translation, rotation, scale, weights };

pub const AnimationTarget = struct {
    node: ?u32 = null,
    path: []const u8,
    extensions: ?Extensions = null,
    extras: ?Extras = null,

    pub fn coreKind(self: AnimationTarget) ?AnimationPathCore {
        return std.meta.stringToEnum(AnimationPathCore, self.path);
    }
};

pub const AnimationChannel = struct {
    sampler: u32,
    target: AnimationTarget,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const AnimationSampler = struct {
    input: u32,
    output: u32,
    interpolation: Interpolation = .LINEAR,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Animation = struct {
    channels: []AnimationChannel,
    samplers: []AnimationSampler,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Image = struct {
    uri: ?[]const u8 = null,
    mimeType: ?[]const u8 = null,
    bufferView: ?u32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Sampler = struct {
    magFilter: ?u32 = null,
    minFilter: ?u32 = null,
    wrapS: u32 = 10497,
    wrapT: u32 = 10497,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Texture = struct {
    sampler: ?u32 = null,
    source: ?u32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const TextureInfo = struct {
    index: u32,
    texCoord: u32 = 0,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const NormalTextureInfo = struct {
    index: u32,
    texCoord: u32 = 0,
    scale: f32 = 1,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const OcclusionTextureInfo = struct {
    index: u32,
    texCoord: u32 = 0,
    strength: f32 = 1,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const PbrMetallicRoughness = struct {
    baseColorFactor: [4]f32 = .{ 1, 1, 1, 1 },
    baseColorTexture: ?TextureInfo = null,
    metallicFactor: f32 = 1,
    roughnessFactor: f32 = 1,
    metallicRoughnessTexture: ?TextureInfo = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const AlphaMode = enum { OPAQUE, MASK, BLEND };

pub const Material = struct {
    pbrMetallicRoughness: ?PbrMetallicRoughness = null,
    normalTexture: ?NormalTextureInfo = null,
    occlusionTexture: ?OcclusionTextureInfo = null,
    emissiveTexture: ?TextureInfo = null,
    emissiveFactor: [3]f32 = .{ 0, 0, 0 },
    alphaMode: AlphaMode = .OPAQUE,
    alphaCutoff: f32 = 0.5,
    doubleSided: bool = false,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const PrimitiveMode = enum(u32) {
    points = 0,
    lines = 1,
    line_loop = 2,
    line_strip = 3,
    triangles = 4,
    triangle_strip = 5,
    triangle_fan = 6,
};

pub const Attributes = std.json.ArrayHashMap(u32);

pub const Primitive = struct {
    attributes: Attributes,
    indices: ?u32 = null,
    material: ?u32 = null,
    mode: u32 = @intFromEnum(PrimitiveMode.triangles),
    targets: ?[]Attributes = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Mesh = struct {
    primitives: []Primitive,
    weights: ?[]f32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Scene = struct {
    nodes: ?[]u32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const Node = struct {
    children: ?[]u32 = null,
    mesh: ?u32 = null,
    camera: ?u32 = null,
    skin: ?u32 = null,
    matrix: ?[16]f32 = null,
    translation: ?[3]f32 = null,
    rotation: ?[4]f32 = null,
    scale: ?[3]f32 = null,
    weights: ?[]f32 = null,
    name: ?[]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,

    pub fn effectiveTranslation(self: Node) [3]f32 {
        return self.translation orelse .{ 0, 0, 0 };
    }

    pub fn effectiveRotation(self: Node) [4]f32 {
        return self.rotation orelse .{ 0, 0, 0, 1 };
    }

    pub fn effectiveScale(self: Node) [3]f32 {
        return self.scale orelse .{ 1, 1, 1 };
    }
};

pub const Gltf = struct {
    asset: Asset,
    scene: ?u32 = null,
    scenes: ?[]Scene = null,
    nodes: ?[]Node = null,
    meshes: ?[]Mesh = null,
    materials: ?[]Material = null,
    textures: ?[]Texture = null,
    samplers: ?[]Sampler = null,
    images: ?[]Image = null,
    cameras: ?[]Camera = null,
    skins: ?[]Skin = null,
    animations: ?[]Animation = null,
    buffers: ?[]Buffer = null,
    bufferViews: ?[]BufferView = null,
    accessors: ?[]Accessor = null,
    extensionsUsed: ?[][]const u8 = null,
    extensionsRequired: ?[][]const u8 = null,
    extensions: ?Extensions = null,
    extras: ?Extras = null,
};

pub const ParseError = std.json.ParseError(std.json.Scanner);

pub fn parseSlice(allocator: std.mem.Allocator, bytes: []const u8) ParseError!std.json.Parsed(Gltf) {
    return std.json.parseFromSlice(Gltf, allocator, bytes, .{ .ignore_unknown_fields = true });
}

pub const glb_magic: u32 = 0x46546C67;
const json_chunk: u32 = 0x4E4F534A;
const bin_chunk: u32 = 0x004E4942;

pub const Glb = struct {
    version: u32,
    json: []const u8,
    bin: ?[]const u8,
};

pub const GlbError = error{
    Truncated,
    BadMagic,
    UnsupportedVersion,
    MissingJsonChunk,
    BadChunkLength,
};

pub fn parseGlb(bytes: []const u8) GlbError!Glb {
    if (bytes.len < 12) return error.Truncated;
    const magic = std.mem.readInt(u32, bytes[0..4], .little);
    const version = std.mem.readInt(u32, bytes[4..8], .little);
    const total = std.mem.readInt(u32, bytes[8..12], .little);
    if (magic != glb_magic) return error.BadMagic;
    if (version != 2) return error.UnsupportedVersion;
    if (total > bytes.len) return error.Truncated;

    var off: usize = 12;
    if (off + 8 > total) return error.MissingJsonChunk;
    const c0_len = std.mem.readInt(u32, bytes[off..][0..4], .little);
    const c0_type = std.mem.readInt(u32, bytes[off + 4 ..][0..4], .little);
    off += 8;
    if (c0_type != json_chunk) return error.MissingJsonChunk;
    if (off + c0_len > total) return error.BadChunkLength;
    const json_bytes = bytes[off .. off + c0_len];
    off += c0_len;

    var bin_bytes: ?[]const u8 = null;
    if (off < total) {
        if (off + 8 > total) return error.BadChunkLength;
        const c1_len = std.mem.readInt(u32, bytes[off..][0..4], .little);
        const c1_type = std.mem.readInt(u32, bytes[off + 4 ..][0..4], .little);
        off += 8;
        if (c1_type == bin_chunk) {
            if (off + c1_len > total) return error.BadChunkLength;
            bin_bytes = bytes[off .. off + c1_len];
        }
    }

    return .{ .version = version, .json = json_bytes, .bin = bin_bytes };
}

pub const LoadedGlb = struct {
    parsed: std.json.Parsed(Gltf),
    bin: ?[]const u8,

    pub fn deinit(self: *LoadedGlb) void {
        self.parsed.deinit();
    }

    pub fn value(self: *const LoadedGlb) *const Gltf {
        return &self.parsed.value;
    }
};

pub fn parseGlbSlice(allocator: std.mem.Allocator, bytes: []const u8) (GlbError || ParseError)!LoadedGlb {
    const glb = try parseGlb(bytes);
    const parsed = try parseSlice(allocator, glb.json);
    return .{ .parsed = parsed, .bin = glb.bin };
}

pub fn isDataUri(uri: []const u8) bool {
    return std.mem.startsWith(u8, uri, "data:");
}

pub const DataUriError = error{ MalformedDataUri, InvalidBase64 } || std.mem.Allocator.Error;

pub fn decodeDataUri(allocator: std.mem.Allocator, uri: []const u8) DataUriError![]u8 {
    const marker = ";base64,";
    const idx = std.mem.indexOf(u8, uri, marker) orelse return error.MalformedDataUri;
    const b64 = uri[idx + marker.len ..];
    const decoded_len = std.base64.standard.Decoder.calcSizeForSlice(b64) catch return error.InvalidBase64;
    const out = try allocator.alloc(u8, decoded_len);
    errdefer allocator.free(out);
    std.base64.standard.Decoder.decode(out, b64) catch return error.InvalidBase64;
    return out;
}

pub const LoadUriError = DataUriError || std.Io.Dir.ReadFileAllocError;

pub fn loadUri(
    allocator: std.mem.Allocator,
    io: std.Io,
    base_dir: std.Io.Dir,
    uri: []const u8,
) LoadUriError![]u8 {
    if (isDataUri(uri)) return decodeDataUri(allocator, uri);
    return base_dir.readFileAlloc(io, uri, allocator, .unlimited);
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

test "node TRS defaults" {
    const json =
        \\{"asset":{"version":"2.0"},"nodes":[{}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const n = p.value.nodes.?[0];
    try testing.expectEqual([3]f32{ 0, 0, 0 }, n.effectiveTranslation());
    try testing.expectEqual([4]f32{ 0, 0, 0, 1 }, n.effectiveRotation());
    try testing.expectEqual([3]f32{ 1, 1, 1 }, n.effectiveScale());
    try testing.expectEqual(@as(?[16]f32, null), n.matrix);
}

test "node TRS explicit" {
    const json =
        \\{"asset":{"version":"2.0"},"nodes":[{
        \\  "translation":[1,2,3],
        \\  "rotation":[0,0,0.7071,0.7071],
        \\  "scale":[2,2,2],
        \\  "children":[1,2],
        \\  "mesh":0}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const n = p.value.nodes.?[0];
    try testing.expectEqual([3]f32{ 1, 2, 3 }, n.effectiveTranslation());
    try testing.expectEqual([3]f32{ 2, 2, 2 }, n.effectiveScale());
    try testing.expectEqual(@as(u32, 0), n.mesh.?);
    try testing.expectEqualSlices(u32, &.{ 1, 2 }, n.children.?);
}

test "node matrix" {
    const json =
        \\{"asset":{"version":"2.0"},"nodes":[{
        \\  "matrix":[1,0,0,0, 0,1,0,0, 0,0,1,0, 5,6,7,1]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const m = p.value.nodes.?[0].matrix.?;
    try testing.expectEqual(@as(f32, 5), m[12]);
    try testing.expectEqual(@as(f32, 6), m[13]);
    try testing.expectEqual(@as(f32, 7), m[14]);
}

test "scenes" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "scene":0,
        \\ "scenes":[{"nodes":[0,1],"name":"main"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectEqual(@as(u32, 0), p.value.scene.?);
    try testing.expectEqualSlices(u32, &.{ 0, 1 }, p.value.scenes.?[0].nodes.?);
    try testing.expectEqualStrings("main", p.value.scenes.?[0].name.?);
}

test "mesh primitive defaults" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "meshes":[{"primitives":[{"attributes":{"POSITION":0}}]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const prim = p.value.meshes.?[0].primitives[0];
    try testing.expectEqual(@as(u32, @intFromEnum(PrimitiveMode.triangles)), prim.mode);
    try testing.expectEqual(@as(?u32, null), prim.indices);
    try testing.expectEqual(@as(usize, 1), prim.attributes.map.count());
    try testing.expectEqual(@as(u32, 0), prim.attributes.map.get("POSITION").?);
}

test "mesh primitive full" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "meshes":[{"primitives":[{
        \\   "attributes":{"POSITION":1,"NORMAL":2,"TEXCOORD_0":3},
        \\   "indices":0,"material":0,"mode":1}]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const prim = p.value.meshes.?[0].primitives[0];
    try testing.expectEqual(@as(u32, 1), prim.mode);
    try testing.expectEqual(@as(u32, 0), prim.indices.?);
    try testing.expectEqual(@as(u32, 0), prim.material.?);
    try testing.expectEqual(@as(usize, 3), prim.attributes.map.count());
    try testing.expectEqual(@as(u32, 1), prim.attributes.map.get("POSITION").?);
    try testing.expectEqual(@as(u32, 2), prim.attributes.map.get("NORMAL").?);
    try testing.expectEqual(@as(u32, 3), prim.attributes.map.get("TEXCOORD_0").?);
}

test "mesh morph targets" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "meshes":[{"primitives":[{
        \\   "attributes":{"POSITION":0},
        \\   "targets":[{"POSITION":1},{"POSITION":2}]}],
        \\  "weights":[0.5,0.25]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const m = p.value.meshes.?[0];
    try testing.expectEqual(@as(usize, 2), m.primitives[0].targets.?.len);
    try testing.expectEqual(@as(u32, 1), m.primitives[0].targets.?[0].map.get("POSITION").?);
    try testing.expectEqualSlices(f32, &.{ 0.5, 0.25 }, m.weights.?);
}

test "material defaults" {
    const json =
        \\{"asset":{"version":"2.0"},"materials":[{}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const m = p.value.materials.?[0];
    try testing.expectEqual([3]f32{ 0, 0, 0 }, m.emissiveFactor);
    try testing.expectEqual(AlphaMode.OPAQUE, m.alphaMode);
    try testing.expectEqual(@as(f32, 0.5), m.alphaCutoff);
    try testing.expectEqual(false, m.doubleSided);
    try testing.expectEqual(@as(?PbrMetallicRoughness, null), m.pbrMetallicRoughness);
}

test "material full pbr" {
    const json =
        \\{"asset":{"version":"2.0"},"materials":[{
        \\  "pbrMetallicRoughness":{
        \\    "baseColorFactor":[0.5,0.6,0.7,1.0],
        \\    "baseColorTexture":{"index":0,"texCoord":1},
        \\    "metallicFactor":0.0,
        \\    "roughnessFactor":0.8,
        \\    "metallicRoughnessTexture":{"index":1}},
        \\  "normalTexture":{"index":2,"scale":2.0},
        \\  "occlusionTexture":{"index":3,"strength":0.5},
        \\  "emissiveTexture":{"index":4},
        \\  "emissiveFactor":[1,0.5,0.25],
        \\  "alphaMode":"BLEND",
        \\  "alphaCutoff":0.25,
        \\  "doubleSided":true}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const m = p.value.materials.?[0];
    const pbr = m.pbrMetallicRoughness.?;
    try testing.expectEqual([4]f32{ 0.5, 0.6, 0.7, 1.0 }, pbr.baseColorFactor);
    try testing.expectEqual(@as(u32, 0), pbr.baseColorTexture.?.index);
    try testing.expectEqual(@as(u32, 1), pbr.baseColorTexture.?.texCoord);
    try testing.expectEqual(@as(f32, 0.0), pbr.metallicFactor);
    try testing.expectEqual(@as(f32, 0.8), pbr.roughnessFactor);
    try testing.expectEqual(@as(f32, 2.0), m.normalTexture.?.scale);
    try testing.expectEqual(@as(f32, 0.5), m.occlusionTexture.?.strength);
    try testing.expectEqual([3]f32{ 1, 0.5, 0.25 }, m.emissiveFactor);
    try testing.expectEqual(AlphaMode.BLEND, m.alphaMode);
    try testing.expectEqual(@as(f32, 0.25), m.alphaCutoff);
    try testing.expectEqual(true, m.doubleSided);
}

test "alpha modes" {
    inline for (.{ "OPAQUE", "MASK", "BLEND" }, .{ AlphaMode.OPAQUE, AlphaMode.MASK, AlphaMode.BLEND }) |s, want| {
        const json = "{\"asset\":{\"version\":\"2.0\"},\"materials\":[{\"alphaMode\":\"" ++ s ++ "\"}]}";
        var p = try parseSlice(testing.allocator, json);
        defer p.deinit();
        try testing.expectEqual(want, p.value.materials.?[0].alphaMode);
    }
}

test "sampler defaults" {
    const json =
        \\{"asset":{"version":"2.0"},"samplers":[{}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const s = p.value.samplers.?[0];
    try testing.expectEqual(@as(u32, 10497), s.wrapS);
    try testing.expectEqual(@as(u32, 10497), s.wrapT);
    try testing.expectEqual(@as(?u32, null), s.magFilter);
}

test "image bufferView" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "images":[{"bufferView":0,"mimeType":"image/png"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const im = p.value.images.?[0];
    try testing.expectEqual(@as(u32, 0), im.bufferView.?);
    try testing.expectEqualStrings("image/png", im.mimeType.?);
}

test "parse BoxTextured sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/BoxTextured/glTF/BoxTextured.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    try testing.expectEqual(@as(usize, 1), p.value.materials.?.len);
    const pbr = p.value.materials.?[0].pbrMetallicRoughness.?;
    try testing.expectEqual(@as(u32, 0), pbr.baseColorTexture.?.index);
    try testing.expectEqual(@as(f32, 0.0), pbr.metallicFactor);
    try testing.expectEqual(@as(usize, 1), p.value.textures.?.len);
    try testing.expectEqual(@as(u32, 0), p.value.textures.?[0].sampler.?);
    try testing.expectEqual(@as(u32, 0), p.value.textures.?[0].source.?);
    try testing.expectEqualStrings("CesiumLogoFlat.png", p.value.images.?[0].uri.?);
    try testing.expectEqual(@as(?u32, 9729), p.value.samplers.?[0].magFilter);
    try testing.expectEqual(@as(?u32, 9986), p.value.samplers.?[0].minFilter);
}

test "extensionsUsed / extensionsRequired" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "extensionsUsed":["KHR_animation_pointer","KHR_lights_punctual"],
        \\ "extensionsRequired":["KHR_animation_pointer"]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectEqual(@as(usize, 2), p.value.extensionsUsed.?.len);
    try testing.expectEqualStrings("KHR_animation_pointer", p.value.extensionsUsed.?[0]);
    try testing.expectEqualStrings("KHR_lights_punctual", p.value.extensionsUsed.?[1]);
    try testing.expectEqualStrings("KHR_animation_pointer", p.value.extensionsRequired.?[0]);
}

test "extensions passthrough" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "nodes":[{"extensions":{"KHR_lights_punctual":{"light":3}}}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const ext = p.value.nodes.?[0].extensions.?;
    const v = ext.map.get("KHR_lights_punctual").?;
    const light = v.object.get("light").?;
    try testing.expectEqual(@as(i64, 3), light.integer);
}

test "extras passthrough" {
    const json =
        \\{"asset":{"version":"2.0","extras":{"note":"hello","count":42}}}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const x = p.value.asset.extras.?;
    try testing.expectEqualStrings("hello", x.object.get("note").?.string);
    try testing.expectEqual(@as(i64, 42), x.object.get("count").?.integer);
}

test "decode data uri" {
    const uri = "data:application/octet-stream;base64,aGVsbG8=";
    const bytes = try decodeDataUri(testing.allocator, uri);
    defer testing.allocator.free(bytes);
    try testing.expectEqualStrings("hello", bytes);
}

test "data uri detection" {
    try testing.expect(isDataUri("data:foo;base64,xx"));
    try testing.expect(!isDataUri("Triangle.bin"));
    try testing.expect(!isDataUri(""));
}

test "data uri malformed" {
    try testing.expectError(error.MalformedDataUri, decodeDataUri(testing.allocator, "data:foo,nope"));
}

test "load embedded buffer" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/Box/glTF-Embedded/Box.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    const buf = p.value.buffers.?[0];
    try testing.expect(isDataUri(buf.uri.?));
    const data = try decodeDataUri(testing.allocator, buf.uri.?);
    defer testing.allocator.free(data);
    try testing.expectEqual(@as(usize, buf.byteLength), data.len);
}

test "load external buffer" {
    var dir = try std.Io.Dir.cwd().openDir(std.testing.io, "test-assets/Models/Triangle/glTF", .{});
    defer dir.close(std.testing.io);
    const data = try loadUri(testing.allocator, std.testing.io, dir, "Triangle.bin");
    defer testing.allocator.free(data);
    try testing.expectEqual(@as(usize, 44), data.len);
}

test "glb bad magic" {
    const bytes = [_]u8{0} ** 12;
    try testing.expectError(error.BadMagic, parseGlb(&bytes));
}

test "glb truncated" {
    const bytes = [_]u8{0} ** 8;
    try testing.expectError(error.Truncated, parseGlb(&bytes));
}

test "parse Box.glb" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/Box/glTF-Binary/Box.glb",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var loaded = try parseGlbSlice(testing.allocator, bytes);
    defer loaded.deinit();
    try testing.expectEqualStrings("2.0", loaded.value().asset.version);
    try testing.expect(loaded.bin != null);
    try testing.expect(loaded.value().meshes.?.len >= 1);
}

test "perspective camera" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "cameras":[{"type":"perspective",
        \\   "perspective":{"yfov":0.7,"znear":0.1,"zfar":1000,"aspectRatio":1.5}}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const c = p.value.cameras.?[0];
    try testing.expectEqual(CameraKind.perspective, c.type);
    const persp = c.perspective.?;
    try testing.expectEqual(@as(f32, 0.7), persp.yfov);
    try testing.expectEqual(@as(f32, 0.1), persp.znear);
    try testing.expectEqual(@as(f32, 1000), persp.zfar.?);
    try testing.expectEqual(@as(f32, 1.5), persp.aspectRatio.?);
}

test "orthographic camera" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "cameras":[{"type":"orthographic",
        \\   "orthographic":{"xmag":2,"ymag":2,"zfar":100,"znear":0.1}}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const c = p.value.cameras.?[0];
    try testing.expectEqual(CameraKind.orthographic, c.type);
    const ortho = c.orthographic.?;
    try testing.expectEqual(@as(f32, 2), ortho.xmag);
    try testing.expectEqual(@as(f32, 100), ortho.zfar);
}

test "skin" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "skins":[{"inverseBindMatrices":0,"skeleton":1,"joints":[1,2,3]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const s = p.value.skins.?[0];
    try testing.expectEqual(@as(u32, 0), s.inverseBindMatrices.?);
    try testing.expectEqual(@as(u32, 1), s.skeleton.?);
    try testing.expectEqualSlices(u32, &.{ 1, 2, 3 }, s.joints);
}

test "animation defaults" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "animations":[{
        \\   "samplers":[{"input":0,"output":1}],
        \\   "channels":[{"sampler":0,"target":{"node":0,"path":"translation"}}]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const a = p.value.animations.?[0];
    try testing.expectEqual(Interpolation.LINEAR, a.samplers[0].interpolation);
    try testing.expectEqualStrings("translation", a.channels[0].target.path);
    try testing.expectEqual(AnimationPathCore.translation, a.channels[0].target.coreKind().?);
    try testing.expectEqual(@as(u32, 0), a.channels[0].target.node.?);
}

test "animation interpolations" {
    inline for (.{ "LINEAR", "STEP", "CUBICSPLINE" }, .{ Interpolation.LINEAR, Interpolation.STEP, Interpolation.CUBICSPLINE }) |s, want| {
        const json = "{\"asset\":{\"version\":\"2.0\"},\"animations\":[{" ++
            "\"samplers\":[{\"input\":0,\"output\":1,\"interpolation\":\"" ++ s ++ "\"}]," ++
            "\"channels\":[{\"sampler\":0,\"target\":{\"path\":\"weights\"}}]}]}";
        var p = try parseSlice(testing.allocator, json);
        defer p.deinit();
        try testing.expectEqual(want, p.value.animations.?[0].samplers[0].interpolation);
    }
}

test "animation target paths" {
    inline for (.{ "translation", "rotation", "scale", "weights" }, .{ AnimationPathCore.translation, AnimationPathCore.rotation, AnimationPathCore.scale, AnimationPathCore.weights }) |s, want| {
        const json = "{\"asset\":{\"version\":\"2.0\"},\"animations\":[{" ++
            "\"samplers\":[{\"input\":0,\"output\":1}]," ++
            "\"channels\":[{\"sampler\":0,\"target\":{\"path\":\"" ++ s ++ "\"}}]}]}";
        var p = try parseSlice(testing.allocator, json);
        defer p.deinit();
        const t = p.value.animations.?[0].channels[0].target;
        try testing.expectEqualStrings(s, t.path);
        try testing.expectEqual(want, t.coreKind().?);
    }
}

test "animation extension path accepted" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "animations":[{
        \\   "samplers":[{"input":0,"output":1}],
        \\   "channels":[{"sampler":0,"target":{"path":"pointer"}}]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const t = p.value.animations.?[0].channels[0].target;
    try testing.expectEqualStrings("pointer", t.path);
    try testing.expectEqual(@as(?AnimationPathCore, null), t.coreKind());
}

test "parse AnimatedTriangle sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/AnimatedTriangle/glTF/AnimatedTriangle.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    const a = p.value.animations.?[0];
    try testing.expectEqual(@as(usize, 1), a.samplers.len);
    try testing.expectEqual(@as(usize, 1), a.channels.len);
    try testing.expectEqualStrings("rotation", a.channels[0].target.path);
    try testing.expectEqual(Interpolation.LINEAR, a.samplers[0].interpolation);
}

test "parse RiggedSimple sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/RiggedSimple/glTF/RiggedSimple.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    try testing.expect(p.value.skins.?.len >= 1);
    try testing.expect(p.value.animations.?.len >= 1);
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
    try testing.expectEqual(@as(u32, 0), p.value.scene.?);
    try testing.expectEqual(@as(usize, 1), p.value.scenes.?.len);
    try testing.expectEqualSlices(u32, &.{0}, p.value.scenes.?[0].nodes.?);
    try testing.expectEqual(@as(u32, 0), p.value.nodes.?[0].mesh.?);
    try testing.expectEqual(@as(usize, 1), p.value.buffers.?.len);
    try testing.expectEqual(@as(u64, 44), p.value.buffers.?[0].byteLength);
    try testing.expectEqualStrings("Triangle.bin", p.value.buffers.?[0].uri.?);
    try testing.expectEqual(@as(usize, 2), p.value.bufferViews.?.len);
    try testing.expectEqual(@as(usize, 2), p.value.accessors.?.len);
    try testing.expectEqual(AccessorType.SCALAR, p.value.accessors.?[0].type);
    try testing.expectEqual(AccessorType.VEC3, p.value.accessors.?[1].type);
    try testing.expectEqual(@as(usize, 1), p.value.meshes.?.len);
    const prim = p.value.meshes.?[0].primitives[0];
    try testing.expectEqual(@as(u32, 1), prim.attributes.map.get("POSITION").?);
    try testing.expectEqual(@as(u32, 0), prim.indices.?);
}
