# zgltf

Zig library for the [glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html) standard.

**Goal:** full Core glTF 2.0 feature coverage.

## Feature Checklist

### Container Formats
- [x] `.gltf` (JSON)
- [x] `.glb` (binary container)
- [x] External buffer / image files
- [x] Embedded base64 data URIs

### Asset
- [x] `version`
- [x] `minVersion`
- [x] `generator`
- [x] `copyright`

### Scenes & Nodes
- [x] Scenes
- [x] Default scene
- [x] Node hierarchy
- [x] Node transforms — matrix
- [x] Node transforms — TRS (translation / rotation / scale)

### Buffers / Buffer Views / Accessors
- [x] Buffers
- [x] Buffer views (with `byteStride`)
- [x] Accessors — all component types (`BYTE`, `UNSIGNED_BYTE`, `SHORT`, `UNSIGNED_SHORT`, `UNSIGNED_INT`, `FLOAT`)
- [x] Accessors — all element types (`SCALAR`, `VEC2`, `VEC3`, `VEC4`, `MAT2`, `MAT3`, `MAT4`)
- [x] Accessors — `normalized`
- [x] Accessors — `min` / `max`
- [x] Sparse accessors

### Meshes
- [x] Mesh primitives
- [x] Attribute `POSITION`
- [x] Attribute `NORMAL`
- [x] Attribute `TANGENT`
- [x] Attribute `TEXCOORD_0` / `TEXCOORD_1`
- [x] Attribute `COLOR_0`
- [x] Attribute `JOINTS_0`
- [x] Attribute `WEIGHTS_0`
- [x] Indexed primitives
- [x] Primitive mode `POINTS`
- [x] Primitive mode `LINES`
- [x] Primitive mode `LINE_LOOP`
- [x] Primitive mode `LINE_STRIP`
- [x] Primitive mode `TRIANGLES`
- [x] Primitive mode `TRIANGLE_STRIP`
- [x] Primitive mode `TRIANGLE_FAN`
- [x] Morph targets
- [x] Morph target weights

### Materials (PBR Metallic-Roughness)
- [x] `baseColorFactor`
- [x] `baseColorTexture`
- [x] `metallicFactor` / `roughnessFactor`
- [x] `metallicRoughnessTexture`
- [x] `normalTexture` (with `scale`)
- [x] `occlusionTexture` (with `strength`)
- [x] `emissiveFactor`
- [x] `emissiveTexture`
- [x] Alpha mode `OPAQUE`
- [x] Alpha mode `MASK` (with `alphaCutoff`)
- [x] Alpha mode `BLEND`
- [x] `doubleSided`

### Textures / Samplers / Images
- [x] Textures
- [x] Samplers — mag / min filter
- [x] Samplers — wrap S / T
- [x] Images — URI
- [x] Images — buffer view + `mimeType`
- [x] PNG decode (via pluggable `ImageDecoder`; reference backend in `examples/image_stb`)
- [x] JPEG decode (via pluggable `ImageDecoder`; reference backend in `examples/image_stb`)

### Cameras
- [x] Perspective
- [x] Orthographic

### Skins & Animation
- [x] Skins (joints, `inverseBindMatrices`)
- [x] Animation channels
- [x] Animation samplers
- [x] Interpolation `LINEAR`
- [x] Interpolation `STEP`
- [x] Interpolation `CUBICSPLINE`
- [x] Target path `translation`
- [x] Target path `rotation`
- [x] Target path `scale`
- [x] Target path `weights`

### Extensibility
- [x] `extensionsUsed`
- [x] `extensionsRequired`
- [x] `extensions` passthrough
- [x] `extras` passthrough
- [x] Typed extension access via `getTypedExtension(comptime T, ...)`
- [x] Optional `zgltf_khr` submodule with typed structs for all Khronos-ratified extensions: `KHR_lights_punctual`, `KHR_materials_unlit`/`clearcoat`/`emissive_strength`/`ior`/`transmission`/`volume`/`specular`/`sheen`/`anisotropy`/`iridescence`/`dispersion`/`variants`, `KHR_texture_transform`/`basisu`, `KHR_draco_mesh_compression`, `KHR_mesh_quantization`, `KHR_xmp_json_ld`, `KHR_animation_pointer`

### Validation
- [x] JSON schema conformance (required fields, non-empty arrays, camera-block match, min/max length)
- [x] Reference resolution checks
- [x] Accessor bounds checks
