const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TileMap = @import("TileMap.zig").TileMap;
const Camera = @import("Camera.zig").Camera;

/// Enemy type
pub const EnemyType = enum {
    Goomba,
    Koopa,
};

/// Enemy state
pub const EnemyState = enum {
    Walking,
    Squished,
    Shell,
    ShellMoving,
    Dead,
};

/// Single platformer enemy
pub const PlatformerEnemy = struct {
    x: i32 = 0,
    y: i32 = 0,

    vel_x: i32 = 0,
    vel_y: i32 = 0,
    sub_x: i32 = 0,
    sub_y: i32 = 0,

    width: i32 = 16,
    height: i32 = 16,

    enemy_type: EnemyType = .Goomba,
    state: EnemyState = .Walking,
    direction: i32 = -1, // -1 = left, 1 = right

    active: bool = false,
    squish_timer: usize = 0,

    // Movement
    walk_speed: i32 = 80,
    shell_speed: i32 = 500,
    gravity: i32 = 60,
    max_fall_speed: i32 = 600,

    // Animation
    walk_frame: usize = 0,
    walk_timer: usize = 0,

    pub fn spawn(self: *PlatformerEnemy, x: i32, y: i32, enemy_type: EnemyType) void {
        self.x = x;
        self.y = y;
        self.enemy_type = enemy_type;
        self.state = .Walking;
        self.active = true;
        self.direction = -1;
        self.vel_x = -self.walk_speed;
        self.vel_y = 0;

        self.height = switch (enemy_type) {
            .Goomba => 16,
            .Koopa => 24,
        };
    }

    pub fn update(self: *PlatformerEnemy, tilemap: *TileMap) void {
        if (!self.active) return;

        switch (self.state) {
            .Walking => self.updateWalking(tilemap),
            .Squished => self.updateSquished(),
            .Shell => {}, // Stationary shell does nothing
            .ShellMoving => self.updateShellMoving(tilemap),
            .Dead => {},
        }
    }

    fn updateWalking(self: *PlatformerEnemy, tilemap: *TileMap) void {
        // Apply gravity
        self.vel_y += self.gravity;
        self.vel_y = @min(self.vel_y, self.max_fall_speed);

        // Set horizontal velocity based on direction
        self.vel_x = self.direction * self.walk_speed;

        // Apply movement
        self.applyVelocity(tilemap);

        // Update animation
        self.walk_timer += 1;
        if (self.walk_timer >= 8) {
            self.walk_timer = 0;
            self.walk_frame = (self.walk_frame + 1) % 2;
        }
    }

    fn updateSquished(self: *PlatformerEnemy) void {
        self.squish_timer += 1;
        if (self.squish_timer >= 30) {
            self.active = false;
        }
    }

    fn updateShellMoving(self: *PlatformerEnemy, tilemap: *TileMap) void {
        // Apply gravity
        self.vel_y += self.gravity;
        self.vel_y = @min(self.vel_y, self.max_fall_speed);

        // Shell moves fast
        self.vel_x = self.direction * self.shell_speed;

        self.applyVelocity(tilemap);
    }

    fn applyVelocity(self: *PlatformerEnemy, tilemap: *TileMap) void {
        // Subpixel movement
        self.sub_x += self.vel_x;
        self.sub_y += self.vel_y;

        const move_x = @divTrunc(self.sub_x, 100);
        const move_y = @divTrunc(self.sub_y, 100);

        self.sub_x = @mod(self.sub_x, 100);
        self.sub_y = @mod(self.sub_y, 100);

        // Horizontal movement
        if (move_x != 0) {
            const new_x = self.x + move_x;

            const collision = tilemap.checkCollision(
                new_x,
                self.y,
                self.width,
                self.height,
            );

            if (collision.left or collision.right) {
                // Turn around
                self.direction = -self.direction;
                self.vel_x = -self.vel_x;
            } else {
                self.x = new_x;

                // Check for edge (don't walk off platforms) - only for walking state
                if (self.state == .Walking) {
                    const check_x = if (self.direction < 0)
                        self.x
                    else
                        self.x + self.width - 1;

                    const ground_below = tilemap.isSolidAt(check_x, self.y + self.height + 2);
                    if (!ground_below) {
                        self.direction = -self.direction;
                        self.vel_x = -self.vel_x;
                    }
                }
            }
        }

        // Vertical movement
        if (move_y != 0) {
            const step: i32 = if (move_y > 0) 1 else -1;
            var remaining = @abs(move_y);

            while (remaining > 0) : (remaining -= 1) {
                const new_y = self.y + step;

                const collision = tilemap.checkCollision(
                    self.x,
                    new_y,
                    self.width,
                    self.height,
                );

                if (step > 0 and collision.bottom) {
                    self.y = collision.bottom_y - self.height;
                    self.vel_y = 0;
                    self.sub_y = 0;
                    break;
                }

                if (step < 0 and collision.top) {
                    self.y = collision.top_y;
                    self.vel_y = 0;
                    self.sub_y = 0;
                    break;
                }

                self.y = new_y;
            }
        }
    }

    /// Called when player stomps on enemy
    pub fn stomp(self: *PlatformerEnemy) void {
        switch (self.enemy_type) {
            .Goomba => {
                self.state = .Squished;
                self.height = 4;
                self.squish_timer = 0;
            },
            .Koopa => {
                if (self.state == .Walking) {
                    self.state = .Shell;
                    self.height = 14;
                } else if (self.state == .Shell) {
                    self.state = .ShellMoving;
                    self.direction = 1; // Kick right by default
                }
            },
        }
    }

    /// Called when enemy hits player from side
    pub fn kickShell(self: *PlatformerEnemy, from_left: bool) void {
        if (self.state == .Shell) {
            self.state = .ShellMoving;
            self.direction = if (from_left) 1 else -1;
        }
    }

    /// Get bounding box for collision
    pub fn getBounds(self: *PlatformerEnemy) struct { x: i32, y: i32, w: i32, h: i32 } {
        return .{
            .x = self.x,
            .y = self.y,
            .w = self.width,
            .h = self.height,
        };
    }

    /// Check if enemy can hurt player
    pub fn canHurtPlayer(self: *PlatformerEnemy) bool {
        return self.active and (self.state == .Walking or self.state == .ShellMoving);
    }

    /// Check if enemy can be stomped
    pub fn canBeStooped(self: *PlatformerEnemy) bool {
        return self.active and (self.state == .Walking or self.state == .Shell);
    }
};

