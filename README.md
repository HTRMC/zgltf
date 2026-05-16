# zgltf

Zig library for the [glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html) standard.

**Goal:** full Core glTF 2.0 feature coverage.

## Feature Checklist

### Container Formats
- [ ] `.gltf` (JSON)
- [ ] `.glb` (binary container)
- [ ] External buffer / image files
- [ ] Embedded base64 data URIs

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
- [ ] `baseColorFactor`
- [ ] `baseColorTexture`
- [ ] `metallicFactor` / `roughnessFactor`
- [ ] `metallicRoughnessTexture`
- [ ] `normalTexture` (with `scale`)
- [ ] `occlusionTexture` (with `strength`)
- [ ] `emissiveFactor`
- [ ] `emissiveTexture`
- [ ] Alpha mode `OPAQUE`
- [ ] Alpha mode `MASK` (with `alphaCutoff`)
- [ ] Alpha mode `BLEND`
- [ ] `doubleSided`

### Textures / Samplers / Images
- [ ] Textures
- [ ] Samplers — mag / min filter
- [ ] Samplers — wrap S / T
- [ ] Images — URI
- [ ] Images — buffer view + `mimeType`
- [ ] PNG decode
- [ ] JPEG decode

### Cameras
- [ ] Perspective
- [ ] Orthographic

### Skins & Animation
- [ ] Skins (joints, `inverseBindMatrices`)
- [ ] Animation channels
- [ ] Animation samplers
- [ ] Interpolation `LINEAR`
- [ ] Interpolation `STEP`
- [ ] Interpolation `CUBICSPLINE`
- [ ] Target path `translation`
- [ ] Target path `rotation`
- [ ] Target path `scale`
- [ ] Target path `weights`

### Extensibility
- [ ] `extensionsUsed`
- [ ] `extensionsRequired`
- [ ] `extensions` passthrough
- [ ] `extras` passthrough

### Validation
- [ ] JSON schema conformance
- [ ] Reference resolution checks
- [ ] Accessor bounds checks
