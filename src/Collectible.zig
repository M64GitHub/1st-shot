const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TileMap = @import("TileMap.zig").TileMap;
const Camera = @import("Camera.zig").Camera;

/// Collectible type
pub const CollectibleType = enum {
    Coin,
    Mushroom,
    Star,
};

/// Collectible state
pub const CollectibleState = enum {
    Idle,
    Rising,     // Emerging from block
    Moving,     // Mushroom moving
    Collected,
};

/// Single collectible item
pub const Collectible = struct {
    x: i32 = 0,
    y: i32 = 0,
    start_y: i32 = 0,

    vel_x: i32 = 0,
    vel_y: i32 = 0,
    sub_x: i32 = 0,
    sub_y: i32 = 0,

    width: i32 = 12,
    height: i32 = 16,

    collectible_type: CollectibleType = .Coin,
    state: CollectibleState = .Idle,
    active: bool = false,

    // Animation
    anim_frame: usize = 0,
    anim_timer: usize = 0,

    // Physics (for mushroom)
    direction: i32 = 1,
    move_speed: i32 = 100,
    gravity: i32 = 50,
    max_fall_speed: i32 = 500,

    // Coin bounce effect
    bounce_height: i32 = 0,
    bounce_timer: usize = 0,

    pub fn spawn(
        self: *Collectible,
        x: i32,
        y: i32,
        collectible_type: CollectibleType,
    ) void {
        self.x = x;
        self.y = y;
        self.start_y = y;
        self.collectible_type = collectible_type;
        self.active = true;
        self.anim_frame = 0;
        self.anim_timer = 0;
        self.vel_x = 0;
        self.vel_y = 0;

        self.width = switch (collectible_type) {
            .Coin => 12,
            .Mushroom => 16,
            .Star => 16,
        };

        // Coins animate but don't move
        // Mushrooms/stars emerge then move
        self.state = switch (collectible_type) {
            .Coin => .Idle,
            .Mushroom, .Star => .Rising,
        };

        if (collectible_type == .Mushroom or collectible_type == .Star) {
            self.vel_y = -150; // Rise out of block
        }
    }

    /// Spawn coin with bounce animation (from hitting block)
    pub fn spawnBouncing(self: *Collectible, x: i32, y: i32) void {
        self.x = x;
        self.y = y - 32; // Start above block
        self.start_y = y;
        self.collectible_type = .Coin;
        self.active = true;
        self.state = .Rising;
        self.bounce_timer = 0;
        self.vel_y = -400; // Bounce up
    }

    pub fn update(self: *Collectible, tilemap: *TileMap) void {
        if (!self.active) return;

        // Update animation
        self.anim_timer += 1;
        if (self.anim_timer >= 6) {
            self.anim_timer = 0;
            self.anim_frame = (self.anim_frame + 1) % 4;
        }

        switch (self.state) {
            .Idle => {
                // Coins just animate
            },
            .Rising => {
                self.updateRising(tilemap);
            },
            .Moving => {
                self.updateMoving(tilemap);
            },
            .Collected => {
                self.active = false;
            },
        }
    }

    fn updateRising(self: *Collectible, tilemap: *TileMap) void {
        if (self.collectible_type == .Coin) {
            // Bouncing coin effect
            self.vel_y += 30;
            self.sub_y += self.vel_y;
            const move_y = @divTrunc(self.sub_y, 100);
            self.sub_y = @mod(self.sub_y, 100);
            self.y += move_y;

            self.bounce_timer += 1;
            if (self.bounce_timer >= 30 or self.y >= self.start_y) {
                self.state = .Collected;
            }
        } else {
            // Mushroom/star rising from block
            self.vel_y += 10;
            self.sub_y += self.vel_y;
            const move_y = @divTrunc(self.sub_y, 100);
            self.sub_y = @mod(self.sub_y, 100);
            self.y += move_y;

            if (self.y >= self.start_y - 16) {
                self.y = self.start_y - 16;
                self.state = .Moving;
                self.vel_y = 0;
                self.vel_x = self.direction * self.move_speed;
            }
        }

        _ = tilemap;
    }

    fn updateMoving(self: *Collectible, tilemap: *TileMap) void {
        // Apply gravity
        self.vel_y += self.gravity;
        self.vel_y = @min(self.vel_y, self.max_fall_speed);

        // Horizontal movement
        self.vel_x = self.direction * self.move_speed;

        // Apply velocity
        self.sub_x += self.vel_x;
        self.sub_y += self.vel_y;

        const move_x = @divTrunc(self.sub_x, 100);
        const move_y = @divTrunc(self.sub_y, 100);

        self.sub_x = @mod(self.sub_x, 100);
        self.sub_y = @mod(self.sub_y, 100);

        // Horizontal collision
        if (move_x != 0) {
            const new_x = self.x + move_x;
            const collision = tilemap.checkCollision(
                new_x,
                self.y,
                self.width,
                self.height,
            );

            if (collision.left or collision.right) {
                self.direction = -self.direction;
            } else {
                self.x = new_x;
            }
        }

        // Vertical collision
        if (move_y != 0) {
            const new_y = self.y + move_y;
            const collision = tilemap.checkCollision(
                self.x,
                new_y,
                self.width,
                self.height,
            );

            if (collision.bottom) {
                self.y = collision.bottom_y - self.height;
                self.vel_y = 0;
                self.sub_y = 0;
            } else {
                self.y = new_y;
            }
        }

        // Deactivate if fallen off screen
        if (self.y > 500) {
            self.active = false;
        }
    }

    /// Called when player collects this item
    pub fn collect(self: *Collectible) void {
        self.state = .Collected;
    }

    /// Get score value
    pub fn getScoreValue(self: *Collectible) usize {
        return switch (self.collectible_type) {
            .Coin => 200,
            .Mushroom => 1000,
            .Star => 1000,
        };
    }
};

