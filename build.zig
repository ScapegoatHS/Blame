const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigwin32_dependency = b.dependency("zigwin32", .{});
    const minhook_dependency = b.dependency("minhook", .{});

    const process_module = b.addModule("blame", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "win32", .module = zigwin32_dependency.module("win32") },
            .{ .name = "minhook", .module = minhook_dependency.module("minhook") },
        },
    });

    process_module.linkSystemLibrary("Advapi32", .{});
    process_module.linkLibrary(minhook_dependency.artifact("minhook"));

    const test_exe = b.addTest(.{
        .root_module = process_module,
    });

    const test_step = b.step("test", "");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
