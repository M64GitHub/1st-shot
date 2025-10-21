const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TrigWave = movy.animation.TrigWave;

pub const MovementType = enum {
    Straight,
    Zigzag,
};

pub const Position = struct {
    x: i32,
    y: i32,
};

pub const SingleEnemy = struct {
    sprite: *Sprite = undefined,
    sprite_pool: *movy.graphic.SpritePool = undefined,
    screen: *movy.Screen = undefined,
    damage: usize = 0,
    damage_threshold: usize = 5,
    x: i32 = 0,
    y: i32 = 0,
    start_x: i32 = 0,
    active: bool = false,
    score: u32 = 250,
    movement_type: MovementType = .Straight,
    wave: TrigWave = undefined,

    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    pub fn update(self: *SingleEnemy) void {
        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 1; // move downward
        }

        // Update x position based on movement type
        switch (self.movement_type) {
            .Straight => {
                // x stays the same
            },
            .Zigzag => {
                self.x = self.start_x + self.wave.tickSine();
            },
        }

        self.sprite.stepActiveAnimation();
        self.sprite.setXY(self.x, self.y);

        // Deactivate if off-screen
        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.x > @as(i32, @intCast(self.screen.w)) or
            self.x < -@as(i32, @intCast(self.sprite.w)))
        {
            self.active = false;
        }
    }

    pub fn getCenterCoords(self: *SingleEnemy) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.sprite.h));

        const x = self.sprite.x + @divTrunc(s_w, 2);
        const y = self.sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }

    pub fn tryDestroy(self: *SingleEnemy) bool {
        if (self.damage < self.damage_threshold) {
            self.damage += 1;
            return false;
        }
        self.active = false;
        self.sprite_pool.release(self.sprite);
        return true;
    }
};

pub const SwarmEnemy = struct {
    master_sprite: *Sprite = undefined,
    tail_pool: movy.graphic.SpritePool,
    tail_sprites: [16]*Sprite = undefined,
    screen: *movy.Screen = undefined,
    damage: usize = 0,
    damage_threshold: usize = 15,
    x: i32 = 0,
    y: i32 = 0,
    start_x: i32 = 0,
    active: bool = false,
    score: u32 = 500,
    tail_count: usize = 6, // Active tail sprites (not including master)
    tail_spacing: i32 = 2, // Vertical distance between sprites
    wave: TrigWave = undefined,

    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    pub fn update(self: *SwarmEnemy) void {
        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 1; // move downward
        }

        // Get current tick before we increment it
        const current_tick = self.wave.tick;

        // Update master position with zigzag (full amplitude)
        const master_offset_x = movy.animation.trig.sine(current_tick, self.wave.duration, self.wave.amplitude);
        self.x = self.start_x + master_offset_x;

        self.master_sprite.stepActiveAnimation();
        self.master_sprite.setXY(self.x, self.y);

        // Update tail sprites - they follow with phase offset and decreasing amplitude
        for (0..self.tail_count) |i| {
            const tail_sprite = self.tail_sprites[i];
            tail_sprite.stepActiveAnimation();

            // Calculate position: offset behind master
            const offset_y = self.y + @as(i32, @intCast((i + 1))) * self.tail_spacing;

            // Phase offset for the wave - each tail is behind in the wave cycle
            // We calculate how far behind based on spacing
            const phase_offset = @as(usize, @intCast(self.tail_spacing * @as(i32, @intCast(i + 1))));

            // Calculate graduated amplitude: decreases from full at master to 1/4 at last tail
            // Formula: amplitude = base_amplitude * (1 - 3/4 * (i+1) / tail_count)
            // This gives us a linear progression from 100% to 25%
            const tail_index = i + 1; // 1 to tail_count
            const amplitude_reduction = @divTrunc(self.wave.amplitude * 3 * @as(i32, @intCast(tail_index)), @as(i32, @intCast(self.tail_count)) * 4);
            const tail_amplitude = self.wave.amplitude - amplitude_reduction;

            const offset_x = self.start_x + self.calculateSineWithAmplitude(current_tick, phase_offset, tail_amplitude);

            tail_sprite.setXY(offset_x, offset_y);
        }

        // Advance the wave tick for next frame
        self.wave.tick = (self.wave.tick + 1) % self.wave.duration;

        // Deactivate if master is off-screen (check bottom mainly)
        if (self.y > @as(i32, @intCast(self.screen.h)) + (@as(i32, @intCast(self.tail_count)) * self.tail_spacing)) {
            self.active = false;
        }
    }

    fn calculateSineWithAmplitude(self: *SwarmEnemy, current_tick: usize, phase_offset: usize, amplitude: i32) i32 {
        // Calculate the tick value for a sprite based on phase offset
        const offset_tick = if (current_tick >= phase_offset)
            current_tick - phase_offset
        else
            self.wave.duration + current_tick - (phase_offset % self.wave.duration);

        return movy.animation.trig.sine(offset_tick, self.wave.duration, amplitude);
    }

    pub fn getCenterCoords(self: *SwarmEnemy) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.master_sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.master_sprite.h));

        const x = self.master_sprite.x + @divTrunc(s_w, 2);
        const y = self.master_sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }

    pub fn tryDestroy(self: *SwarmEnemy) bool {
        if (self.damage < self.damage_threshold) {
            self.damage += 1;
            return false;
        }
        self.active = false;
        // Release all sprites
        for (0..self.tail_count) |i| {
            self.tail_pool.release(self.tail_sprites[i]);
        }
        return true;
    }

    pub fn getAllSpritePositions(self: *SwarmEnemy) [17]Position {
        var positions: [17]Position = undefined;

        // Master position
        const master_center = self.getCenterCoords();
        positions[0] = Position{ .x = master_center.x, .y = master_center.y };

        // Tail positions
        for (0..self.tail_count) |i| {
            const tail_sprite = self.tail_sprites[i];
            const s_w: i32 = @as(i32, @intCast(tail_sprite.w));
            const s_h: i32 = @as(i32, @intCast(tail_sprite.h));

            positions[i + 1] = Position{
                .x = tail_sprite.x + @divTrunc(s_w, 2),
                .y = tail_sprite.y + @divTrunc(s_h, 2),
            };
        }

        return positions;
    }
};

