const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
// const TrigWave = movy.animation.TrigWave;

pub const DropStacleType = enum {
    ShieldDrop, // Drops shield bonus
    LifeDrop, // Drops extra life
    AmmoDrop, // Drops ammo (enables spread weapon)
    SpecialWeapon, // Drops special weapon with 50 ammo
    Jackpot, // Drops shield + life + ammo at once!
};

pub const DropStacle = struct {
    sprite: *Sprite = undefined,
    sprite_pool: *movy.graphic.SpritePool = undefined,
    screen: *movy.Screen = undefined,
    damage: usize = 0,
    damage_threshold: usize = 3, // Easier to destroy
    start_x: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    kind: DropStacleType = .AmmoDrop,
    active: bool = false,
    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    // wave: TrigWave = undefined,

    pub fn update(self: *DropStacle) void {
        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 1; // move downward
        }

        // self.x = self.start_x + self.wave.tickSine();
        self.x = self.start_x;

        self.sprite.stepActiveAnimation();
        self.sprite.setXY(self.x, self.y);

        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.x > @as(i32, @intCast(self.screen.w)) or
            self.x < -@as(i32, @intCast(self.sprite.w)))
        {
            self.active = false;
        }
    }

    pub fn getCenterCoords(self: *DropStacle) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.sprite.h));

        const x = self.sprite.x + @divTrunc(s_w, 2);
        const y = self.sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }

    pub fn tryDestroy(self: *DropStacle) bool {
        if (self.damage < self.damage_threshold) {
            self.damage += 1;
            return false;
        }
        self.active = false;
        self.sprite_pool.release(self.sprite);
        return true;
    }
};

