const std = @import("std");
const zgltf = @import("zgltf");

pub const lights_punctual_name = "KHR_lights_punctual";
pub const unlit_name = "KHR_materials_unlit";
pub const clearcoat_name = "KHR_materials_clearcoat";
pub const emissive_strength_name = "KHR_materials_emissive_strength";
pub const ior_name = "KHR_materials_ior";
pub const texture_transform_name = "KHR_texture_transform";
pub const transmission_name = "KHR_materials_transmission";
pub const volume_name = "KHR_materials_volume";
pub const specular_name = "KHR_materials_specular";
pub const sheen_name = "KHR_materials_sheen";
pub const anisotropy_name = "KHR_materials_anisotropy";
pub const iridescence_name = "KHR_materials_iridescence";
pub const dispersion_name = "KHR_materials_dispersion";
pub const variants_name = "KHR_materials_variants";
pub const draco_name = "KHR_draco_mesh_compression";
pub const mesh_quantization_name = "KHR_mesh_quantization";
pub const texture_basisu_name = "KHR_texture_basisu";
pub const xmp_json_ld_name = "KHR_xmp_json_ld";
pub const animation_pointer_name = "KHR_animation_pointer";

pub const LightType = enum { directional, point, spot };

pub const LightSpot = struct {
    innerConeAngle: f32 = 0,
    outerConeAngle: f32 = std.math.pi / 4.0,
};

pub const Light = struct {
    name: ?[]const u8 = null,
    color: [3]f32 = .{ 1, 1, 1 },
    intensity: f32 = 1,
    type: LightType,
    range: ?f32 = null,
    spot: ?LightSpot = null,
};

pub const LightsPunctualTop = struct {
    lights: []Light,
};

pub const LightsPunctualNode = struct {
    light: u32,
};

pub const MaterialsUnlit = struct {};

pub const Clearcoat = struct {
    clearcoatFactor: f32 = 0,
    clearcoatTexture: ?zgltf.TextureInfo = null,
    clearcoatRoughnessFactor: f32 = 0,
    clearcoatRoughnessTexture: ?zgltf.TextureInfo = null,
    clearcoatNormalTexture: ?zgltf.NormalTextureInfo = null,
};

pub const EmissiveStrength = struct {
    emissiveStrength: f32 = 1,
};

pub const Ior = struct {
    ior: f32 = 1.5,
};

pub const TextureTransform = struct {
    offset: [2]f32 = .{ 0, 0 },
    rotation: f32 = 0,
    scale: [2]f32 = .{ 1, 1 },
    texCoord: ?u32 = null,
};

pub const Transmission = struct {
    transmissionFactor: f32 = 0,
    transmissionTexture: ?zgltf.TextureInfo = null,
};

pub const Volume = struct {
    thicknessFactor: f32 = 0,
    thicknessTexture: ?zgltf.TextureInfo = null,
    attenuationDistance: f32 = std.math.inf(f32),
    attenuationColor: [3]f32 = .{ 1, 1, 1 },
};

pub const Specular = struct {
    specularFactor: f32 = 1,
    specularTexture: ?zgltf.TextureInfo = null,
    specularColorFactor: [3]f32 = .{ 1, 1, 1 },
    specularColorTexture: ?zgltf.TextureInfo = null,
};

pub const Sheen = struct {
    sheenColorFactor: [3]f32 = .{ 0, 0, 0 },
    sheenColorTexture: ?zgltf.TextureInfo = null,
    sheenRoughnessFactor: f32 = 0,
    sheenRoughnessTexture: ?zgltf.TextureInfo = null,
};

pub const Anisotropy = struct {
    anisotropyStrength: f32 = 0,
    anisotropyRotation: f32 = 0,
    anisotropyTexture: ?zgltf.TextureInfo = null,
};

pub const Iridescence = struct {
    iridescenceFactor: f32 = 0,
    iridescenceTexture: ?zgltf.TextureInfo = null,
    iridescenceIor: f32 = 1.3,
    iridescenceThicknessMinimum: f32 = 100,
    iridescenceThicknessMaximum: f32 = 400,
    iridescenceThicknessTexture: ?zgltf.TextureInfo = null,
};

pub const Dispersion = struct {
    dispersion: f32 = 0,
};

pub const VariantName = struct {
    name: []const u8,
};

pub const VariantsTop = struct {
    variants: []VariantName,
};

pub const VariantMapping = struct {
    material: u32,
    variants: []u32,
};

pub const VariantsPrimitive = struct {
    mappings: []VariantMapping,
};

pub const DracoAttributes = std.json.ArrayHashMap(u32);

pub const DracoMeshCompression = struct {
    bufferView: u32,
    attributes: DracoAttributes,
};

pub const TextureBasisu = struct {
    source: u32,
};

pub const XmpJsonLd = struct {
    packet: u32,
};

pub const XmpJsonLdTop = struct {
    packets: []std.json.Value,
};