pub const EnemyManager = struct {
    screen: *movy.Screen,
    single_enemy_pool: movy.graphic.SpritePool,
    swarm_enemy_pool: movy.graphic.SpritePool,
    active_single_enemies: [MaxSingleEnemies]SingleEnemy,
    active_swarm_enemies: [MaxSwarmEnemies]SwarmEnemy,

    // Frame tracking
    update_count: usize = 0,

    // Spawning state
    single_spawn_cooldown: usize = 0,
    single_spawn_interval: usize = 300,
    swarm_spawn_cooldown: usize = 0,
    swarm_spawn_interval: usize = 200,
    swarm_unlock_frame: usize = 200,

    // Configuration
    max_single_concurrent: usize = 2,

    rng: std.Random.DefaultPrng,

    pub const MaxSingleEnemies = 8;
    pub const MaxSwarmEnemies = 4;

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*EnemyManager {
        const self = try allocator.create(EnemyManager);
        self.* = EnemyManager{
            .screen = screen,
            .single_enemy_pool = movy.graphic.SpritePool.init(allocator),
            .swarm_enemy_pool = movy.graphic.SpritePool.init(allocator),
            .active_single_enemies = [_]SingleEnemy{.{ .active = false }} ** MaxSingleEnemies,
            .active_swarm_enemies = [_]SwarmEnemy{
                .{
                    .active = false,
                    .tail_pool = movy.graphic.SpritePool.init(allocator),
                },
            } ** MaxSwarmEnemies,
            .rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp())),
        };

        try self.initSprites(allocator);
        return self;
    }

    fn initSprites(self: *EnemyManager, allocator: std.mem.Allocator) !void {
        const single_enemy_path = "assets/enemy_single.png";
        const swarm_enemy_path = "assets/enemy_swarm.png";

        // Initialize SingleEnemy sprite pool
        for (0..MaxSingleEnemies) |_| {
            const s = try Sprite.initFromPng(
                allocator,
                single_enemy_path,
                "single_enemy",
            );
            try s.splitByWidth(allocator, 12);
            try s.addAnimation(
                allocator,
                "fly",
                Sprite.FrameAnimation.init(1, 12, .loopForward, 1),
            );
            try self.single_enemy_pool.addSprite(s);
        }

        // Initialize SwarmEnemy sprite pools (each swarm has its own tail pool)
        for (&self.active_swarm_enemies) |*swarm| {
            for (0..16) |_| {
                const s = try Sprite.initFromPng(
                    allocator,
                    swarm_enemy_path,
                    "swarm_enemy",
                );
                try s.splitByWidth(allocator, 12);
                try s.addAnimation(
                    allocator,
                    "fly",
                    Sprite.FrameAnimation.init(1, 12, .loopForward, 1),
                );
                try swarm.tail_pool.addSprite(s);
            }
        }
    }

    pub fn getCurrentTailSize(self: *EnemyManager) usize {
        // Start at 6, increase by 1 every 1000 frames, max 16
        const base_size: usize = 6;
        const growth = self.update_count / 1000;
        return @min(base_size + growth, 16);
    }

    pub fn trySpawnSingleEnemy(
        self: *EnemyManager,
        x: i32,
        y: i32,
        movement_type: MovementType,
    ) !void {
        const sprite = self.single_enemy_pool.get() orelse return;

        // Random speed
        const min_speed: usize = 30;
        const max_speed: usize = 50;

        // Random zigzag parameters if needed
        var wave = TrigWave.init(1, 0); // default (unused for Straight)
        const start_x = x;

        if (movement_type == .Zigzag) {
            const duration = self.rng.random().intRangeAtMost(usize, 60, 90);
            const amplitude = self.rng.random().intRangeAtMost(i32, 20, 60);
            wave = TrigWave.init(duration, amplitude);
        }

        try sprite.startAnimation("fly");
        sprite.setXY(x, y);

        for (&self.active_single_enemies) |*enemy| {
            if (!enemy.active) {
                enemy.* = SingleEnemy{
                    .sprite = sprite,
                    .sprite_pool = &self.single_enemy_pool,
                    .screen = self.screen,
                    .x = x,
                    .y = y,
                    .start_x = start_x,
                    .active = true,
                    .movement_type = movement_type,
                    .wave = wave,

                    .speed_adder = self.rng.random().intRangeAtMost(
                        usize,
                        min_speed,
                        max_speed,
                    ),
                    .speed_threshold = 100,
                    .speed_value = 0,

                    .damage = 0,
                    .damage_threshold = 5,
                    .score = 250,
                };
                break;
            }
        }
    }

    pub fn trySpawnSwarmEnemy(
        self: *EnemyManager,
        x: i32,
        y: i32,
    ) !void {
        // Find an inactive swarm slot
        for (&self.active_swarm_enemies) |*swarm| {
            if (!swarm.active) {
                // Get master sprite from the swarm's tail pool
                const master = swarm.tail_pool.get() orelse return;

                // Get tail sprites
                const tail_size = self.getCurrentTailSize();
                var tail_sprites: [16]*Sprite = undefined;

                for (0..tail_size) |i| {
                    tail_sprites[i] = swarm.tail_pool.get() orelse {
                        // If we can't get enough sprites, release what we got
                        swarm.tail_pool.release(master);
                        for (0..i) |j| {
                            swarm.tail_pool.release(tail_sprites[j]);
                        }
                        return;
                    };
                }

                // Random zigzag parameters
                const duration = self.rng.random().intRangeAtMost(usize, 60, 120);
                const amplitude = self.rng.random().intRangeAtMost(i32, 80, 100);
                const spacing = self.rng.random().intRangeAtMost(i32, 4, 8);

                // Random speed
                const min_speed: usize = 25;
                const max_speed: usize = 45;

                try master.startAnimation("fly");
                master.setXY(x, y);

                for (0..tail_size) |i| {
                    try tail_sprites[i].startAnimation("fly");
                }

                swarm.* = SwarmEnemy{
                    .master_sprite = master,
                    .tail_pool = swarm.tail_pool,
                    .tail_sprites = tail_sprites,
                    .screen = self.screen,
                    .x = x,
                    .y = y,
                    .start_x = x,
                    .active = true,
                    .tail_count = tail_size,
                    .tail_spacing = spacing,
                    .wave = TrigWave.init(duration, amplitude),

                    .speed_adder = self.rng.random().intRangeAtMost(
                        usize,
                        min_speed,
                        max_speed,
                    ),
                    .speed_threshold = 100,
                    .speed_value = 0,

                    .damage = 0,
                    .damage_threshold = 15,
                    .score = 500,
                };

                return;
            }
        }
    }

    pub fn update(self: *EnemyManager) !void {
        // Auto-spawn SingleEnemies
        var single_count: usize = 0;
        for (self.active_single_enemies) |enemy| {
            if (enemy.active) single_count += 1;
        }

        if (single_count < self.max_single_concurrent) {
            if (self.single_spawn_cooldown == 0) {
                // Spawn 1 or 2 enemies (60% chance for 1, 40% for 2)
                const roll = self.rng.random().intRangeLessThan(u8, 0, 10);
                const count = if (roll < 6) @as(usize, 1) else @as(usize, 2);

                for (0..count) |_| {
                    const rand_x: i32 = self.rng.random().intRangeAtMost(
                        i32,
                        16,
                        @as(i32, @intCast(self.screen.w)) - 16,
                    );

                    // 50/50 chance for Straight or Zigzag
                    const movement_roll = self.rng.random().intRangeLessThan(u8, 0, 2);
                    const movement_type: MovementType = if (movement_roll == 0) .Straight else .Zigzag;

                    try self.trySpawnSingleEnemy(rand_x, -16, movement_type);
                }

                // Add random jitter to interval
                const jitter = self.rng.random().intRangeAtMost(usize, 0, 50);
                self.single_spawn_cooldown = self.single_spawn_interval + jitter;
            } else {
                self.single_spawn_cooldown -= 1;
            }
        }

        // Auto-spawn SwarmEnemies (only after unlock frame)
        if (self.update_count >= self.swarm_unlock_frame) {
            var swarm_count: usize = 0;
            for (self.active_swarm_enemies) |swarm| {
                if (swarm.active) swarm_count += 1;
            }

            if (swarm_count < MaxSwarmEnemies) {
                if (self.swarm_spawn_cooldown == 0) {
                    const rand_x: i32 = self.rng.random().intRangeAtMost(
                        i32,
                        32,
                        @as(i32, @intCast(self.screen.w)) - 32,
                    );

                    try self.trySpawnSwarmEnemy(rand_x, -120);

                    // Add random jitter to interval
                    const jitter = self.rng.random().intRangeAtMost(usize, 0, 100);
                    self.swarm_spawn_cooldown = self.swarm_spawn_interval + jitter;
                } else {
                    self.swarm_spawn_cooldown -= 1;
                }
            }
        }

        // Update all active enemies
        for (&self.active_single_enemies) |*enemy| {
            if (enemy.active) {
                enemy.update();
                if (!enemy.active) {
                    self.single_enemy_pool.release(enemy.sprite);
                }
            }
        }

        for (&self.active_swarm_enemies) |*swarm| {
            if (swarm.active) {
                swarm.update();
                if (!swarm.active) {
                    // Release all sprites
                    for (0..swarm.tail_count) |i| {
                        swarm.tail_pool.release(swarm.tail_sprites[i]);
                    }
                    swarm.tail_pool.release(swarm.master_sprite);
                }
            }
        }

        self.update_count += 1;
    }

    pub fn addRenderSurfaces(self: *EnemyManager) !void {
        // Render SingleEnemies
        for (&self.active_single_enemies) |*enemy| {
            if (enemy.active) {
                try self.screen.addRenderSurface(
                    try enemy.sprite.getCurrentFrameSurface(),
                );
            }
        }

        // Render SwarmEnemies (tail first, then master on top)
        for (&self.active_swarm_enemies) |*swarm| {
            if (swarm.active) {
                // Render tail sprites from back to front
                var i: usize = swarm.tail_count;
                while (i > 0) {
                    i -= 1;
                    try self.screen.addRenderSurface(
                        try swarm.tail_sprites[i].getCurrentFrameSurface(),
                    );
                }

                // Render master last (on top)
                try self.screen.addRenderSurface(
                    try swarm.master_sprite.getCurrentFrameSurface(),
                );
            }
        }
    }

    pub fn deinit(self: *EnemyManager, allocator: std.mem.Allocator) void {
        self.single_enemy_pool.deinit(allocator);
        for (&self.active_swarm_enemies) |*swarm| {
            swarm.tail_pool.deinit(allocator);
        }
        allocator.destroy(self);
    }
};
