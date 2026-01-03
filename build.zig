const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = std.builtin.OptimizeMode.ReleaseFast;
    const sdl2_prefix_option = b.option([]const u8, "sdl2-prefix", "Path to the SDL2 installation prefix containing include/ and lib/");

    const dep_movy = b.dependency("movy", .{});
    const mod_movy = dep_movy.module("movy");

    const dep_resid = b.dependency("resid", .{});
    const mod_resid = dep_resid.module("resid");
    const mod_resid_mixer = dep_resid.module("resid_mixer");

    const is_macos = target.result.os.tag == .macos;
    const SDL2Paths = struct {
        include: []const u8,
        lib: []const u8,
    };
    var sdl2_paths: ?SDL2Paths = null;

    // Add SDL2 paths on macOS.
    if (is_macos) {
        const default_sdl2_prefix = "/opt/homebrew/opt/sdl2";
        const sdl2_prefix = sdl2_prefix_option orelse default_sdl2_prefix;
        sdl2_paths = .{
            .include = b.pathJoin(&.{ sdl2_prefix, "include" }),
            .lib = b.pathJoin(&.{ sdl2_prefix, "lib" }),
        };
    }

    if (sdl2_paths) |paths| {
        mod_resid_mixer.addIncludePath(.{ .cwd_relative = paths.include });
        mod_resid_mixer.addLibraryPath(.{ .cwd_relative = paths.lib });
    }

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

    // Add SDL2 paths when building on macOS.
    if (sdl2_paths) |paths| {
        game_exe.addIncludePath(.{ .cwd_relative = paths.include });
        game_exe.addLibraryPath(.{ .cwd_relative = paths.lib });
    }
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
