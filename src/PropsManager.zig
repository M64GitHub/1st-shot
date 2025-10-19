const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;

pub const PropType = enum {
    AmmoBonus,
    ExtraLife,
    ShieldBonus,
    PointsBonus,
};

pub const Prop = struct {
    sprite: *Sprite = undefined,
    sprite_pool: *movy.graphic.SpritePool = undefined,
    screen: *movy.Screen = undefined,
    x: i32 = 0,
    y: i32 = 0,
    kind: PropType = .AmmoBonus,
    active: bool = false,

    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    collected: bool = false,
    value: u32 = 0, // For points and ammo amounts

    pub fn draw(self: *Prop) void {
        const surface = self.sprite.getCurrentFrameSurface() catch return;

        // Calculate available text lines (half of pixel height)
        const text_lines = surface.h / 2;
        if (text_lines < 2) return; // Need at least 2 lines

        // Prepare the text based on prop type
        var value_buf: [16]u8 = undefined;

        const label: []const u8 = switch (self.kind) {
            .ExtraLife => "LIVE",
            .PointsBonus => "BONUS",
            .ShieldBonus => "SHIELD",
            .AmmoBonus => "AMMO",
        };

        const value_text: []const u8 = switch (self.kind) {
            .ExtraLife => "+1",
            .ShieldBonus => "",
            .PointsBonus => blk: {
                break :blk std.fmt.bufPrint(
                    &value_buf,
                    "+{d}",
                    .{self.value},
                ) catch "+???";
            },
            .AmmoBonus => blk: {
                break :blk std.fmt.bufPrint(
                    &value_buf,
                    "+{d}",
                    .{self.value},
                ) catch "+???";
            },
        };

        // Calculate centered positions
        const label_x = (surface.w -| label.len) / 2;
        const value_x = (surface.w -| value_text.len) / 2;

        // Calculate Y positions (centered vertically, accounting for half-height)
        // We want to center 2 lines of text in the available space
        const center_line = text_lines / 2;
        const label_y = if (center_line > 0) (center_line - 1) * 2 else 0;
        const value_y = label_y + 1;

        // Draw the label on the first line
        _ = surface.putStrXY(
            label,
            label_x,
            @intCast(label_y + 1),
            movy.color.WHITE,
            movy.color.DARKER_GRAY,
        );

        // Draw the value on the second line
        _ = surface.putStrXY(
            value_text,
            value_x,
            @intCast(value_y + 1),
            movy.color.WHITE,
            movy.color.DARKER_GRAY,
        );
    }

    pub fn update(self: *Prop) void {
        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 2; // move downward

        }
        self.sprite.setXY(self.x, self.y);

        // Deactivate if off-screen
        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.x > @as(i32, @intCast(self.screen.w)) or
            self.x < -@as(i32, @intCast(self.sprite.w)))
        {
            self.active = false;
        }
    }

    pub fn getCenterCoords(self: *Prop) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.sprite.h));

        const x = self.sprite.x + @divTrunc(s_w, 2);
        const y = self.sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }

    pub fn collect(self: *Prop) void {
        self.active = false;
        self.collected = true;
        self.sprite_pool.release(self.sprite);
    }
};