const testing = std.testing;

test "lights_punctual node + top" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "extensionsUsed":["KHR_lights_punctual"],
        \\ "extensions":{"KHR_lights_punctual":{"lights":[
        \\   {"type":"point","color":[1,0.5,0.25],"intensity":50,"range":10}]}},
        \\ "nodes":[{"extensions":{"KHR_lights_punctual":{"light":0}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var top = (try zgltf.getTypedExtension(LightsPunctualTop, testing.allocator, p.value.extensions, lights_punctual_name)).?;
    defer top.deinit();
    try testing.expectEqual(@as(usize, 1), top.value.lights.len);
    try testing.expectEqual(LightType.point, top.value.lights[0].type);
    try testing.expectEqual([3]f32{ 1, 0.5, 0.25 }, top.value.lights[0].color);

    var node = (try zgltf.getTypedExtension(LightsPunctualNode, testing.allocator, p.value.nodes.?[0].extensions, lights_punctual_name)).?;
    defer node.deinit();
    try testing.expectEqual(@as(u32, 0), node.value.light);
}

test "materials_unlit toggle" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"extensions":{"KHR_materials_unlit":{}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const m = p.value.materials.?[0];
    var parsed = (try zgltf.getTypedExtension(MaterialsUnlit, testing.allocator, m.extensions, unlit_name)).?;
    defer parsed.deinit();
}

test "clearcoat" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"extensions":{"KHR_materials_clearcoat":{
        \\   "clearcoatFactor":0.7,
        \\   "clearcoatRoughnessFactor":0.2,
        \\   "clearcoatTexture":{"index":0}}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var cc = (try zgltf.getTypedExtension(Clearcoat, testing.allocator, p.value.materials.?[0].extensions, clearcoat_name)).?;
    defer cc.deinit();
    try testing.expectEqual(@as(f32, 0.7), cc.value.clearcoatFactor);
    try testing.expectEqual(@as(f32, 0.2), cc.value.clearcoatRoughnessFactor);
    try testing.expectEqual(@as(u32, 0), cc.value.clearcoatTexture.?.index);
}

test "emissive strength + ior defaults" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"extensions":{
        \\   "KHR_materials_emissive_strength":{"emissiveStrength":5.0},
        \\   "KHR_materials_ior":{}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const ext = p.value.materials.?[0].extensions;
    var es = (try zgltf.getTypedExtension(EmissiveStrength, testing.allocator, ext, emissive_strength_name)).?;
    defer es.deinit();
    try testing.expectEqual(@as(f32, 5.0), es.value.emissiveStrength);
    var ior = (try zgltf.getTypedExtension(Ior, testing.allocator, ext, ior_name)).?;
    defer ior.deinit();
    try testing.expectEqual(@as(f32, 1.5), ior.value.ior);
}

test "texture_transform" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"pbrMetallicRoughness":{"baseColorTexture":{
        \\   "index":0,
        \\   "extensions":{"KHR_texture_transform":{
        \\     "offset":[0.5,0.25],"rotation":1.5707,"scale":[2,2]}}}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const ti = p.value.materials.?[0].pbrMetallicRoughness.?.baseColorTexture.?;
    var tt = (try zgltf.getTypedExtension(TextureTransform, testing.allocator, ti.extensions, texture_transform_name)).?;
    defer tt.deinit();
    try testing.expectEqual([2]f32{ 0.5, 0.25 }, tt.value.offset);
    try testing.expectEqual([2]f32{ 2, 2 }, tt.value.scale);
}

test "transmission + volume + specular" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"extensions":{
        \\   "KHR_materials_transmission":{"transmissionFactor":0.5},
        \\   "KHR_materials_volume":{"thicknessFactor":1.0,"attenuationColor":[0.9,0.95,1.0]},
        \\   "KHR_materials_specular":{"specularFactor":0.4,"specularColorFactor":[0.8,0.8,0.8]}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const ext = p.value.materials.?[0].extensions;
    var tr = (try zgltf.getTypedExtension(Transmission, testing.allocator, ext, transmission_name)).?;
    defer tr.deinit();
    try testing.expectEqual(@as(f32, 0.5), tr.value.transmissionFactor);
    var vol = (try zgltf.getTypedExtension(Volume, testing.allocator, ext, volume_name)).?;
    defer vol.deinit();
    try testing.expectEqual(@as(f32, 1.0), vol.value.thicknessFactor);
    try testing.expectEqual([3]f32{ 0.9, 0.95, 1.0 }, vol.value.attenuationColor);
    var sp = (try zgltf.getTypedExtension(Specular, testing.allocator, ext, specular_name)).?;
    defer sp.deinit();
    try testing.expectEqual(@as(f32, 0.4), sp.value.specularFactor);
}

test "sheen + anisotropy + iridescence + dispersion" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "materials":[{"extensions":{
        \\   "KHR_materials_sheen":{"sheenColorFactor":[1,0.5,0.25],"sheenRoughnessFactor":0.8},
        \\   "KHR_materials_anisotropy":{"anisotropyStrength":0.6,"anisotropyRotation":1.5},
        \\   "KHR_materials_iridescence":{"iridescenceFactor":1.0,"iridescenceIor":1.4},
        \\   "KHR_materials_dispersion":{"dispersion":0.2}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const ext = p.value.materials.?[0].extensions;
    var sh = (try zgltf.getTypedExtension(Sheen, testing.allocator, ext, sheen_name)).?;
    defer sh.deinit();
    try testing.expectEqual([3]f32{ 1, 0.5, 0.25 }, sh.value.sheenColorFactor);
    var an = (try zgltf.getTypedExtension(Anisotropy, testing.allocator, ext, anisotropy_name)).?;
    defer an.deinit();
    try testing.expectEqual(@as(f32, 0.6), an.value.anisotropyStrength);
    var ir = (try zgltf.getTypedExtension(Iridescence, testing.allocator, ext, iridescence_name)).?;
    defer ir.deinit();
    try testing.expectEqual(@as(f32, 1.4), ir.value.iridescenceIor);
    var ds = (try zgltf.getTypedExtension(Dispersion, testing.allocator, ext, dispersion_name)).?;
    defer ds.deinit();
    try testing.expectEqual(@as(f32, 0.2), ds.value.dispersion);
}

test "variants top + primitive" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "extensions":{"KHR_materials_variants":{"variants":[{"name":"red"},{"name":"blue"}]}},
        \\ "meshes":[{"primitives":[{"attributes":{},
        \\   "extensions":{"KHR_materials_variants":{
        \\     "mappings":[{"material":0,"variants":[0]},{"material":1,"variants":[1]}]}}}]}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var top = (try zgltf.getTypedExtension(VariantsTop, testing.allocator, p.value.extensions, variants_name)).?;
    defer top.deinit();
    try testing.expectEqual(@as(usize, 2), top.value.variants.len);
    try testing.expectEqualStrings("red", top.value.variants[0].name);
    var prim = (try zgltf.getTypedExtension(VariantsPrimitive, testing.allocator, p.value.meshes.?[0].primitives[0].extensions, variants_name)).?;
    defer prim.deinit();
    try testing.expectEqual(@as(u32, 0), prim.value.mappings[0].material);
    try testing.expectEqualSlices(u32, &.{0}, prim.value.mappings[0].variants);
}

test "draco mesh compression" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "meshes":[{"primitives":[{"attributes":{"POSITION":0},
        \\   "extensions":{"KHR_draco_mesh_compression":{
        \\     "bufferView":3,"attributes":{"POSITION":0,"NORMAL":1}}}}]}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var d = (try zgltf.getTypedExtension(DracoMeshCompression, testing.allocator, p.value.meshes.?[0].primitives[0].extensions, draco_name)).?;
    defer d.deinit();
    try testing.expectEqual(@as(u32, 3), d.value.bufferView);
    try testing.expectEqual(@as(u32, 0), d.value.attributes.map.get("POSITION").?);
    try testing.expectEqual(@as(u32, 1), d.value.attributes.map.get("NORMAL").?);
}

test "texture_basisu" {
    const json =
        \\{"asset":{"version":"2.0"},
        \\ "textures":[{"extensions":{"KHR_texture_basisu":{"source":2}}}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var b = (try zgltf.getTypedExtension(TextureBasisu, testing.allocator, p.value.textures.?[0].extensions, texture_basisu_name)).?;
    defer b.deinit();
    try testing.expectEqual(@as(u32, 2), b.value.source);
}

test "xmp_json_ld" {
    const json =
        \\{"asset":{"version":"2.0","extensions":{"KHR_xmp_json_ld":{"packet":0}}},
        \\ "extensions":{"KHR_xmp_json_ld":{"packets":[{"dc:creator":"Alice"}]}}}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    var top = (try zgltf.getTypedExtension(XmpJsonLdTop, testing.allocator, p.value.extensions, xmp_json_ld_name)).?;
    defer top.deinit();
    try testing.expectEqual(@as(usize, 1), top.value.packets.len);
    var ref = (try zgltf.getTypedExtension(XmpJsonLd, testing.allocator, p.value.asset.extensions, xmp_json_ld_name)).?;
    defer ref.deinit();
    try testing.expectEqual(@as(u32, 0), ref.value.packet);
}

test "extension missing returns null" {
    const json =
        \\{"asset":{"version":"2.0"},"materials":[{}]}
    ;
    var p = try zgltf.parseSlice(testing.allocator, json);
    defer p.deinit();
    const res = try zgltf.getTypedExtension(Clearcoat, testing.allocator, p.value.materials.?[0].extensions, clearcoat_name);
    try testing.expect(res == null);
}
