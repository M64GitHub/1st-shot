const std = @import("std");
const movy = @import("movy");

/// Camera for horizontal scrolling viewport
pub const Camera = struct {
    x: i32 = 0,
    y: i32 = 0,
    target_x: i32 = 0,
    target_y: i32 = 0,

    screen_width: i32,
    screen_height: i32,

    // Level bounds
    level_width: i32,
    level_height: i32,

    // Camera smoothing
    smoothing: f32 = 0.1,

    // Dead zone (player can move this much before camera follows)
    dead_zone_x: i32 = 80,
    dead_zone_y: i32 = 40,

    // Look-ahead (camera leads in direction of movement)
    look_ahead_x: i32 = 60,

    pub fn init(
        screen_width: i32,
        screen_height: i32,
        level_width: i32,
        level_height: i32,
    ) Camera {
        return Camera{
            .screen_width = screen_width,
            .screen_height = screen_height,
            .level_width = level_width,
            .level_height = level_height,
        };
    }

    /// Update camera to follow target position (usually player center)
    pub fn follow(self: *Camera, target_x: i32, target_y: i32, velocity_x: i32) void {
        // Calculate desired camera position (center target on screen with look-ahead)
        const look_ahead: i32 = if (velocity_x > 0)
            self.look_ahead_x
        else if (velocity_x < 0)
            -self.look_ahead_x
        else
            0;

        self.target_x = target_x - @divTrunc(self.screen_width, 2) + look_ahead;
        self.target_y = target_y - @divTrunc(self.screen_height, 2) + 32; // Offset to show more ground

        // Apply dead zone
        const dx = self.target_x - self.x;
        const dy = self.target_y - self.y;

        if (@abs(dx) > self.dead_zone_x) {
            if (dx > 0) {
                self.x += @as(i32, @intFromFloat(@as(f32, @floatFromInt(dx - self.dead_zone_x)) * self.smoothing)) + 1;
            } else {
                self.x += @as(i32, @intFromFloat(@as(f32, @floatFromInt(dx + self.dead_zone_x)) * self.smoothing)) - 1;
            }
        }

        if (@abs(dy) > self.dead_zone_y) {
            if (dy > 0) {
                self.y += @as(i32, @intFromFloat(@as(f32, @floatFromInt(dy - self.dead_zone_y)) * self.smoothing)) + 1;
            } else {
                self.y += @as(i32, @intFromFloat(@as(f32, @floatFromInt(dy + self.dead_zone_y)) * self.smoothing)) - 1;
            }
        }

        // Clamp to level bounds
        self.clampToBounds();
    }

    /// Immediately center on position (no smoothing)
    pub fn centerOn(self: *Camera, x: i32, y: i32) void {
        self.x = x - @divTrunc(self.screen_width, 2);
        self.y = y - @divTrunc(self.screen_height, 2) + 32;
        self.clampToBounds();
    }

    /// Clamp camera to level bounds
    fn clampToBounds(self: *Camera) void {
        // Don't scroll past level boundaries
        self.x = @max(0, @min(self.x, self.level_width - self.screen_width));

        // For vertical, allow some flexibility but not too much
        self.y = @max(0, @min(self.y, self.level_height - self.screen_height));
    }

    /// Convert world coordinates to screen coordinates
    pub fn worldToScreen(self: *Camera, world_x: i32, world_y: i32) struct { x: i32, y: i32 } {
        return .{
            .x = world_x - self.x,
            .y = world_y - self.y,
        };
    }

    /// Convert screen coordinates to world coordinates
    pub fn screenToWorld(self: *Camera, screen_x: i32, screen_y: i32) struct { x: i32, y: i32 } {
        return .{
            .x = screen_x + self.x,
            .y = screen_y + self.y,
        };
    }

    /// Check if a world rectangle is visible on screen
    pub fn isVisible(self: *Camera, world_x: i32, world_y: i32, w: i32, h: i32) bool {
        return world_x + w > self.x and
            world_x < self.x + self.screen_width and
            world_y + h > self.y and
            world_y < self.y + self.screen_height;
    }

    /// Update level bounds (e.g., when loading a new level)
    pub fn setLevelBounds(self: *Camera, width: i32, height: i32) void {
        self.level_width = width;
        self.level_height = height;
        self.clampToBounds();
    }
};
