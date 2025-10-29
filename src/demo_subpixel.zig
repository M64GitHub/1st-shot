const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;

var ScreenWidth: usize = 80;
var ScreenHeight: usize = 24;

const Obstacle = struct {
    sprite: Sprite,
    x: i32,
    y: i32,

    // For jerky movement
    frame_counter: usize = 0,
    frame_threshold: usize = 1,

    // For smooth movement
    speed_adder: usize = 100,
    speed_value: usize = 0,
    speed_threshold: usize = 100,

    is_smooth: bool = false,

    pub fn updateRough(self: *Obstacle) void {
        self.frame_counter += 1;
        if (self.frame_counter >= self.frame_threshold) {
            self.frame_counter = 0;
            self.y += 1;
        }

        // Loop back to top
        if (self.y > ScreenHeight * 2) {
            self.y = -@as(i32, @intCast(self.sprite.h));
        }

        self.sprite.setXY(self.x, self.y);
    }

    pub fn updateSmooth(self: *Obstacle) void {
        self.speed_value += self.speed_adder;

        // Move multiple pixels if speed_value accumulated enough
        while (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 1;
        }

        // Loop back to top
        if (self.y > ScreenHeight * 2) {
            self.y = -@as(i32, @intCast(self.sprite.h));
        }

        self.sprite.setXY(self.x, self.y);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const terminal_size = try movy.terminal.getSize();
    ScreenHeight = terminal_size.height;
    ScreenWidth = terminal_size.width;

    // Initialize terminal
    try movy.terminal.beginRawMode();
    defer movy.terminal.endRawMode();
    try movy.terminal.beginAlternateScreen();
    defer movy.terminal.endAlternateScreen();

    // Create screen
    var screen = try movy.Screen.init(
        allocator,
        terminal_size.width,
        terminal_size.height,
    );
    defer screen.deinit(allocator);
    screen.setScreenMode(movy.Screen.Mode.bgcolor);
    screen.bg_color = movy.color.BLACK;

    // Load obstacle sprite (big asteroid)
    var sprite_left = try Sprite.initFromPng(
        allocator,
        "assets/asteroid_big.png",
        "asteroid_left",
    );
    defer sprite_left.deinit(allocator);

    var sprite_right = try Sprite.initFromPng(
        allocator,
        "assets/asteroid_big.png",
        "asteroid_right",
    );
    defer sprite_right.deinit(allocator);

    // Setup animations
    try sprite_left.splitByWidth(allocator, 30);
    try sprite_left.addAnimation(
        allocator,
        "spin",
        Sprite.FrameAnimation.init(1, 4, .loopBounce, 1),
    );
    try sprite_left.startAnimation("spin");

    try sprite_right.splitByWidth(allocator, 30);
    try sprite_right.addAnimation(
        allocator,
        "spin",
        Sprite.FrameAnimation.init(1, 4, .loopBounce, 1),
    );
    try sprite_right.startAnimation("spin");

    // Create obstacles
    var left_obstacle = Obstacle{
        .sprite = sprite_left.*,
        .x = 20,
        .y = 0,
        .frame_threshold = 1,
        .is_smooth = false,
    };

    var right_obstacle = Obstacle{
        .sprite = sprite_right.*,
        .x = 80,
        .y = 0,
        .frame_threshold = 1,
        .speed_adder = 75,
        .speed_threshold = 100,
        .is_smooth = true,
    };

    var running = true;
    var inner_loop: usize = 0;
    var show_left = true;
    var show_right = false;

    while (running) {
        inner_loop += 1;

        // Input handling - poll EVERY loop for responsiveness
        if (try movy.input.get()) |in| {
            switch (in) {
                .key => |key| {
                    switch (key.type) {
                        .Escape => running = false,
                        .Char => {
                            if (key.sequence.len == 1) {
                                if (key.sequence[0] == '1') {
                                    show_left = !show_left;
                                } else if (key.sequence[0] == '2') {
                                    show_right = !show_right;
                                } else if (key.sequence[0] == 'y' or
                                    key.sequence[0] == 'Y')
                                {
                                    // Sync smooth obstacle Y position to jerky
                                    right_obstacle.y = left_obstacle.y;
                                }
                            }
                        },
                        .Down => {
                            if (left_obstacle.frame_threshold > 1) {
                                left_obstacle.frame_threshold -= 1; // Speed up jerky
                            }
                        },
                        .Up => {
                            if (left_obstacle.frame_threshold < 20) {
                                left_obstacle.frame_threshold += 1; // Slow down rough
                            }
                        },
                        .Left => {
                            if (right_obstacle.speed_adder >= 5) {
                                right_obstacle.speed_adder -= 5; // Slow down smooth
                            }
                        },
                        .Right => {
                            right_obstacle.speed_adder += 5; // Speed up smooth
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }

        // Only render every 100 iterations for stable ~10 FPS (flicker-free)
        if (inner_loop % 200 == 0) {
            try screen.renderInit();

            // Update obstacles
            left_obstacle.sprite.stepActiveAnimation();
            left_obstacle.updateRough();

            right_obstacle.sprite.stepActiveAnimation();
            right_obstacle.updateSmooth();

            // Render obstacles (only if visible)
            if (show_left) {
                try screen.addRenderSurface(
                    allocator,
                    try left_obstacle.sprite.getCurrentFrameSurface(),
                );
            }

            if (show_right) {
                try screen.addRenderSurface(
                    allocator,
                    try right_obstacle.sprite.getCurrentFrameSurface(),
                );
            }

            screen.render();

            // Draw instructions at bottom
            const instructions_y = ScreenHeight - 3;
            _ = screen.output_surface.putStrXY(
                "CONTROLS:",
                2,
                instructions_y,
                movy.color.WHITE,
                movy.color.BLACK,
            );
            _ = screen.output_surface.putStrXY(
                "ESC=Quit  UP/DOWN=Rough  LEFT/RIGHT=Smooth  1/2=Toggle  Y=Sync",
                2,
                instructions_y + 1,
                movy.color.WHITE,
                movy.color.BLACK,
            );

            // Draw status
            var buf: [80]u8 = undefined;
            const status = try std.fmt.bufPrint(
                &buf,
                "Rough Threshold: {d:3}  Smooth Adder: {d:3}",
                .{
                    left_obstacle.frame_threshold,
                    right_obstacle.speed_adder,
                },
            );
            _ = screen.output_surface.putStrXY(
                status,
                2,
                instructions_y - 2,
                movy.color.WHITE,
                movy.color.BLACK,
            );

            // Draw smooth frame calculation (only if smooth is visible)
            if (show_right) {
                const f_value: f32 =
                    @as(f32, @floatFromInt(right_obstacle.speed_threshold)) /
                    @as(
                        f32,
                        @floatFromInt(right_obstacle.speed_adder),
                    );
                var f_buf: [40]u8 = undefined;
                const f_status = try std.fmt.bufPrint(
                    &f_buf,
                    "F = {d:.2}",
                    .{f_value},
                );
                _ = screen.output_surface.putStrXY(
                    f_status,
                    50,
                    instructions_y - 2,
                    movy.color.WHITE,
                    movy.color.BLACK,
                );
            }

            // Draw labels above obstacles (only if visible)
            if (show_left) {
                _ = screen.output_surface.putStrXY(
                    "ROUGH",
                    @intCast(left_obstacle.x - 2),
                    1,
                    movy.color.WHITE,
                    movy.color.BLACK,
                );
            }
            if (show_right) {
                _ = screen.output_surface.putStrXY(
                    "SMOOTH",
                    @intCast(right_obstacle.x - 2),
                    1,
                    movy.color.WHITE,
                    movy.color.BLACK,
                );
            }

            // Render to terminal - single output per frame = no flicker
            try screen.output();
        } else {
            // Fast polling when not rendering
            std.Thread.sleep(50_000);
        }
    }
}
