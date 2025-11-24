const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TileMap = @import("TileMap.zig").TileMap;
const TileType = @import("TileMap.zig").TileType;
const Camera = @import("Camera.zig").Camera;

/// Player state
pub const PlayerState = enum {
    Idle,
    Walking,
    Jumping,
    Falling,
    Ducking,
    Dead,
};

/// Direction facing
pub const Direction = enum {
    Left,
    Right,
};

/// Platformer player with physics
pub const PlatformerPlayer = struct {
    // Position (world coordinates)
    x: i32 = 0,
    y: i32 = 0,

    // Velocity (subpixel precision)
    vel_x: i32 = 0,
    vel_y: i32 = 0,

    // Accumulated subpixel movement
    sub_x: i32 = 0,
    sub_y: i32 = 0,

    // Dimensions
    width: i32 = 14,
    height: i32 = 24,

    // State
    state: PlayerState = .Idle,
    direction: Direction = .Right,
    on_ground: bool = false,

    // Jump variables
    jump_held: bool = false,
    jump_timer: i32 = 0,
    coyote_time: i32 = 0, // Grace period after leaving platform

    // Physics constants (tuned for Mario-like feel)
    gravity: i32 = 60, // Subpixel gravity per frame
    max_fall_speed: i32 = 800, // Max falling velocity
    jump_force: i32 = -900, // Initial jump velocity
    jump_hold_force: i32 = -30, // Additional force while holding jump
    max_jump_hold_time: i32 = 15, // Frames to hold jump for max height

    walk_accel: i32 = 50, // Walking acceleration
    walk_decel: i32 = 40, // Deceleration when not pressing direction
    max_walk_speed: i32 = 350, // Max horizontal velocity
    air_control: i32 = 30, // Air control acceleration

    // Sprites
    sprite: *Sprite,
    screen: *movy.Screen,

    // Animation tracking
    walk_frame: usize = 0,
    walk_timer: usize = 0,

    // Input state
    input_left: bool = false,
    input_right: bool = false,
    input_jump: bool = false,
    input_duck: bool = false,

    // Lives and power state
    lives: usize = 3,
    is_big: bool = false,
    is_invincible: bool = false,
    invincible_timer: usize = 0,

    // Score
    score: usize = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*PlatformerPlayer {
        const self = try allocator.create(PlatformerPlayer);

        // Load player sprite
        var sprite = try Sprite.initFromPng(
            allocator,
            "assets/player.png",
            "player",
        );

        // Split into frames (16 pixels wide each)
        try sprite.splitByWidth(allocator, 16);

        // Define animations
        // Frame 0: idle, 1-3: walk, 4: jump, 5: duck
        try sprite.addAnimation(
            allocator,
            "idle",
            Sprite.FrameAnimation.init(0, 0, .once, 1),
        );

        try sprite.addAnimation(
            allocator,
            "walk",
            Sprite.FrameAnimation.init(1, 3, .loopForward, 6),
        );

        try sprite.addAnimation(
            allocator,
            "jump",
            Sprite.FrameAnimation.init(4, 4, .once, 1),
        );

        try sprite.addAnimation(
            allocator,
            "duck",
            Sprite.FrameAnimation.init(5, 5, .once, 1),
        );

        try sprite.startAnimation("idle");

        self.* = PlatformerPlayer{
            .sprite = sprite,
            .screen = screen,
        };

        return self;
    }

    pub fn deinit(self: *PlatformerPlayer, allocator: std.mem.Allocator) void {
        self.sprite.deinit(allocator);
        allocator.destroy(self);
    }

    /// Process keyboard input
    pub fn onKeyDown(self: *PlatformerPlayer, key: movy.input.Key) void {
        switch (key.type) {
            .Left => self.input_left = true,
            .Right => self.input_right = true,
            .Up, .Char => {
                if (key.type == .Char and key.sequence[0] == ' ') {
                    self.input_jump = true;
                } else if (key.type == .Up) {
                    self.input_jump = true;
                }
            },
            .Down => self.input_duck = true,
            else => {},
        }
    }

    pub fn onKeyUp(self: *PlatformerPlayer, key: movy.input.Key) void {
        switch (key.type) {
            .Left => self.input_left = false,
            .Right => self.input_right = false,
            .Up, .Char => {
                if (key.type == .Char and key.sequence[0] == ' ') {
                    self.input_jump = false;
                    self.jump_held = false;
                } else if (key.type == .Up) {
                    self.input_jump = false;
                    self.jump_held = false;
                }
            },
            .Down => self.input_duck = false,
            else => {},
        }
    }

    /// Update player physics and state
    pub fn update(self: *PlatformerPlayer, tilemap: *TileMap) void {
        if (self.state == .Dead) return;

        // Store previous ground state for coyote time
        const was_on_ground = self.on_ground;

        // Handle horizontal movement
        self.handleHorizontalMovement();

        // Handle jumping
        self.handleJumping(was_on_ground);

        // Apply gravity
        self.applyGravity();

        // Apply velocity and handle collisions
        self.applyVelocity(tilemap);

        // Update state
        self.updateState();

        // Update animation
        self.updateAnimation();

        // Update invincibility
        if (self.is_invincible) {
            if (self.invincible_timer > 0) {
                self.invincible_timer -= 1;
            } else {
                self.is_invincible = false;
            }
        }
    }

    fn handleHorizontalMovement(self: *PlatformerPlayer) void {
        const accel = if (self.on_ground) self.walk_accel else self.air_control;

        if (self.input_left and !self.input_duck) {
            self.vel_x -= accel;
            self.direction = .Left;
        } else if (self.input_right and !self.input_duck) {
            self.vel_x += accel;
            self.direction = .Right;
        } else {
            // Decelerate
            if (self.vel_x > 0) {
                self.vel_x = @max(0, self.vel_x - self.walk_decel);
            } else if (self.vel_x < 0) {
                self.vel_x = @min(0, self.vel_x + self.walk_decel);
            }
        }

        // Clamp horizontal velocity
        self.vel_x = std.math.clamp(self.vel_x, -self.max_walk_speed, self.max_walk_speed);
    }

    fn handleJumping(self: *PlatformerPlayer, was_on_ground: bool) void {
        // Update coyote time
        if (self.on_ground) {
            self.coyote_time = 6; // 6 frames of grace
        } else if (self.coyote_time > 0) {
            self.coyote_time -= 1;
        }

        // Start jump
        if (self.input_jump and !self.jump_held and (self.on_ground or self.coyote_time > 0)) {
            self.vel_y = self.jump_force;
            self.jump_held = true;
            self.jump_timer = self.max_jump_hold_time;
            self.on_ground = false;
            self.coyote_time = 0;
        }

        // Variable jump height (hold to jump higher)
        if (self.jump_held and self.input_jump and self.jump_timer > 0) {
            self.vel_y += self.jump_hold_force;
            self.jump_timer -= 1;
        }

        // Cancel jump hold if button released
        if (!self.input_jump) {
            self.jump_held = false;
            self.jump_timer = 0;
        }

        _ = was_on_ground;
    }

    fn applyGravity(self: *PlatformerPlayer) void {
        if (!self.on_ground) {
            self.vel_y += self.gravity;
            self.vel_y = @min(self.vel_y, self.max_fall_speed);
        }
    }

    fn applyVelocity(self: *PlatformerPlayer, tilemap: *TileMap) void {
        // Subpixel movement accumulation
        self.sub_x += self.vel_x;
        self.sub_y += self.vel_y;

        // Convert to pixel movement
        const move_x = @divTrunc(self.sub_x, 100);
        const move_y = @divTrunc(self.sub_y, 100);

        self.sub_x = @mod(self.sub_x, 100);
        self.sub_y = @mod(self.sub_y, 100);

        // Apply horizontal movement with collision
        self.moveX(move_x, tilemap);

        // Apply vertical movement with collision
        self.moveY(move_y, tilemap);
    }

    fn moveX(self: *PlatformerPlayer, amount: i32, tilemap: *TileMap) void {
        if (amount == 0) return;

        const step: i32 = if (amount > 0) 1 else -1;
        var remaining = @abs(amount);

        while (remaining > 0) : (remaining -= 1) {
            const new_x = self.x + step;

            // Check collision at new position
            const collision = tilemap.checkCollision(
                new_x + 1, // Inset hitbox slightly
                self.y,
                self.width - 2,
                self.height,
            );

            if (collision.left or collision.right) {
                self.vel_x = 0;
                self.sub_x = 0;
                break;
            }

            self.x = new_x;
        }
    }

    fn moveY(self: *PlatformerPlayer, amount: i32, tilemap: *TileMap) void {
        if (amount == 0) return;

        const step: i32 = if (amount > 0) 1 else -1;
        var remaining = @abs(amount);

        self.on_ground = false;

        while (remaining > 0) : (remaining -= 1) {
            const new_y = self.y + step;

            // Check collision at new position
            const collision = tilemap.checkCollision(
                self.x + 1,
                new_y,
                self.width - 2,
                self.height,
            );

            if (step > 0 and collision.bottom) {
                // Landing on ground
                self.y = collision.bottom_y - self.height;
                self.vel_y = 0;
                self.sub_y = 0;
                self.on_ground = true;
                break;
            }

            if (step < 0 and collision.top) {
                // Hit ceiling
                self.y = collision.top_y;
                self.vel_y = 0;
                self.sub_y = 0;

                // Check if hit a question block
                if (collision.hit_tile) |tile| {
                    if (tile.tile_type == .Question and !tile.hit) {
                        tile.hit = true;
                        self.score += 100;
                        // TODO: Spawn coin or power-up
                    } else if (tile.tile_type == .Brick and self.is_big) {
                        // Break brick if big Mario
                        tile.tile_type = .Empty;
                        self.score += 50;
                    }
                }
                break;
            }

            self.y = new_y;
        }
    }

    fn updateState(self: *PlatformerPlayer) void {
        if (self.state == .Dead) return;

        if (!self.on_ground) {
            if (self.vel_y < 0) {
                self.state = .Jumping;
            } else {
                self.state = .Falling;
            }
        } else if (self.input_duck) {
            self.state = .Ducking;
        } else if (@abs(self.vel_x) > 10) {
            self.state = .Walking;
        } else {
            self.state = .Idle;
        }
    }

    fn updateAnimation(self: *PlatformerPlayer) void {
        const anim_name: []const u8 = switch (self.state) {
            .Idle => "idle",
            .Walking => "walk",
            .Jumping, .Falling => "jump",
            .Ducking => "duck",
            .Dead => "idle",
        };

        // Check if we need to change animation
        if (self.sprite.active_animation) |current| {
            if (!std.mem.eql(u8, current, anim_name)) {
                self.sprite.startAnimation(anim_name) catch {};
            }
        } else {
            self.sprite.startAnimation(anim_name) catch {};
        }

        self.sprite.stepActiveAnimation();
    }

    /// Get center position for camera tracking
    pub fn getCenterX(self: *PlatformerPlayer) i32 {
        return self.x + @divTrunc(self.width, 2);
    }

    pub fn getCenterY(self: *PlatformerPlayer) i32 {
        return self.y + @divTrunc(self.height, 2);
    }

    /// Render player at screen position
    pub fn render(
        self: *PlatformerPlayer,
        allocator: std.mem.Allocator,
        camera: *Camera,
    ) !void {
        // Skip rendering during invincibility flicker
        if (self.is_invincible and (self.invincible_timer % 4) < 2) {
            return;
        }

        const screen_pos = camera.worldToScreen(self.x, self.y);

        // Handle facing direction (flip sprite if facing left)
        self.sprite.setXY(screen_pos.x, screen_pos.y);

        // Get current frame surface
        var surface = try self.sprite.getCurrentFrameSurface();

        // Flip horizontally if facing left
        if (self.direction == .Left) {
            surface.flip_h = true;
        } else {
            surface.flip_h = false;
        }

        try self.screen.addRenderSurface(allocator, surface);
    }

    /// Take damage
    pub fn takeDamage(self: *PlatformerPlayer) void {
        if (self.is_invincible) return;

        if (self.is_big) {
            self.is_big = false;
            self.is_invincible = true;
            self.invincible_timer = 120; // 2 seconds at 60fps
        } else {
            self.lives -= 1;
            if (self.lives == 0) {
                self.state = .Dead;
            } else {
                self.is_invincible = true;
                self.invincible_timer = 120;
            }
        }
    }

    /// Collect power-up
    pub fn collectPowerUp(self: *PlatformerPlayer) void {
        if (!self.is_big) {
            self.is_big = true;
            self.height = 32; // Bigger hitbox
        }
        self.score += 1000;
    }

    /// Stomp on enemy (bounce)
    pub fn bounceOffEnemy(self: *PlatformerPlayer) void {
        self.vel_y = -600; // Bounce force
        self.score += 100;
    }

    /// Set spawn position
    pub fn setPosition(self: *PlatformerPlayer, x: i32, y: i32) void {
        self.x = x;
        self.y = y;
        self.vel_x = 0;
        self.vel_y = 0;
        self.sub_x = 0;
        self.sub_y = 0;
    }
};
