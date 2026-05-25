const std = @import("std");

pub const image = @import("image.zig");

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

    pub fn fromInt(v: u32) error{UnknownAccessorComponentType}!ComponentType {
        return switch (v) {
            5120 => .byte,
            5121 => .unsigned_byte,
            5122 => .short,
            5123 => .unsigned_short,
            5125 => .unsigned_int,
            5126 => .float,
            else => error.UnknownAccessorComponentType,
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

    pub fn elementSize(a: *const @This()) error{UnknownAccessorComponentType}!u64 {
        const ct = try ComponentType.fromInt(a.componentType);
        return @as(u64, ct.byteSize()) * a.type.componentCount();
    }

    pub fn bytes(a: *const @This(), gltf: *const Gltf, buffers: []const []const u8) AccessorReadError![]const u8 {
        if (a.sparse != null) return error.SparseNotSupported;
        const bv_idx = a.bufferView orelse return error.NoBufferView;
        const bvs = gltf.bufferViews orelse return error.BadBufferViewRef;
        if (bv_idx >= bvs.len) return error.BadBufferViewRef;
        const bv = bvs[bv_idx];
        if (bv.buffer >= buffers.len) return error.BufferIndexOutOfBounds;
        const buf = buffers[bv.buffer];
        const elem = try a.elementSize();
        const stride: u64 = if (bv.byteStride) |s| s else elem;
        const start = @as(u64, bv.byteOffset) + @as(u64, a.byteOffset);
        const total: u64 = if (a.count == 0) 0 else (@as(u64, a.count - 1) * stride + elem);
        if (start + total > buf.len) return error.BufferOutOfBounds;
        return buf[@intCast(start)..@intCast(start + total)];
    }

    pub fn asSlice(a: *const @This(), comptime T: type, gltf: *const Gltf, buffers: []const []const u8) AccessorReadError![]align(1) const T {
        const elem = try a.elementSize();
        if (@sizeOf(T) != elem) return error.ComponentTypeMismatch;
        const bv_idx = a.bufferView orelse return error.NoBufferView;
        const bvs = gltf.bufferViews orelse return error.BadBufferViewRef;
        if (bv_idx >= bvs.len) return error.BadBufferViewRef;
        const bv = bvs[bv_idx];
        if (bv.byteStride) |s| if (s != elem) return error.StrideMismatch;
        const raw = try a.bytes(gltf, buffers);
        return std.mem.bytesAsSlice(T, raw);
    }

    pub fn readIndicesU32(a: *const @This(), gltf: *const Gltf, buffers: []const []const u8, out: []u32) AccessorReadError!void {
        if (a.type != .SCALAR) return error.ComponentTypeMismatch;
        if (out.len < a.count) return error.BufferOutOfBounds;
        const ct = try ComponentType.fromInt(a.componentType);
        switch (ct) {
            .unsigned_byte => {
                var it = try a.iterator(u8, gltf, buffers);
                var i: u32 = 0;
                while (it.next()) |v| : (i += 1) out[i] = v;
            },
            .unsigned_short => {
                var it = try a.iterator(u16, gltf, buffers);
                var i: u32 = 0;
                while (it.next()) |v| : (i += 1) out[i] = v;
            },
            .unsigned_int => {
                var it = try a.iterator(u32, gltf, buffers);
                var i: u32 = 0;
                while (it.next()) |v| : (i += 1) out[i] = v;
            },
            else => return error.ComponentTypeMismatch,
        }
    }

    pub fn iterator(a: *const @This(), comptime T: type, gltf: *const Gltf, buffers: []const []const u8) AccessorReadError!AccessorIter(T) {
        const elem = try a.elementSize();
        if (@sizeOf(T) != elem) return error.ComponentTypeMismatch;
        const bv_idx = a.bufferView orelse return error.NoBufferView;
        const bvs = gltf.bufferViews orelse return error.BadBufferViewRef;
        if (bv_idx >= bvs.len) return error.BadBufferViewRef;
        const bv = bvs[bv_idx];
        const stride: u64 = if (bv.byteStride) |s| s else elem;
        const raw = try a.bytes(gltf, buffers);
        return .{ .buffer = raw, .stride = stride, .count = a.count };
    }
};

pub const AccessorReadError = error{
    NoBufferView,
    SparseNotSupported,
    StrideMismatch,
    ComponentTypeMismatch,
    BufferIndexOutOfBounds,
    BufferOutOfBounds,
    BadBufferViewRef,
    UnknownAccessorComponentType,
};

pub fn AccessorIter(comptime T: type) type {
    return struct {
        buffer: []const u8,
        stride: u64,
        count: u32,
        i: u32 = 0,

        pub fn next(self: *@This()) ?T {
            if (self.i >= self.count) return null;
            const off: usize = @intCast(@as(u64, self.i) * self.stride);
            self.i += 1;
            var out: T = undefined;
            @memcpy(std.mem.asBytes(&out), self.buffer[off .. off + @sizeOf(T)]);
            return out;
        }

        pub fn reset(self: *@This()) void {
            self.i = 0;
        }
    };
}

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

fn intToEnumChecked(comptime E: type, raw: u32) !E {
    inline for (@typeInfo(E).@"enum".fields) |field| {
        if (field.value == raw) return @field(E, field.name);
    }
    return error.UnexpectedToken;
}

pub const MagFilter = enum(u32) {
    nearest = 9728,
    linear = 9729,

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !MagFilter {
        const raw = try std.json.innerParse(u32, allocator, source, options);
        return intToEnumChecked(MagFilter, raw);
    }

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !MagFilter {
        const raw = try std.json.innerParseFromValue(u32, allocator, source, options);
        return intToEnumChecked(MagFilter, raw);
    }

    pub fn jsonStringify(self: MagFilter, jws: anytype) !void {
        try jws.write(@intFromEnum(self));
    }
};

pub const MinFilter = enum(u32) {
    nearest = 9728,
    linear = 9729,
    nearest_mipmap_nearest = 9984,
    linear_mipmap_nearest = 9985,
    nearest_mipmap_linear = 9986,
    linear_mipmap_linear = 9987,

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !MinFilter {
        const raw = try std.json.innerParse(u32, allocator, source, options);
        return intToEnumChecked(MinFilter, raw);
    }

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !MinFilter {
        const raw = try std.json.innerParseFromValue(u32, allocator, source, options);
        return intToEnumChecked(MinFilter, raw);
    }

    pub fn jsonStringify(self: MinFilter, jws: anytype) !void {
        try jws.write(@intFromEnum(self));
    }
};

pub const WrapMode = enum(u32) {
    clamp_to_edge = 33071,
    mirrored_repeat = 33648,
    repeat = 10497,

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !WrapMode {
        const raw = try std.json.innerParse(u32, allocator, source, options);
        return intToEnumChecked(WrapMode, raw);
    }

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !WrapMode {
        const raw = try std.json.innerParseFromValue(u32, allocator, source, options);
        return intToEnumChecked(WrapMode, raw);
    }

    pub fn jsonStringify(self: WrapMode, jws: anytype) !void {
        try jws.write(@intFromEnum(self));
    }
};

pub const Sampler = struct {
    magFilter: ?MagFilter = null,
    minFilter: ?MinFilter = null,
    wrapS: WrapMode = .repeat,
    wrapT: WrapMode = .repeat,
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

pub const ValidationError = error{
    BadSceneRef,
    BadNodeRef,
    BadMeshRef,
    BadCameraRef,
    BadSkinRef,
    BadAccessorRef,
    BadBufferViewRef,
    BadBufferRef,
    BadMaterialRef,
    BadTextureRef,
    BadImageRef,
    BadSamplerRef,
    BadAnimationSamplerRef,
    AccessorOutOfBounds,
    BufferViewOutOfBounds,
    UnknownAccessorComponentType,
    EmptyPrimitives,
    EmptyJoints,
    EmptyAnimationChannels,
    EmptyAnimationSamplers,
    CameraMissingBlock,
    AccessorMinMaxLengthMismatch,
    BadCameraKind,
};

fn countOf(opt: anytype) usize {
    return if (opt) |s| s.len else 0;
}

fn checkIdx(idx: u32, n: usize, err: ValidationError) ValidationError!void {
    if (idx >= n) return err;
}

pub fn validate(g: *const Gltf) ValidationError!void {
    const n_nodes = countOf(g.nodes);
    const n_meshes = countOf(g.meshes);
    const n_cameras = countOf(g.cameras);
    const n_skins = countOf(g.skins);
    const n_materials = countOf(g.materials);
    const n_textures = countOf(g.textures);
    const n_samplers = countOf(g.samplers);
    const n_images = countOf(g.images);
    const n_accessors = countOf(g.accessors);
    const n_buffer_views = countOf(g.bufferViews);
    const n_buffers = countOf(g.buffers);
    const n_scenes = countOf(g.scenes);

    if (g.scene) |s| try checkIdx(s, n_scenes, error.BadSceneRef);

    if (g.scenes) |scenes| for (scenes) |sc| {
        if (sc.nodes) |ns| for (ns) |i| try checkIdx(i, n_nodes, error.BadNodeRef);
    };

    if (g.nodes) |nodes| for (nodes) |nd| {
        if (nd.children) |ch| for (ch) |i| try checkIdx(i, n_nodes, error.BadNodeRef);
        if (nd.mesh) |i| try checkIdx(i, n_meshes, error.BadMeshRef);
        if (nd.camera) |i| try checkIdx(i, n_cameras, error.BadCameraRef);
        if (nd.skin) |i| try checkIdx(i, n_skins, error.BadSkinRef);
    };

    if (g.meshes) |meshes| for (meshes) |m| {
        if (m.primitives.len == 0) return error.EmptyPrimitives;
    };

    if (g.meshes) |meshes| for (meshes) |m| for (m.primitives) |prim| {
        if (prim.indices) |i| try checkIdx(i, n_accessors, error.BadAccessorRef);
        if (prim.material) |i| try checkIdx(i, n_materials, error.BadMaterialRef);
        var it = prim.attributes.map.iterator();
        while (it.next()) |kv| try checkIdx(kv.value_ptr.*, n_accessors, error.BadAccessorRef);
        if (prim.targets) |ts| for (ts) |t| {
            var tit = t.map.iterator();
            while (tit.next()) |kv| try checkIdx(kv.value_ptr.*, n_accessors, error.BadAccessorRef);
        };
    };

    if (g.materials) |mats| for (mats) |m| {
        if (m.pbrMetallicRoughness) |pbr| {
            if (pbr.baseColorTexture) |t| try checkIdx(t.index, n_textures, error.BadTextureRef);
            if (pbr.metallicRoughnessTexture) |t| try checkIdx(t.index, n_textures, error.BadTextureRef);
        }
        if (m.normalTexture) |t| try checkIdx(t.index, n_textures, error.BadTextureRef);
        if (m.occlusionTexture) |t| try checkIdx(t.index, n_textures, error.BadTextureRef);
        if (m.emissiveTexture) |t| try checkIdx(t.index, n_textures, error.BadTextureRef);
    };

    if (g.textures) |txs| for (txs) |t| {
        if (t.sampler) |i| try checkIdx(i, n_samplers, error.BadSamplerRef);
        if (t.source) |i| try checkIdx(i, n_images, error.BadImageRef);
    };

    if (g.images) |imgs| for (imgs) |im| {
        if (im.bufferView) |i| try checkIdx(i, n_buffer_views, error.BadBufferViewRef);
    };

    if (g.skins) |skins| for (skins) |sk| {
        if (sk.joints.len == 0) return error.EmptyJoints;
        if (sk.skeleton) |i| try checkIdx(i, n_nodes, error.BadNodeRef);
        if (sk.inverseBindMatrices) |i| try checkIdx(i, n_accessors, error.BadAccessorRef);
        for (sk.joints) |j| try checkIdx(j, n_nodes, error.BadNodeRef);
    };

    if (g.cameras) |cams| for (cams) |cam| switch (cam.type) {
        .perspective => if (cam.perspective == null) return error.CameraMissingBlock,
        .orthographic => if (cam.orthographic == null) return error.CameraMissingBlock,
    };

    if (g.animations) |anims| for (anims) |a| {
        if (a.channels.len == 0) return error.EmptyAnimationChannels;
        if (a.samplers.len == 0) return error.EmptyAnimationSamplers;
        for (a.channels) |c| {
            try checkIdx(c.sampler, @as(u32, @intCast(a.samplers.len)), error.BadAnimationSamplerRef);
            if (c.target.node) |i| try checkIdx(i, n_nodes, error.BadNodeRef);
        }
        for (a.samplers) |s| {
            try checkIdx(s.input, n_accessors, error.BadAccessorRef);
            try checkIdx(s.output, n_accessors, error.BadAccessorRef);
        }
    };

    if (g.bufferViews) |views| for (views) |v| {
        try checkIdx(v.buffer, n_buffers, error.BadBufferRef);
        const buf = g.buffers.?[v.buffer];
        if (@as(u64, v.byteOffset) + v.byteLength > buf.byteLength) return error.BufferViewOutOfBounds;
    };

    if (g.accessors) |accs| for (accs) |a| {
        const elem_size = try a.elementSize();
        const ncomp = a.type.componentCount();
        if (a.min) |m| if (m.len != ncomp) return error.AccessorMinMaxLengthMismatch;
        if (a.max) |m| if (m.len != ncomp) return error.AccessorMinMaxLengthMismatch;
        if (a.bufferView) |bvi| {
            try checkIdx(bvi, n_buffer_views, error.BadBufferViewRef);
            const bv = g.bufferViews.?[bvi];
            const stride: u64 = if (bv.byteStride) |s| s else elem_size;
            const end = @as(u64, a.byteOffset) + if (a.count == 0) 0 else (@as(u64, a.count - 1) * stride + elem_size);
            if (end > bv.byteLength) return error.AccessorOutOfBounds;
        }
        if (a.sparse) |sp| {
            try checkIdx(sp.indices.bufferView, n_buffer_views, error.BadBufferViewRef);
            try checkIdx(sp.values.bufferView, n_buffer_views, error.BadBufferViewRef);
        }
    };
}

pub fn getTypedExtension(
    comptime T: type,
    allocator: std.mem.Allocator,
    container: ?Extensions,
    name: []const u8,
) !?std.json.Parsed(T) {
    const ext = container orelse return null;
    const value = ext.map.get(name) orelse return null;
    return try std.json.parseFromValue(T, allocator, value, .{ .ignore_unknown_fields = true });
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
    try testing.expectEqual(WrapMode.repeat, s.wrapS);
    try testing.expectEqual(WrapMode.repeat, s.wrapT);
    try testing.expectEqual(@as(?MagFilter, null), s.magFilter);
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
    try testing.expectEqual(MagFilter.linear, p.value.samplers.?[0].magFilter.?);
    try testing.expectEqual(MinFilter.nearest_mipmap_linear, p.value.samplers.?[0].minFilter.?);
}

test "validate Triangle sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/Triangle/glTF/Triangle.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    try validate(&p.value);
}

test "validate BoxTextured sample" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "test-assets/Models/BoxTextured/glTF/BoxTextured.gltf",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(bytes);
    var p = try parseSlice(testing.allocator, bytes);
    defer p.deinit();
    try validate(&p.value);
}

