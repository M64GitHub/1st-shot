const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TrigWave = movy.animation.TrigWave;
const PlayerCenter = @import("EnemyManager.zig").PlayerCenter;

pub const EnemyState = enum {
    Entering, // Not fully visible yet
    Armed, // Fully visible, waiting to shoot
    FirstShot, // First projectile fired, waiting for second
    SecondShot, // Second projectile fired
    Disarmed, // Both projectiles fired, just moving down
};

pub const ProjectileSide = enum {
    Left,
    Right,
};

pub const LaunchedProjectile = struct {
    sprite: *Sprite = undefined,
    x: i32 = 0,
    y: i32 = 0,
    velocity_x: i32 = 0,
    velocity_y: i32 = 0,
    active: bool = false,
    ever_used: bool = false, // Track if this slot was ever initialized
    orphaned: bool = false, // True when parent ShooterEnemy is destroyed
    screen: *movy.Screen = undefined,
    sprite_pool: *movy.graphic.SpritePool = undefined, // Reference to pool for cleanup

    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    pub fn update(self: *LaunchedProjectile) void {
        if (!self.active) return;

        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.x += self.velocity_x;
            self.y += self.velocity_y;
        }

        self.sprite.stepActiveAnimation();
        self.sprite.setXY(self.x, self.y);

        // Deactivate if off-screen
        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.x > @as(i32, @intCast(self.screen.w)) or
            self.x < -@as(i32, @intCast(self.sprite.w)))
        {
            self.active = false;

            // If orphaned, release sprite back to pool since parent is gone
            if (self.orphaned) {
                self.sprite_pool.release(self.sprite);
                self.ever_used = false;
                self.orphaned = false;
            }
        }
    }

    pub fn getCenterCoords(self: *LaunchedProjectile) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.sprite.h));

        const x = self.sprite.x + @divTrunc(s_w, 2);
        const y = self.sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }
};

