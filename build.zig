const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zgltf", .{
        .root_source_file = b.path("src/zgltf.zig"),
        .target = target,
    });

    const khr_mod = b.addModule("zgltf_khr", .{
        .root_source_file = b.path("src/khr.zig"),
        .target = target,
        .optimize = optimize,
    });
    khr_mod.addImport("zgltf", mod);

    const exe = b.addExecutable(.{
        .name = "zgltf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zgltf", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const khr_tests = b.addTest(.{ .root_module = khr_mod });
    const run_khr_tests = b.addRunArtifact(khr_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_khr_tests.step);

    // -------- examples (opt-in, not part of the library) --------
    const examples_step = b.step("examples", "Build example backends");
    const examples_test_step = b.step("examples-test", "Test example backends");

    const stb_dep = b.dependency("stb", .{});

    const stb_example_mod = b.createModule(.{
        .root_source_file = b.path("examples/image_stb/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "zgltf", .module = mod },
        },
    });
    stb_example_mod.addIncludePath(stb_dep.path(""));
    stb_example_mod.addCSourceFile(.{
        .file = b.path("examples/image_stb/stb_image_impl.c"),
        .flags = &.{},
    });

    const stb_example_exe = b.addExecutable(.{
        .name = "image_stb",
        .root_module = stb_example_mod,
    });
    examples_step.dependOn(&b.addInstallArtifact(stb_example_exe, .{}).step);

    const stb_example_tests = b.addTest(.{ .root_module = stb_example_mod });
    examples_test_step.dependOn(&b.addRunArtifact(stb_example_tests).step);
}