test "validate detects empty primitives" {
    const json =
        \\{"asset":{"version":"2.0"},"meshes":[{"primitives":[]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.EmptyPrimitives, validate(&p.value));
}

test "validate detects empty joints" {
    const json =
        \\{"asset":{"version":"2.0"},"skins":[{"joints":[]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.EmptyJoints, validate(&p.value));
}

test "validate detects camera missing block" {
    const json =
        \\{"asset":{"version":"2.0"},"cameras":[{"type":"perspective"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.CameraMissingBlock, validate(&p.value));
}

test "validate detects min/max length mismatch" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":36}],
        \\ "bufferViews":[{"buffer":0,"byteLength":36}],
        \\ "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.AccessorMinMaxLengthMismatch, validate(&p.value));
}

test "validate detects bad scene ref" {
    const json =
        \\{"asset":{"version":"2.0"},"scene":5,"scenes":[{"nodes":[]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.BadSceneRef, validate(&p.value));
}

test "validate detects bad mesh ref" {
    const json =
        \\{"asset":{"version":"2.0"},"nodes":[{"mesh":2}],"meshes":[{"primitives":[{"attributes":{}}]}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.BadMeshRef, validate(&p.value));
}

test "validate detects accessor out of bounds" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":12}],
        \\ "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":12}],
        \\ "accessors":[{"bufferView":0,"componentType":5126,"count":2,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.AccessorOutOfBounds, validate(&p.value));
}

test "validate detects bufferview out of bounds" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":10}],
        \\ "bufferViews":[{"buffer":0,"byteOffset":4,"byteLength":20}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    try testing.expectError(error.BufferViewOutOfBounds, validate(&p.value));
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

test "accessor asSlice dense" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":36}],
        \\ "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36}],
        \\ "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const verts = [_]f32{ 0, 0, 0, 1, 2, 3, 4, 5, 6 };
    const bin = std.mem.sliceAsBytes(&verts);
    const slice = try p.value.accessors.?[0].asSlice([3]f32, &p.value, &.{bin});
    try testing.expectEqual(@as(usize, 3), slice.len);
    try testing.expectEqual([3]f32{ 1, 2, 3 }, slice[1]);
    try testing.expectEqual([3]f32{ 4, 5, 6 }, slice[2]);
}

test "accessor iterator with stride" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":40}],
        \\ "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":40,"byteStride":20}],
        \\ "accessors":[{"bufferView":0,"componentType":5126,"count":2,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    // interleaved: [pos.xyz, pad, pad] [pos.xyz, pad, pad] (20-byte stride, 12-byte element)
    const raw = [_]f32{ 1, 2, 3, 9, 9, 4, 5, 6, 9, 9 };
    const bin = std.mem.sliceAsBytes(&raw);
    var it = try p.value.accessors.?[0].iterator([3]f32, &p.value, &.{bin});
    try testing.expectEqual([3]f32{ 1, 2, 3 }, it.next().?);
    try testing.expectEqual([3]f32{ 4, 5, 6 }, it.next().?);
    try testing.expectEqual(@as(?[3]f32, null), it.next());
}

test "accessor bytes error on sparse" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":12}],
        \\ "bufferViews":[{"buffer":0,"byteLength":12}],
        \\ "accessors":[{"componentType":5126,"count":3,"type":"SCALAR",
        \\   "sparse":{"count":1,
        \\     "indices":{"bufferView":0,"componentType":5123},
        \\     "values":{"bufferView":0}}}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const bin = [_]u8{0} ** 12;
    try testing.expectError(error.SparseNotSupported, p.value.accessors.?[0].bytes(&p.value, &.{&bin}));
}

test "accessor asSlice rejects stride mismatch" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":40}],
        \\ "bufferViews":[{"buffer":0,"byteLength":40,"byteStride":20}],
        \\ "accessors":[{"bufferView":0,"componentType":5126,"count":2,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const bin = [_]u8{0} ** 40;
    try testing.expectError(error.StrideMismatch, p.value.accessors.?[0].asSlice([3]f32, &p.value, &.{&bin}));
}

test "accessor readIndicesU32 from u16" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":8}],
        \\ "bufferViews":[{"buffer":0,"byteLength":8}],
        \\ "accessors":[{"bufferView":0,"componentType":5123,"count":4,"type":"SCALAR"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const indices = [_]u16{ 10, 20, 30, 65535 };
    const bin = std.mem.sliceAsBytes(&indices);
    var out: [4]u32 = undefined;
    try p.value.accessors.?[0].readIndicesU32(&p.value, &.{bin}, &out);
    try testing.expectEqualSlices(u32, &.{ 10, 20, 30, 65535 }, &out);
}

test "accessor readIndicesU32 from u8" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":3}],
        \\ "bufferViews":[{"buffer":0,"byteLength":3}],
        \\ "accessors":[{"bufferView":0,"componentType":5121,"count":3,"type":"SCALAR"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const indices = [_]u8{ 1, 2, 255 };
    var out: [3]u32 = undefined;
    try p.value.accessors.?[0].readIndicesU32(&p.value, &.{&indices}, &out);
    try testing.expectEqualSlices(u32, &.{ 1, 2, 255 }, &out);
}

test "accessor readIndicesU32 rejects non-scalar" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "buffers":[{"byteLength":24}],
        \\ "bufferViews":[{"buffer":0,"byteLength":24}],
        \\ "accessors":[{"bufferView":0,"componentType":5123,"count":2,"type":"VEC3"}]}
    ;
    var p = try parseSlice(testing.allocator, json);
    defer p.deinit();
    const bin = [_]u8{0} ** 24;
    var out: [2]u32 = undefined;
    try testing.expectError(error.ComponentTypeMismatch, p.value.accessors.?[0].readIndicesU32(&p.value, &.{&bin}, &out));
}
