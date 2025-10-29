const std = @import("std");
const movy = @import("movy");
const LogFile = @import("LogFile.zig").LogFile;

const logo_text =
    \\ ____  ____________________        _________ ___ ___ ___________________
    \\/_   |/   _____/\__    ___/       /   _____//   X   \\_      \__    ___/
    \\ |   |\_____  \   |    |  ______  \_____  \/   _|_   \/  _|_  \|    |
    \\ |   |/        \  |    | /_____/  /        \    |    /    |    \    |
    \\ |___/_______  /  |____|         /_______  /\___X_  /\_______  /____|
    \\             \/                          \/       \/         \/
;

pub const GameLogo = struct {
    surface: *movy.core.RenderSurface,
    fade_frame: usize = 0,
    fade_duration: usize = 120,
    screen: *movy.Screen = undefined,
    active: bool = true,
    log_file: *LogFile,

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
        log_file: *LogFile,
    ) !*GameLogo {
        const width: u32 = 76;
        const height: u32 = 7 * 2;

        // Allocate GameLogo on heap
        const self = try allocator.create(GameLogo);
        errdefer allocator.destroy(self);

        // Create the render surface
        const surface = try movy.core.RenderSurface.init(
            allocator,
            width,
            height,
            movy.color.BLUE,
        );
        errdefer surface.deinit(allocator);

        const s_w: i32 = @as(i32, @intCast(screen.w));
        const s_h: i32 = @as(i32, @intCast(screen.h));

        const su_w: i32 = @as(i32, @intCast(surface.w));
        const su_h: i32 = @as(i32, @intCast(surface.h));

        const x = @divTrunc(s_w, 2) - @divTrunc(su_w, 2);
        var y = @divTrunc(s_h, 2) - @divTrunc(su_h, 2);

        // y needs to be even for char overlays
        const y_i: u32 = @intCast(y);
        if (y_i % 2 != 0) y -= 1;

        log_file.log("[GameLogo]", "y: {}", .{y});

        surface.x = x;
        surface.y = y;

        self.surface = surface;
        self.screen = screen;
        self.fade_duration = 60;
        self.fade_frame = 0;
        self.active = true;
        self.log_file = log_file;

        surface.clearTransparent();

        _ = self.surface.putStrXYTransparent(
            logo_text,
            0,
            0,
            movy.color.WHITE,
            movy.color.BLACK,
        );

        return self;
    }

    pub fn deinit(self: *GameLogo, allocator: std.mem.Allocator) void {
        self.surface.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn fadeIn(self: *GameLogo) !void {
        // Already fully visible, do nothing
        if (self.fade_frame >= self.fade_duration) return;

        // Calculate fade alpha (0.0 to 1.0)
        const alpha = @as(f32, @floatFromInt(self.fade_frame)) /
            @as(f32, @floatFromInt(self.fade_duration));

        // Convert to RGB value (0 to 255) - fading from black to white
        const color_val = @as(u8, @intFromFloat(alpha * 255.0));
        const fade_color = movy.core.types.Rgb{
            .r = color_val,
            .g = color_val,
            .b = color_val,
        };

        // Clear surface and re-render text with faded color
        self.surface.clearTransparent();
        _ = self.surface.putStrXYTransparent(
            logo_text,
            0,
            0,
            fade_color,
            movy.color.BLACK,
        );

        self.fade_frame += 1;
    }

    pub fn fadeOut(self: *GameLogo) !void {
        // Already fully invisible, do nothing
        if (self.fade_frame == 0) {
            // self.active = false;
            return;
        }

        // Calculate fade alpha (1.0 to 0.0 as frame decrements)
        const alpha = @as(f32, @floatFromInt(self.fade_frame)) /
            @as(f32, @floatFromInt(self.fade_duration));

        // Convert to RGB value (255 to 0) - fading from white to black
        const color_val = @as(u8, @intFromFloat(alpha * 255.0));
        const fade_color = movy.core.types.Rgb{
            .r = color_val,
            .g = color_val,
            .b = color_val,
        };

        // Clear surface and re-render text with faded color
        self.surface.clearTransparent();
        _ = self.surface.putStrXYTransparent(
            logo_text,
            0,
            0,
            fade_color,
            movy.color.BLACK,
        );

        self.fade_frame -= 1;
    }
};