/// Manager for all platformer enemies
pub const PlatformerEnemyManager = struct {
    enemies: [MaxEnemies]PlatformerEnemy,
    goomba_sprite: *Sprite,
    koopa_sprite: *Sprite,
    screen: *movy.Screen,
    allocator: std.mem.Allocator,

    pub const MaxEnemies = 16;

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*PlatformerEnemyManager {
        const self = try allocator.create(PlatformerEnemyManager);

        // Load sprites
        var goomba = try Sprite.initFromPng(
            allocator,
            "assets/enemy_goomba.png",
            "goomba",
        );
        try goomba.splitByWidth(allocator, 16);
        try goomba.addAnimation(
            allocator,
            "walk",
            Sprite.FrameAnimation.init(0, 1, .loopForward, 8),
        );
        try goomba.addAnimation(
            allocator,
            "squished",
            Sprite.FrameAnimation.init(2, 2, .once, 1),
        );

        var koopa = try Sprite.initFromPng(
            allocator,
            "assets/enemy_koopa.png",
            "koopa",
        );
        try koopa.splitByWidth(allocator, 16);
        try koopa.addAnimation(
            allocator,
            "walk",
            Sprite.FrameAnimation.init(0, 1, .loopForward, 8),
        );
        try koopa.addAnimation(
            allocator,
            "shell",
            Sprite.FrameAnimation.init(2, 2, .once, 1),
        );

        self.* = PlatformerEnemyManager{
            .enemies = [_]PlatformerEnemy{.{}} ** MaxEnemies,
            .goomba_sprite = goomba,
            .koopa_sprite = koopa,
            .screen = screen,
            .allocator = allocator,
        };

        return self;
    }

    pub fn deinit(self: *PlatformerEnemyManager) void {
        self.goomba_sprite.deinit(self.allocator);
        self.koopa_sprite.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    /// Spawn a new enemy
    pub fn spawn(self: *PlatformerEnemyManager, x: i32, y: i32, enemy_type: EnemyType) void {
        for (&self.enemies) |*enemy| {
            if (!enemy.active) {
                enemy.spawn(x, y, enemy_type);
                return;
            }
        }
    }

    /// Update all enemies
    pub fn update(self: *PlatformerEnemyManager, tilemap: *TileMap) void {
        for (&self.enemies) |*enemy| {
            enemy.update(tilemap);
        }

        // Check shell collisions with other enemies
        for (&self.enemies) |*shell| {
            if (!shell.active or shell.state != .ShellMoving) continue;

            for (&self.enemies) |*other| {
                if (!other.active or other == shell) continue;
                if (other.state == .Squished or other.state == .Dead) continue;

                // Check collision
                if (checkOverlap(
                    shell.x,
                    shell.y,
                    shell.width,
                    shell.height,
                    other.x,
                    other.y,
                    other.width,
                    other.height,
                )) {
                    // Kill the other enemy
                    other.state = .Dead;
                    other.active = false;
                }
            }
        }
    }

    /// Render all enemies
    pub fn render(
        self: *PlatformerEnemyManager,
        allocator: std.mem.Allocator,
        camera: *Camera,
    ) !void {
        for (&self.enemies) |*enemy| {
            if (!enemy.active) continue;

            // Check if visible
            if (!camera.isVisible(enemy.x, enemy.y, enemy.width, enemy.height)) continue;

            const screen_pos = camera.worldToScreen(enemy.x, enemy.y);

            const sprite = switch (enemy.enemy_type) {
                .Goomba => self.goomba_sprite,
                .Koopa => self.koopa_sprite,
            };

            // Set animation based on state
            const anim: []const u8 = switch (enemy.state) {
                .Walking => "walk",
                .Squished, .Shell, .ShellMoving => if (enemy.enemy_type == .Goomba) "squished" else "shell",
                .Dead => continue,
            };

            sprite.startAnimation(anim) catch {};
            sprite.stepActiveAnimation();
            sprite.setXY(screen_pos.x, screen_pos.y);

            const surface = try sprite.getCurrentFrameSurface();

            // Flip based on direction
            surface.flip_h = enemy.direction > 0;

            try self.screen.addRenderSurface(allocator, surface);
        }
    }

    /// Get active enemies for collision checking
    pub fn getActiveEnemies(self: *PlatformerEnemyManager) []PlatformerEnemy {
        return &self.enemies;
    }
};

/// Helper function for overlap detection
fn checkOverlap(
    x1: i32,
    y1: i32,
    w1: i32,
    h1: i32,
    x2: i32,
    y2: i32,
    w2: i32,
    h2: i32,
) bool {
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2;
}