pub const DropStacleManager = struct {
    screen: *movy.Screen,
    shield_drop_pool: movy.graphic.SpritePool,
    life_drop_pool: movy.graphic.SpritePool,
    ammo_drop_pool: movy.graphic.SpritePool,
    special_weapon_pool: movy.graphic.SpritePool,
    jackpot_pool: movy.graphic.SpritePool,
    active_dropstacles: [MaxDropStacles]DropStacle,

    // Auto spawn configuration
    target_count: usize = 2,
    spawn_cooldown: u16 = 0,
    spawn_interval: u16 = 60, // Spawn every ~10 seconds
    rng: std.Random.DefaultPrng,

    pub const MaxDropStacles = 16;

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*DropStacleManager {
        const self = try allocator.create(DropStacleManager);
        self.* = DropStacleManager{
            .screen = screen,
            .shield_drop_pool = movy.graphic.SpritePool.init(allocator),
            .life_drop_pool = movy.graphic.SpritePool.init(allocator),
            .ammo_drop_pool = movy.graphic.SpritePool.init(allocator),
            .special_weapon_pool = movy.graphic.SpritePool.init(allocator),
            .jackpot_pool = movy.graphic.SpritePool.init(allocator),
            .active_dropstacles = [_]DropStacle{.{ .active = false }} **
                MaxDropStacles,
            .rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp())),
        };

        try self.initSprites(allocator);
        return self;
    }

    fn initSprites(self: *DropStacleManager, allocator: std.mem.Allocator) !void {
        const shield_path = "assets/dropstacle_shield.png";
        const life_path = "assets/dropstacle_life.png";
        const ammo_path = "assets/dropstacle_ammo.png";
        const special_path = "assets/dropstacle_special.png";
        const jackpot_path = "assets/dropstacle_jackpot.png";

        for (0..MaxDropStacles) |_| {
            // Shield drop
            var s = try Sprite.initFromPng(
                allocator,
                shield_path,
                "shield_dropstacle",
            );
            try s.splitByWidth(allocator, 10);
            try s.addAnimation(
                allocator,
                "rotate",
                Sprite.FrameAnimation.init(1, 16, .loopForward, 2),
            );
            try self.shield_drop_pool.addSprite(s);

            // Life drop
            s = try Sprite.initFromPng(
                allocator,
                life_path,
                "life_dropstacle",
            );
            try s.splitByWidth(allocator, 10);
            try s.addAnimation(
                allocator,
                "rotate",
                Sprite.FrameAnimation.init(1, 16, .loopForward, 2),
            );
            try self.life_drop_pool.addSprite(s);

            // Ammo drop
            s = try Sprite.initFromPng(
                allocator,
                ammo_path,
                "ammo_dropstacle",
            );
            try s.splitByWidth(allocator, 10);
            try s.addAnimation(
                allocator,
                "rotate",
                Sprite.FrameAnimation.init(1, 16, .loopForward, 2),
            );
            try self.ammo_drop_pool.addSprite(s);

            // Special weapon drop
            s = try Sprite.initFromPng(
                allocator,
                special_path,
                "special_dropstacle",
            );
            try s.splitByWidth(allocator, 10);
            try s.addAnimation(
                allocator,
                "rotate",
                Sprite.FrameAnimation.init(1, 16, .loopForward, 2),
            );
            try self.special_weapon_pool.addSprite(s);

            // Jackpot drop
            s = try Sprite.initFromPng(
                allocator,
                jackpot_path,
                "jackpot_dropstacle",
            );
            try s.splitByWidth(allocator, 10);
            try s.addAnimation(
                allocator,
                "rotate",
                Sprite.FrameAnimation.init(1, 16, .loopForward, 1),
            );
            try self.jackpot_pool.addSprite(s);
        }
    }

    pub fn trySpawn(
        self: *DropStacleManager,
        x: i32,
        y: i32,
        kind: DropStacleType,
    ) !void {
        const sprite = switch (kind) {
            .ShieldDrop => self.shield_drop_pool.get(),
            .LifeDrop => self.life_drop_pool.get(),
            .AmmoDrop => self.ammo_drop_pool.get(),
            .SpecialWeapon => self.special_weapon_pool.get(),
            .Jackpot => self.jackpot_pool.get(),
        } orelse return;

        const spritepool: *movy.graphic.SpritePool = switch (kind) {
            .ShieldDrop => &self.shield_drop_pool,
            .LifeDrop => &self.life_drop_pool,
            .AmmoDrop => &self.ammo_drop_pool,
            .SpecialWeapon => &self.special_weapon_pool,
            .Jackpot => &self.jackpot_pool,
        };

        const damage_thr: usize = switch (kind) {
            .ShieldDrop => 3,
            .LifeDrop => 3,
            .AmmoDrop => 3,
            .SpecialWeapon => 5,
            .Jackpot => 8, // Harder to destroy, more valuable!
        };

        try sprite.startAnimation("rotate");
        sprite.setXY(x, y);

        // const ampl: i32 = self.rng.random().intRangeAtMost(
        //     i32,
        //     5,
        //     8,
        // );
        //
        // const time: usize = self.rng.random().intRangeAtMost(
        //     usize,
        //     50,
        //     100,
        // );

        for (&self.active_dropstacles) |*drop| {
            if (!drop.active) {
                drop.* = DropStacle{
                    .sprite = sprite,
                    .sprite_pool = spritepool,
                    .screen = self.screen,
                    .start_x = x,
                    .x = 0,
                    .y = y,
                    .active = true,
                    .kind = kind,
                    .speed_adder = self.rng.random().intRangeAtMost(
                        usize,
                        10,
                        20,
                    ),
                    .speed_threshold = 100,
                    .speed_value = 0,
                    .damage = 0,
                    .damage_threshold = damage_thr,

                    // .wave = movy.animation.TrigWave.init(time, ampl),
                };
                break;
            }
        }
    }

    pub fn update(self: *DropStacleManager) !void {
        // Auto-spawn logic
        var count: usize = 0;
        for (self.active_dropstacles) |drop| {
            if (drop.active) count += 1;
        }

        if (count < self.target_count) {
            if (self.spawn_cooldown == 0) {
                const rand_x: i32 = self.rng.random().intRangeAtMost(
                    i32,
                    0,
                    @as(i32, @intCast(self.screen.w)),
                );

                // Weighted random drop type
                const roll = self.rng.random().intRangeLessThan(u8, 0, 100);
                const kind: DropStacleType = switch (roll) {
                    0...39 => DropStacleType.AmmoDrop, // 40% - Most common
                    40...64 => DropStacleType.ShieldDrop, // 25%
                    65...84 => DropStacleType.LifeDrop, // 20%
                    85...94 => DropStacleType.SpecialWeapon, // 10%
                    else => DropStacleType.Jackpot, // 5% - Rare!
                };

                const y: i32 = -10;
                const x: i32 = 0;

                try self.trySpawn(rand_x + x, y, kind);

                self.spawn_cooldown = self.spawn_interval;
            } else {
                self.spawn_cooldown -= 1;
            }
        }

        // Update active dropstacles
        for (&self.active_dropstacles) |*drop| {
            if (drop.active) {
                drop.update();
                if (!drop.active) {
                    // Release sprites of inactive
                    switch (drop.kind) {
                        .ShieldDrop => self.shield_drop_pool.release(drop.sprite),
                        .LifeDrop => self.life_drop_pool.release(drop.sprite),
                        .AmmoDrop => self.ammo_drop_pool.release(drop.sprite),
                        .SpecialWeapon => self.special_weapon_pool.release(drop.sprite),
                        .Jackpot => self.jackpot_pool.release(drop.sprite),
                    }
                }
            }
        }
    }

    pub fn addRenderSurfaces(self: *DropStacleManager) !void {
        for (&self.active_dropstacles) |*drop| {
            if (drop.active) {
                try self.screen.addRenderSurface(
                    try drop.sprite.getCurrentFrameSurface(),
                );
            }
        }
    }

    pub fn deinit(self: *DropStacleManager, allocator: std.mem.Allocator) void {
        self.shield_drop_pool.deinit(allocator);
        self.life_drop_pool.deinit(allocator);
        self.ammo_drop_pool.deinit(allocator);
        self.special_weapon_pool.deinit(allocator);
        self.jackpot_pool.deinit(allocator);
        allocator.destroy(self);
    }
};
