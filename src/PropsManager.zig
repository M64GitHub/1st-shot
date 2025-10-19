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
    speed: usize = 2,
    speed_ctr: usize = 0,
    collected: bool = false,

    pub fn update(self: *Prop) void {
        if (self.speed_ctr > 0) {
            self.speed_ctr -= 1;
            return;
        }
        self.speed_ctr = self.speed;
        self.y += 1; // move downward
        self.sprite.stepActiveAnimation();
        self.sprite.setXY(self.x, self.y);

        // Deactivate if off-screen
        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.y < -@as(i32, @intCast(self.sprite.h)) or
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

    // Auto spawn configuration
    spawn_cooldown: usize = 0,
    spawn_interval: usize = 600, // spawn every ~600 frames (10 seconds at 60fps)
    rng: std.Random.DefaultPrng,

    pub const MaxProps = 16;

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
            try s.splitByWidth(allocator, 16); // Adjust size as needed
            try s.addAnimation(
                allocator,
                "idle",
                Sprite.FrameAnimation.init(1, 4, .loopForward, 2),
            );
            try self.ammo_pool.addSprite(s);

            // Extra life sprite
            s = try Sprite.initFromPng(
                allocator,
                life_path,
                "life_prop",
            );
            try s.splitByWidth(allocator, 16);
            try s.addAnimation(
                allocator,
                "idle",
                Sprite.FrameAnimation.init(1, 4, .loopForward, 2),
            );
            try self.life_pool.addSprite(s);

            // Shield bonus sprite
            s = try Sprite.initFromPng(
                allocator,
                shield_path,
                "shield_prop",
            );
            try s.splitByWidth(allocator, 16);
            try s.addAnimation(
                allocator,
                "idle",
                Sprite.FrameAnimation.init(1, 4, .loopForward, 2),
            );
            try self.shield_pool.addSprite(s);

            // Points bonus sprite
            s = try Sprite.initFromPng(
                allocator,
                points_path,
                "points_prop",
            );
            try s.splitByWidth(allocator, 16);
            try s.addAnimation(
                allocator,
                "idle",
                Sprite.FrameAnimation.init(1, 4, .loopForward, 2),
            );
            try self.points_pool.addSprite(s);
        }
    }

    pub fn trySpawn(
        self: *PropsManager,
        x: i32,
        y: i32,
        kind: PropType,
    ) !void {
        const sprite = switch (kind) {
            .AmmoBonus => self.ammo_pool.get(),
            .ExtraLife => self.life_pool.get(),
            .ShieldBonus => self.shield_pool.get(),
            .PointsBonus => self.points_pool.get(),
        } orelse return;

        const spritepool: *movy.graphic.SpritePool = switch (kind) {
            .AmmoBonus => &self.ammo_pool,
            .ExtraLife => &self.life_pool,
            .ShieldBonus => &self.shield_pool,
            .PointsBonus => &self.points_pool,
        };

        try sprite.startAnimation("idle");
        sprite.setXY(x, y);

        for (&self.active_props) |*prop| {
            if (!prop.active) {
                prop.* = Prop{
                    .sprite = sprite,
                    .sprite_pool = spritepool,
                    .screen = self.screen,
                    .x = x,
                    .y = y,
                    .active = true,
                    .kind = kind,
                    .speed = 2,
                    .speed_ctr = 0,
                    .collected = false,
                };
                break;
            }
        }
    }

    pub fn update(self: *PropsManager) !void {
        // Auto-spawn logic
        if (self.spawn_cooldown == 0) {
            // Count active props
            var count: usize = 0;
            for (self.active_props) |prop| {
                if (prop.active) count += 1;
            }

            // Spawn a new prop if not too many active
            if (count < 3) { // Max 3 props on screen at once
                const rand_x: i32 = self.rng.random().intRangeAtMost(
                    i32,
                    16,
                    @as(i32, @intCast(self.screen.w)) - 16,
                );

                // Weighted random prop type
                const roll = self.rng.random().intRangeLessThan(u8, 0, 100);
                const kind: PropType = switch (roll) {
                    0...39 => PropType.AmmoBonus, // 40% chance
                    40...59 => PropType.PointsBonus, // 20% chance
                    60...79 => PropType.ShieldBonus, // 20% chance
                    else => PropType.ExtraLife, // 20% chance
                };

                try self.trySpawn(rand_x, -16, kind);
                self.spawn_cooldown = self.spawn_interval;
            }
        } else {
            self.spawn_cooldown -= 1;
        }

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
