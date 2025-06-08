const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = std.builtin.OptimizeMode.ReleaseFast;

    const dep_movy = b.dependency("movy", .{});
    const mod_movy = dep_movy.module("movy");

    const name = "1st-shot";

    const game_exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    game_exe.addIncludePath(b.path("src/core/lodepng/"));
    game_exe.root_module.addImport("movy", mod_movy);
    game_exe.linkLibC();
    b.installArtifact(game_exe);

    // Add run step
    const run_game = b.addRunArtifact(game_exe);
    run_game.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_game.addArgs(args);
    b.step(
        b.fmt("run-{s}", .{name}),
        b.fmt("Run {s}", .{name}),
    ).dependOn(&run_game.step);
}