pub const PropsManager = struct {
    screen: *movy.Screen,
    ammo_pool: movy.graphic.SpritePool,
    life_pool: movy.graphic.SpritePool,
    shield_pool: movy.graphic.SpritePool,
    points_pool: movy.graphic.SpritePool,
    active_props: [MaxProps]Prop,
    rng: std.Random.DefaultPrng,

    pub const MaxProps = 32;

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*PropsManager {
        const self = try allocator.create(PropsManager);
        self.* = PropsManager{
            .screen = screen,
            .ammo_pool = movy.graphic.SpritePool.init(allocator),
            .life_pool = movy.graphic.SpritePool.init(allocator),
            .shield_pool = movy.graphic.SpritePool.init(allocator),
            .points_pool = movy.graphic.SpritePool.init(allocator),
            .active_props = [_]Prop{.{ .active = false }} ** MaxProps,
            .rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp())),
        };

        try self.initSprites(allocator);
        return self;
    }

    fn initSprites(self: *PropsManager, allocator: std.mem.Allocator) !void {
        // Update these paths to match your actual asset filenames
        const ammo_path = "assets/prop_ammo.png";
        const life_path = "assets/prop_life.png";
        const shield_path = "assets/prop_shield.png";
        const points_path = "assets/prop_points.png";

        for (0..MaxProps) |_| {
            // Ammo bonus sprite
            var s = try Sprite.initFromPng(
                allocator,
                ammo_path,
                "ammo_prop",
            );
            try self.ammo_pool.addSprite(s);

            // Extra life sprite
            s = try Sprite.initFromPng(
                allocator,
                life_path,
                "life_prop",
            );
            try self.life_pool.addSprite(s);

            // Shield bonus sprite
            s = try Sprite.initFromPng(
                allocator,
                shield_path,
                "shield_prop",
            );
            try self.shield_pool.addSprite(s);

            // Points bonus sprite
            s = try Sprite.initFromPng(
                allocator,
                points_path,
                "points_prop",
            );
            try self.points_pool.addSprite(s);
        }
    }

    pub fn trySpawn(
        self: *PropsManager,
        x: i32,
        y: i32,
        kind: PropType,
        value: u32,
    ) !bool {
        // Check if we've hit the max props limit
        var count: usize = 0;
        for (self.active_props) |prop| {
            if (prop.active) count += 1;
        }
        if (count >= MaxProps) return false;

        const sprite = switch (kind) {
            .AmmoBonus => self.ammo_pool.get(),
            .ExtraLife => self.life_pool.get(),
            .ShieldBonus => self.shield_pool.get(),
            .PointsBonus => self.points_pool.get(),
        } orelse return false;

        const spritepool: *movy.graphic.SpritePool = switch (kind) {
            .AmmoBonus => &self.ammo_pool,
            .ExtraLife => &self.life_pool,
            .ShieldBonus => &self.shield_pool,
            .PointsBonus => &self.points_pool,
        };

        const y_h = @divTrunc(y, 2); // need to place on even y
        sprite.setXY(x, y_h * 2);

        for (&self.active_props) |*prop| {
            if (!prop.active) {
                prop.* = Prop{
                    .sprite = sprite,
                    .sprite_pool = spritepool,
                    .screen = self.screen,
                    .x = x,
                    .y = y_h * 2,
                    .active = true,
                    .kind = kind,
                    .speed_adder = self.rng.random().intRangeAtMost(
                        usize,
                        25,
                        30,
                    ),
                    .speed_threshold = 100,
                    .speed_value = 0,
                    .collected = false,
                    .value = value,
                };
                prop.draw();
                return true;
            }
        }
        return false;
    }

    // Convenience functions for spawning specific prop types

    pub fn spawnAmmoBonus(
        self: *PropsManager,
        x: i32,
        y: i32,
        ammo_amount: u32,
    ) !bool {
        return self.trySpawn(x, y, .AmmoBonus, ammo_amount);
    }

    pub fn spawnPointsBonus(
        self: *PropsManager,
        x: i32,
        y: i32,
        points_amount: u32,
    ) !bool {
        return self.trySpawn(x, y, .PointsBonus, points_amount);
    }

    pub fn spawnExtraLife(
        self: *PropsManager,
        x: i32,
        y: i32,
    ) !bool {
        return self.trySpawn(x, y, .ExtraLife, 0);
    }

    pub fn spawnShieldBonus(
        self: *PropsManager,
        x: i32,
        y: i32,
    ) !bool {
        return self.trySpawn(x, y, .ShieldBonus, 0);
    }

    pub fn update(self: *PropsManager) !void {
        // Update active props
        for (&self.active_props) |*prop| {
            if (prop.active) {
                prop.update();
                if (!prop.active and !prop.collected) {
                    // Release sprites of inactive props that weren't collected
                    switch (prop.kind) {
                        .AmmoBonus => self.ammo_pool.release(prop.sprite),
                        .ExtraLife => self.life_pool.release(prop.sprite),
                        .ShieldBonus => self.shield_pool.release(prop.sprite),
                        .PointsBonus => self.points_pool.release(prop.sprite),
                    }
                }
            }
        }
    }

    pub fn addRenderSurfaces(self: *PropsManager) !void {
        for (&self.active_props) |*prop| {
            if (prop.active) {
                try self.screen.addRenderSurface(
                    try prop.sprite.getCurrentFrameSurface(),
                );
            }
        }
    }

    pub fn deinit(self: *PropsManager, allocator: std.mem.Allocator) void {
        self.ammo_pool.deinit(allocator);
        self.life_pool.deinit(allocator);
        self.shield_pool.deinit(allocator);
        self.points_pool.deinit(allocator);
        allocator.destroy(self);
    }
};