pub const ShooterEnemy = struct {
    master_sprite: *Sprite = undefined,
    left_projectile: ?*Sprite = null,
    right_projectile: ?*Sprite = null,
    launched_projectiles: [2]LaunchedProjectile =
        [_]LaunchedProjectile{.{}} ** 2,

    projectile_pool: *movy.graphic.SpritePool = undefined,
    screen: *movy.Screen = undefined,

    x: i32 = 0,
    y: i32 = 0,
    start_x: i32 = 0,
    active: bool = false,
    sprites_released: bool = false,

    state: EnemyState = .Entering,
    shot_timer: usize = 0,
    next_shot_delay: usize = 0,
    first_shot_side: ProjectileSide = .Left,

    damage: usize = 0,
    damage_threshold: usize = 2,
    score: u32 = 350,

    global_wave: TrigWave = undefined,

    speed_adder: usize = 0,
    speed_value: usize = 0,
    speed_threshold: usize = 0,

    pub fn update(
        self: *ShooterEnemy,
        player_center: PlayerCenter,
        rng: *std.Random.DefaultPrng,
    ) void {
        // Always update launched projectiles, even if parent is destroyed
        for (&self.launched_projectiles) |*proj| {
            proj.update();
        }

        if (!self.active) return;

        // Move downward
        self.speed_value += self.speed_adder;
        if (self.speed_value >= self.speed_threshold) {
            self.speed_value -= self.speed_threshold;
            self.y += 1;
        }

        // Apply global wave
        const global_offset = self.global_wave.tickSine();
        self.x = self.start_x + global_offset;

        // Update master sprite
        self.master_sprite.stepActiveAnimation();
        self.master_sprite.setXY(self.x, self.y);

        // Update attached projectiles (if not launched)
        if (self.left_projectile) |left| {
            left.stepActiveAnimation();
            left.setXY(self.x - 10, self.y);
        }
        if (self.right_projectile) |right| {
            right.stepActiveAnimation();
            right.setXY(self.x + 14, self.y);
        }

        // State machine
        switch (self.state) {
            .Entering => {
                // Check if fully visible
                if (self.y > 0) {
                    self.state = .Armed;
                    self.shot_timer = 0;
                    self.next_shot_delay =
                        rng.random().intRangeAtMost(usize, 60, 90);
                    // Randomly choose which projectile to fire first
                    self.first_shot_side =
                        if (rng.random().boolean()) .Left else .Right;
                }
            },
            .Armed => {
                self.shot_timer += 1;
                if (self.shot_timer >= self.next_shot_delay) {
                    self.launchProjectile(self.first_shot_side, player_center);
                    self.state = .FirstShot;
                    self.shot_timer = 0;
                    self.next_shot_delay =
                        rng.random().intRangeAtMost(usize, 60, 90);
                }
            },
            .FirstShot => {
                self.shot_timer += 1;
                if (self.shot_timer >= self.next_shot_delay) {
                    // Fire the other projectile
                    const second_side: ProjectileSide =
                        if (self.first_shot_side == .Left) .Right else .Left;

                    self.launchProjectile(second_side, player_center);
                    self.state = .Disarmed;
                }
            },
            .SecondShot, .Disarmed => {
                // Just continue moving downward
            },
        }

        // Deactivate if off-screen
        if (self.y > @as(i32, @intCast(self.screen.h)) or
            self.x > @as(i32, @intCast(self.screen.w)) or
            self.x < -@as(i32, @intCast(self.master_sprite.w)))
        {
            self.active = false;
        }
    }

    fn launchProjectile(
        self: *ShooterEnemy,
        side: ProjectileSide,
        player_center: PlayerCenter,
    ) void {
        // Get the projectile sprite and position
        const projectile_sprite: ?*Sprite =
            if (side == .Left) self.left_projectile else self.right_projectile;

        if (projectile_sprite == null) return;

        const sprite = projectile_sprite.?;
        const proj_x = if (side == .Left) self.x - 10 else self.x + 14;
        const proj_y = self.y;

        // Calculate velocity toward player center
        const dx_float = @as(f32, @floatFromInt(player_center.x - proj_x));
        const dy_float = @as(f32, @floatFromInt(player_center.y - proj_y));

        // Calculate distance using floats
        const dist_sq = dx_float * dx_float + dy_float * dy_float;
        const dist = @sqrt(dist_sq);

        // Normalize and scale to desired speed (2 pixels per frame)
        const speed: f32 = 2.0;
        var vel_x: i32 = 0;
        var vel_y: i32 = 2; // Default downward if something goes wrong

        if (dist > 0.1) { // Avoid division by very small numbers
            vel_x = @as(i32, @intFromFloat(@round(speed * dx_float / dist)));
            vel_y = @as(i32, @intFromFloat(@round(speed * dy_float / dist)));
        }

        // Find an inactive launched projectile slot
        for (&self.launched_projectiles) |*launched| {
            if (!launched.active) {
                launched.* = LaunchedProjectile{
                    .sprite = sprite,
                    .x = proj_x,
                    .y = proj_y,
                    .velocity_x = vel_x,
                    .velocity_y = vel_y,
                    .active = true,
                    .ever_used = true,
                    .orphaned = false,
                    .screen = self.screen,
                    .sprite_pool = self.projectile_pool,
                    .speed_adder = 100, // Move every frame
                    .speed_threshold = 100,
                    .speed_value = 0,
                };
                break;
            }
        }

        // Remove from attached projectiles
        if (side == .Left) {
            self.left_projectile = null;
        } else {
            self.right_projectile = null;
        }
    }

    pub fn getCenterCoords(self: *ShooterEnemy) struct { x: i32, y: i32 } {
        const s_w: i32 = @as(i32, @intCast(self.master_sprite.w));
        const s_h: i32 = @as(i32, @intCast(self.master_sprite.h));

        const x = self.master_sprite.x + @divTrunc(s_w, 2);
        const y = self.master_sprite.y + @divTrunc(s_h, 2);

        return .{ .x = x, .y = y };
    }

    pub fn tryDestroy(self: *ShooterEnemy) bool {
        return self.tryDestroyWithDamage(1);
    }

    pub fn tryDestroyWithDamage(self: *ShooterEnemy, damage_amount: usize) bool {
        if (self.damage < self.damage_threshold) {
            self.damage += damage_amount;
            if (self.damage >= self.damage_threshold) {
                self.active = false;
                return true;
            }
            return false;
        }
        self.active = false;
        return true;
    }

    pub fn release(
        self: *ShooterEnemy,
        master_pool: *movy.graphic.SpritePool,
        projectile_pool: *movy.graphic.SpritePool,
    ) void {
        // Only release if we haven't already
        if (self.sprites_released) return;

        // Release master sprite
        master_pool.release(self.master_sprite);

        // Convert attached projectiles into orphaned projectiles falling downward
        // This makes them continue flying instead of disappearing
        if (self.left_projectile) |left_sprite| {
            // Find an inactive slot for the orphaned projectile (can reuse old slots)
            var found_slot = false;
            for (&self.launched_projectiles) |*launched| {
                if (!launched.active) {
                    found_slot = true;
                    launched.* = LaunchedProjectile{
                        .sprite = left_sprite,
                        .x = self.x - 10,
                        .y = self.y,
                        .velocity_x = 0,
                        .velocity_y = 2, // Fall straight down
                        .active = true,
                        .ever_used = true,
                        .orphaned = true, // Mark as orphaned immediately
                        .screen = self.screen,
                        .sprite_pool = self.projectile_pool,
                        .speed_adder = 100,
                        .speed_threshold = 100,
                        .speed_value = 0,
                    };
                    self.left_projectile = null;
                    break;
                }
            }

            // If no slot available, release the sprite
            if (self.left_projectile != null) {
                projectile_pool.release(left_sprite);
                self.left_projectile = null;
            }
        }
        if (self.right_projectile) |right_sprite| {
            // Find an inactive slot for the orphaned projectile (can reuse old slots)
            var found_slot = false;
            for (&self.launched_projectiles) |*launched| {
                if (!launched.active) {
                    found_slot = true;
                    launched.* = LaunchedProjectile{
                        .sprite = right_sprite,
                        .x = self.x + 14,
                        .y = self.y,
                        .velocity_x = 0,
                        .velocity_y = 2, // Fall straight down
                        .active = true,
                        .ever_used = true,
                        .orphaned = true, // Mark as orphaned immediately
                        .screen = self.screen,
                        .sprite_pool = self.projectile_pool,
                        .speed_adder = 100,
                        .speed_threshold = 100,
                        .speed_value = 0,
                    };
                    self.right_projectile = null;
                    break;
                }
            }

            // If no slot available, release the sprite
            if (self.right_projectile != null) {
                projectile_pool.release(right_sprite);
                self.right_projectile = null;
            }
        }

        // Mark launched projectiles as orphaned so they can clean themselves up
        // Active projectiles will continue flying and release their sprites when off-screen
        // Inactive projectiles need immediate cleanup
        for (&self.launched_projectiles) |*launched| {
            if (launched.ever_used) {
                if (launched.active) {
                    // Let active projectiles continue flying
                    launched.orphaned = true;
                } else {
                    // Inactive projectiles can be cleaned up immediately
                    projectile_pool.release(launched.sprite);
                    launched.ever_used = false;
                }
            }
        }

        // Mark as released to prevent double-free
        self.sprites_released = true;
        self.active = false;
    }
};
