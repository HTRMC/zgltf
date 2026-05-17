# image_stb

Reference `ImageDecoder` impl backed by [stb_image](https://github.com/nothings/stb). Not part of the `zgltf` library; opt-in example showing how to plug a decoder into the `zgltf.image.ImageDecoder` vtable.

## Files

- `decoder.zig`: exports `pub const decoder: image.ImageDecoder` wrapping `stbi_load_from_memory`. Frees with `stbi_image_free` via the `free_with` hook.
- `stb_image_impl.c`: `#define STB_IMAGE_IMPLEMENTATION` translation unit.
- `main.zig`: CLI demo. `image_stb <path>` prints `WxH ch=N bytes=M`.

## Build / run

From repo root:

```sh
zig build examples            # builds zig-out/bin/image_stb
zig build examples-test       # runs decoder tests
./zig-out/bin/image_stb test-assets/Models/BoxTextured/glTF/CesiumLogoFlat.png
```

## Using in your own project

1. Copy `examples/image_stb/` into your tree.
2. Add the stb dependency to your `build.zig.zon`:
   ```sh
   zig fetch --save https://github.com/nothings/stb/archive/<commit>.tar.gz
   ```
3. Mirror the build block (see repo `build.zig`, `examples` step):
   ```zig
   const stb_dep = b.dependency("stb", .{});
   your_mod.addIncludePath(stb_dep.path(""));
   your_mod.addCSourceFile(.{
       .file = b.path("path/to/stb_image_impl.c"),
       .flags = &.{},
   });
   your_mod.link_libc = true;
   ```
4. Import and pass to your texture loader:
   ```zig
   const stb = @import("decoder.zig");
   var img = try stb.decoder.decode(allocator, png_bytes);
   defer img.deinit(allocator);
   ```

## Picking a different backend

The decoder contract lives in `src/image.zig`:

```zig
pub const ImageDecoder = struct {
    ctx: ?*anyopaque = null,
    decodeFn: *const fn (ctx: ?*anyopaque, allocator: std.mem.Allocator, bytes: []const u8) DecodeError!DecodedImage,
};
```

Any backend (spng, lodepng, zigimg, libjpeg-turbo, KTX2) works. Implement `decodeFn`, return `DecodedImage`, set `free_with` if the backend owns the pixel buffer. glTF 2.0 requires PNG + JPEG, so PNG-only decoders (spng) need a JPEG fallback for full spec coverage.
