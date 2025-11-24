const std = @import("std");
const movy = @import("movy");
const PlatformerGame = @import("PlatformerGame.zig").PlatformerGame;

const FRAME_DELAY_NS = 14 * std.time.ns_per_ms; // ~71 FPS
const KEYDOWN_TIME: usize = 5; // key up after 5 frames

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // -- Init terminal and screen
    const terminal_size = try movy.terminal.getSize();

    // Set raw mode, switch to alternate screen
    try movy.terminal.beginRawMode();
    defer movy.terminal.endRawMode();
    try movy.terminal.beginAlternateScreen();
    defer movy.terminal.endAlternateScreen();

    // -- Initialize screen
    var screen = try movy.Screen.init(
        allocator,
        terminal_size.width,
        terminal_size.height,
    );
    defer screen.deinit(allocator);
    screen.setScreenMode(movy.Screen.Mode.bgcolor);
    screen.bg_color = movy.color.fromRgb(100, 148, 252); // Sky blue background

    // -- Game Setup
    var game = try PlatformerGame.init(allocator, &screen);
    defer game.deinit();

    // -- Main loop
    var render_time_buffer: [64]u8 = undefined;
    var output_time_buffer: [64]u8 = undefined;
    var loop_time_buffer: [64]u8 = undefined;
    var status_line_buffer: [1024]u8 = undefined;
    var render_time_len: usize = 0;
    var output_time_len: usize = 0;
    var loop_time_len: usize = 0;

    var frame: usize = 0;

    // Keyboard control
    var keydown_cooldown: usize = 0;
    var last_key: ?movy.input.Key = null;
    var status: []u8 = "";

    while (true) {
        const loop_start_time = std.time.nanoTimestamp();
        frame += 1;

        // Handle input
        if (try movy.input.get()) |in| {
            switch (in) {
                .key => |key| {
                    switch (key.type) {
                        .Escape => break,
                        else => {
                            last_key = key;
                            keydown_cooldown = KEYDOWN_TIME;
                            game.onKeyDown(last_key.?);
                        },
                    }
                },
                else => {},
            }
        } else {
            if (keydown_cooldown > 0) {
                keydown_cooldown -= 1;
                if (keydown_cooldown == 0) {
                    if (last_key) |key| {
                        game.onKeyUp(key);
                    }
                    last_key = null;
                }
            }
        }

        // Update game
        game.update();

        // Render
        const start_time = std.time.nanoTimestamp();
        try game.render(allocator);

        var end_time = std.time.nanoTimestamp();
        const render_time_ns = end_time - start_time;

        const scrn_h = @divTrunc(screen.h, 2);

        _ = screen.output_surface.putStrXY(
            status,
            0,
            scrn_h - 1,
            movy.color.LIGHT_BLUE,
            movy.color.BLACK,
        );

        // Output to terminal
        try screen.output();
        end_time = std.time.nanoTimestamp() - end_time;

        // Format timings for debug display
        const render_time = try std.fmt.bufPrint(
            &render_time_buffer,
            "Render: {d:>4} us",
            .{@divTrunc(render_time_ns, 1000)},
        );
        render_time_len = render_time.len;

        const output_time = try std.fmt.bufPrint(
            &output_time_buffer,
            "Output: {d:>6} us",
            .{@divTrunc(end_time, 1000)},
        );
        output_time_len = output_time.len;

        const loop_end_time = std.time.nanoTimestamp();
        const loop_time_ns = loop_end_time - loop_start_time;

        const loop_time = try std.fmt.bufPrint(
            &loop_time_buffer,
            "Loop: {d:>6} us",
            .{@divTrunc(loop_time_ns, 1000) + 500},
        );
        loop_time_len = loop_time.len;

        status = try std.fmt.bufPrint(
            &status_line_buffer,
            "{s:>20} | {s:>18} | {s:>18}",
            .{
                render_time_buffer[0..render_time_len],
                output_time_buffer[0..output_time_len],
                loop_time_buffer[0..loop_time_len],
            },
        );

        // Frame timing
        const total_end_time = std.time.nanoTimestamp();
        const frame_time = total_end_time - loop_start_time;
        if (frame_time < FRAME_DELAY_NS) {
            std.Thread.sleep(@intCast(FRAME_DELAY_NS - frame_time));
        }
    }
}
