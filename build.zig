const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = std.builtin.OptimizeMode.ReleaseFast;

    const dep_movy = b.dependency("movy", .{});
    const mod_movy = dep_movy.module("movy");

    const dep_resid = b.dependency("resid", .{});
    const mod_resid = dep_resid.module("resid");

    const name = "1st-shot";

    const game_mod = b.addModule(name, .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    game_mod.addIncludePath(b.path("src/core/lodepng/"));
    game_mod.addImport("movy", mod_movy);
    game_mod.addImport("resid", mod_resid);

    const game_exe = b.addExecutable(.{
        .name = name,
        .root_module = game_mod,
    });
    game_exe.linkLibC();
    game_exe.linkSystemLibrary("SDL2");
    b.installArtifact(game_exe);

    // Add run step for main game
    const run_game = b.addRunArtifact(game_exe);
    run_game.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_game.addArgs(args);
    b.step(
        b.fmt("run-{s}", .{name}),
        b.fmt("Run {s}", .{name}),
    ).dependOn(&run_game.step);

    // Demo: Subpixel movement comparison
    const demo_name = "demo-subpixel";
    const demo_mod = b.addModule(demo_name, .{
        .root_source_file = b.path("src/demo_subpixel.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo_mod.addIncludePath(b.path("src/core/lodepng/"));
    demo_mod.addImport("movy", mod_movy);

    const demo_exe = b.addExecutable(.{
        .name = demo_name,
        .root_module = demo_mod,
    });
    demo_exe.linkLibC();
    b.installArtifact(demo_exe);

    // Add run step for demo
    const run_demo = b.addRunArtifact(demo_exe);
    run_demo.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_demo.addArgs(args);
    b.step(
        b.fmt("run-{s}", .{demo_name}),
        b.fmt("Run {s}", .{demo_name}),
    ).dependOn(&run_demo.step);
}