/// Manager for collectibles
pub const CollectibleManager = struct {
    collectibles: [MaxCollectibles]Collectible,
    coin_sprite: *Sprite,
    mushroom_sprite: *Sprite,
    star_sprite: *Sprite,
    screen: *movy.Screen,
    allocator: std.mem.Allocator,

    pub const MaxCollectibles = 32;

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*CollectibleManager {
        const self = try allocator.create(CollectibleManager);

        // Load sprites
        var coin = try Sprite.initFromPng(
            allocator,
            "assets/collectible_coin.png",
            "coin",
        );
        try coin.splitByWidth(allocator, 12);
        try coin.addAnimation(
            allocator,
            "spin",
            Sprite.FrameAnimation.init(0, 3, .loopForward, 6),
        );

        var mushroom = try Sprite.initFromPng(
            allocator,
            "assets/powerup_mushroom.png",
            "mushroom",
        );

        var star = try Sprite.initFromPng(
            allocator,
            "assets/powerup_star.png",
            "star",
        );
        try star.splitByWidth(allocator, 16);
        try star.addAnimation(
            allocator,
            "flash",
            Sprite.FrameAnimation.init(0, 3, .loopForward, 4),
        );

        self.* = CollectibleManager{
            .collectibles = [_]Collectible{.{}} ** MaxCollectibles,
            .coin_sprite = coin,
            .mushroom_sprite = mushroom,
            .star_sprite = star,
            .screen = screen,
            .allocator = allocator,
        };

        return self;
    }

    pub fn deinit(self: *CollectibleManager) void {
        self.coin_sprite.deinit(self.allocator);
        self.mushroom_sprite.deinit(self.allocator);
        self.star_sprite.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    /// Spawn a new collectible
    pub fn spawn(
        self: *CollectibleManager,
        x: i32,
        y: i32,
        collectible_type: CollectibleType,
    ) void {
        for (&self.collectibles) |*collectible| {
            if (!collectible.active) {
                collectible.spawn(x, y, collectible_type);
                return;
            }
        }
    }

    /// Spawn bouncing coin (from hitting block)
    pub fn spawnBouncingCoin(self: *CollectibleManager, x: i32, y: i32) void {
        for (&self.collectibles) |*collectible| {
            if (!collectible.active) {
                collectible.spawnBouncing(x, y);
                return;
            }
        }
    }

    /// Update all collectibles
    pub fn update(self: *CollectibleManager, tilemap: *TileMap) void {
        for (&self.collectibles) |*collectible| {
            collectible.update(tilemap);
        }
    }

    /// Render all collectibles
    pub fn render(
        self: *CollectibleManager,
        allocator: std.mem.Allocator,
        camera: *Camera,
    ) !void {
        for (&self.collectibles) |*collectible| {
            if (!collectible.active) continue;

            // Check visibility
            if (!camera.isVisible(
                collectible.x,
                collectible.y,
                collectible.width,
                collectible.height,
            )) continue;

            const screen_pos = camera.worldToScreen(collectible.x, collectible.y);

            const sprite = switch (collectible.collectible_type) {
                .Coin => self.coin_sprite,
                .Mushroom => self.mushroom_sprite,
                .Star => self.star_sprite,
            };

            // Update animation
            switch (collectible.collectible_type) {
                .Coin => {
                    sprite.startAnimation("spin") catch {};
                    sprite.stepActiveAnimation();
                },
                .Star => {
                    sprite.startAnimation("flash") catch {};
                    sprite.stepActiveAnimation();
                },
                .Mushroom => {},
            }

            sprite.setXY(screen_pos.x, screen_pos.y);
            const surface = try sprite.getCurrentFrameSurface();
            try self.screen.addRenderSurface(allocator, surface);
        }
    }

    /// Get active collectibles for collision checking
    pub fn getActiveCollectibles(self: *CollectibleManager) []Collectible {
        return &self.collectibles;
    }
};
