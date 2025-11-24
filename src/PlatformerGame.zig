const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;
const TileMap = @import("TileMap.zig").TileMap;
const TileType = @import("TileMap.zig").TileType;
const Camera = @import("Camera.zig").Camera;
const PlatformerPlayer = @import("PlatformerPlayer.zig").PlatformerPlayer;
const PlatformerEnemyManager = @import("PlatformerEnemy.zig").PlatformerEnemyManager;
const PlatformerEnemy = @import("PlatformerEnemy.zig").PlatformerEnemy;
const EnemyType = @import("PlatformerEnemy.zig").EnemyType;
const CollectibleManager = @import("Collectible.zig").CollectibleManager;
const CollectibleType = @import("Collectible.zig").CollectibleType;
const Collectible = @import("Collectible.zig").Collectible;

/// Game state
pub const GameState = enum {
    Playing,
    Paused,
    PlayerDied,
    GameOver,
    LevelComplete,
};

/// Background element for parallax scrolling
const BackgroundElement = struct {
    sprite: *Sprite,
    x: i32,
    y: i32,
    parallax: f32, // 0.0 = static, 1.0 = moves with camera
};

/// Main platformer game
pub const PlatformerGame = struct {
    screen: *movy.Screen,
    allocator: std.mem.Allocator,

    // Core systems
    tilemap: *TileMap,
    camera: Camera,
    player: *PlatformerPlayer,
    enemies: *PlatformerEnemyManager,
    collectibles: *CollectibleManager,

    // Background sprites
    cloud_sprite: *Sprite,
    bush_sprite: *Sprite,
    hill_sprite: *Sprite,

    // Background elements
    clouds: [8]BackgroundElement,
    bushes: [12]BackgroundElement,
    hills: [6]BackgroundElement,

    // Game state
    state: GameState = .Playing,
    frame_counter: usize = 0,
    death_timer: usize = 0,

    // Level info
    level_width: usize,
    level_height: usize,

    // HUD
    msgbuf: [256]u8 = [_]u8{0} ** 256,

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*PlatformerGame {
        const self = try allocator.create(PlatformerGame);

        // Level dimensions (tiles)
        const level_width: usize = 200;
        const level_height: usize = 15;

        // Create tilemap
        const tilemap = try TileMap.init(
            allocator,
            level_width,
            level_height,
            screen,
        );

        // Load a sample level
        loadLevel1(tilemap);

        // Create camera
        const camera = Camera.init(
            @as(i32, @intCast(screen.w)),
            @as(i32, @intCast(screen.h)),
            @as(i32, @intCast(level_width)) * TileMap.TILE_SIZE,
            @as(i32, @intCast(level_height)) * TileMap.TILE_SIZE,
        );

        // Create player
        const player = try PlatformerPlayer.init(allocator, screen);
        player.setPosition(48, 176); // Starting position

        // Create enemy manager
        const enemies = try PlatformerEnemyManager.init(allocator, screen);

        // Create collectible manager
        const collectibles = try CollectibleManager.init(allocator, screen);

        // Load background sprites
        var cloud_sprite = try Sprite.initFromPng(
            allocator,
            "assets/bg_cloud.png",
            "cloud",
        );

        var bush_sprite = try Sprite.initFromPng(
            allocator,
            "assets/bg_bush.png",
            "bush",
        );

        var hill_sprite = try Sprite.initFromPng(
            allocator,
            "assets/bg_hill.png",
            "hill",
        );

        self.* = PlatformerGame{
            .screen = screen,
            .allocator = allocator,
            .tilemap = tilemap,
            .camera = camera,
            .player = player,
            .enemies = enemies,
            .collectibles = collectibles,
            .cloud_sprite = cloud_sprite,
            .bush_sprite = bush_sprite,
            .hill_sprite = hill_sprite,
            .clouds = undefined,
            .bushes = undefined,
            .hills = undefined,
            .level_width = level_width,
            .level_height = level_height,
        };

        // Initialize background elements
        self.initBackgrounds();

        // Spawn initial enemies and coins
        self.spawnLevelEntities();

        return self;
    }

    fn initBackgrounds(self: *PlatformerGame) void {
        // Place clouds at various positions
        var rng = std.Random.DefaultPrng.init(12345);
        const random = rng.random();

        for (&self.clouds, 0..) |*cloud, i| {
            cloud.* = BackgroundElement{
                .sprite = self.cloud_sprite,
                .x = @as(i32, @intCast(i)) * 400 + random.intRangeAtMost(i32, 0, 200),
                .y = random.intRangeAtMost(i32, 10, 60),
                .parallax = 0.3,
            };
        }

        // Hills (behind everything)
        for (&self.hills, 0..) |*hill, i| {
            hill.* = BackgroundElement{
                .sprite = self.hill_sprite,
                .x = @as(i32, @intCast(i)) * 500 + random.intRangeAtMost(i32, 0, 100),
                .y = @as(i32, @intCast(self.screen.h)) - 64 - 32,
                .parallax = 0.4,
            };
        }

        // Bushes (in front of hills)
        for (&self.bushes, 0..) |*bush, i| {
            bush.* = BackgroundElement{
                .sprite = self.bush_sprite,
                .x = @as(i32, @intCast(i)) * 280 + random.intRangeAtMost(i32, 0, 150),
                .y = @as(i32, @intCast(self.screen.h)) - 64 - 16,
                .parallax = 0.6,
            };
        }
    }

    fn spawnLevelEntities(self: *PlatformerGame) void {
        // Spawn some goombas
        self.enemies.spawn(320, 192, .Goomba);
        self.enemies.spawn(480, 192, .Goomba);
        self.enemies.spawn(640, 192, .Goomba);
        self.enemies.spawn(800, 192, .Koopa);
        self.enemies.spawn(1200, 192, .Goomba);
        self.enemies.spawn(1500, 192, .Koopa);

        // Spawn coins (placed in the level)
        self.collectibles.spawn(200, 160, .Coin);
        self.collectibles.spawn(220, 160, .Coin);
        self.collectibles.spawn(240, 160, .Coin);
        self.collectibles.spawn(500, 130, .Coin);
        self.collectibles.spawn(520, 130, .Coin);
        self.collectibles.spawn(900, 160, .Coin);
        self.collectibles.spawn(920, 160, .Coin);
        self.collectibles.spawn(940, 160, .Coin);
    }

    pub fn deinit(self: *PlatformerGame) void {
        self.tilemap.deinit();
        self.player.deinit(self.allocator);
        self.enemies.deinit();
        self.collectibles.deinit();
        self.cloud_sprite.deinit(self.allocator);
        self.bush_sprite.deinit(self.allocator);
        self.hill_sprite.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn onKeyDown(self: *PlatformerGame, key: movy.input.Key) void {
        if (self.state == .GameOver) {
            if (key.type == .Char and key.sequence[0] == ' ') {
                self.restart();
            }
            return;
        }

        if (key.type == .Char and key.sequence[0] == 'p') {
            self.state = if (self.state == .Paused) .Playing else .Paused;
            return;
        }

        self.player.onKeyDown(key);
    }

    pub fn onKeyUp(self: *PlatformerGame, key: movy.input.Key) void {
        self.player.onKeyUp(key);
    }

    pub fn update(self: *PlatformerGame) void {
        if (self.state == .Paused or self.state == .GameOver) return;

        if (self.state == .PlayerDied) {
            self.death_timer += 1;
            if (self.death_timer >= 90) {
                if (self.player.lives > 0) {
                    self.respawnPlayer();
                } else {
                    self.state = .GameOver;
                }
            }
            return;
        }

        // Update player
        self.player.update(self.tilemap);

        // Update camera to follow player
        self.camera.follow(
            self.player.getCenterX(),
            self.player.getCenterY(),
            self.player.vel_x,
        );

        // Update tilemap animations
        self.tilemap.update();

        // Update enemies
        self.enemies.update(self.tilemap);

        // Update collectibles
        self.collectibles.update(self.tilemap);

        // Check collisions
        self.checkPlayerEnemyCollisions();
        self.checkPlayerCollectibleCollisions();

        // Check if player fell off screen
        if (self.player.y > @as(i32, @intCast(self.level_height)) * TileMap.TILE_SIZE + 100) {
            self.playerDied();
        }

        self.frame_counter += 1;
    }

    fn checkPlayerEnemyCollisions(self: *PlatformerGame) void {
        const player_bounds = .{
            .x = self.player.x + 2,
            .y = self.player.y,
            .w = self.player.width - 4,
            .h = self.player.height,
        };

        for (&self.enemies.enemies) |*enemy| {
            if (!enemy.active) continue;
            if (!enemy.canHurtPlayer() and !enemy.canBeStooped()) continue;

            const enemy_bounds = enemy.getBounds();

            // Check overlap
            if (checkOverlap(
                player_bounds.x,
                player_bounds.y,
                player_bounds.w,
                player_bounds.h,
                enemy_bounds.x,
                enemy_bounds.y,
                enemy_bounds.w,
                enemy_bounds.h,
            )) {
                // Determine if stomp or hurt
                const player_bottom = self.player.y + self.player.height;
                const enemy_top = enemy.y + 4; // Slight tolerance
                const player_falling = self.player.vel_y > 0;

                if (player_falling and player_bottom <= enemy_top + 8 and enemy.canBeStooped()) {
                    // Stomp!
                    enemy.stomp();
                    self.player.bounceOffEnemy();
                } else if (enemy.canHurtPlayer()) {
                    // Player takes damage
                    self.player.takeDamage();
                    if (self.player.state == .Dead) {
                        self.playerDied();
                    }
                }
            }
        }
    }

    fn checkPlayerCollectibleCollisions(self: *PlatformerGame) void {
        const player_bounds = .{
            .x = self.player.x,
            .y = self.player.y,
            .w = self.player.width,
            .h = self.player.height,
        };

        for (&self.collectibles.collectibles) |*collectible| {
            if (!collectible.active) continue;
            if (collectible.state == .Rising and collectible.collectible_type == .Coin) {
                continue; // Don't collect bouncing coins
            }

            if (checkOverlap(
                player_bounds.x,
                player_bounds.y,
                player_bounds.w,
                player_bounds.h,
                collectible.x,
                collectible.y,
                collectible.width,
                collectible.height,
            )) {
                // Collect!
                self.player.score += collectible.getScoreValue();

                if (collectible.collectible_type == .Mushroom) {
                    self.player.collectPowerUp();
                }

                collectible.collect();
            }
        }
    }

    fn playerDied(self: *PlatformerGame) void {
        self.player.lives -= 1;
        self.state = .PlayerDied;
        self.death_timer = 0;
    }

    fn respawnPlayer(self: *PlatformerGame) void {
        self.player.setPosition(48, 176);
        self.player.state = .Idle;
        self.player.is_invincible = true;
        self.player.invincible_timer = 120;
        self.state = .Playing;
        self.camera.centerOn(self.player.getCenterX(), self.player.getCenterY());
    }

    fn restart(self: *PlatformerGame) void {
        self.player.lives = 3;
        self.player.score = 0;
        self.player.is_big = false;
        self.player.height = 24;
        self.respawnPlayer();
    }

    pub fn render(self: *PlatformerGame, allocator: std.mem.Allocator) !void {
        try self.screen.renderInit();

        // Render background (sky color is set in screen.bg_color)
        try self.renderBackgrounds(allocator);

        // Render tilemap
        try self.tilemap.render(allocator, self.camera.x, self.camera.y);

        // Render collectibles
        try self.collectibles.render(allocator, &self.camera);

        // Render enemies
        try self.enemies.render(allocator, &self.camera);

        // Render player
        if (self.state != .PlayerDied or (self.death_timer % 8) < 4) {
            try self.player.render(allocator, &self.camera);
        }

        // Render HUD
        try self.renderHUD();

        // Final render
        self.screen.render();
    }

    fn renderBackgrounds(self: *PlatformerGame, allocator: std.mem.Allocator) !void {
        const screen_w = @as(i32, @intCast(self.screen.w));

        // Render hills (furthest back)
        for (&self.hills) |*hill| {
            const parallax_x = @as(i32, @intFromFloat(
                @as(f32, @floatFromInt(self.camera.x)) * hill.parallax,
            ));
            const screen_x = hill.x - parallax_x;

            // Wrap around for infinite scrolling effect
            var wrapped_x = @mod(screen_x, screen_w + 64);
            if (wrapped_x < -64) wrapped_x += screen_w + 64;

            hill.sprite.setXY(wrapped_x, hill.y);
            const surface = try hill.sprite.getCurrentFrameSurface();
            try self.screen.addRenderSurface(allocator, surface);
        }

        // Render bushes
        for (&self.bushes) |*bush| {
            const parallax_x = @as(i32, @intFromFloat(
                @as(f32, @floatFromInt(self.camera.x)) * bush.parallax,
            ));
            const screen_x = bush.x - parallax_x;

            var wrapped_x = @mod(screen_x, screen_w + 48);
            if (wrapped_x < -48) wrapped_x += screen_w + 48;

            bush.sprite.setXY(wrapped_x, bush.y);
            const surface = try bush.sprite.getCurrentFrameSurface();
            try self.screen.addRenderSurface(allocator, surface);
        }

        // Render clouds (closest parallax layer before tiles)
        for (&self.clouds) |*cloud| {
            const parallax_x = @as(i32, @intFromFloat(
                @as(f32, @floatFromInt(self.camera.x)) * cloud.parallax,
            ));
            const screen_x = cloud.x - parallax_x;

            var wrapped_x = @mod(screen_x, screen_w + 48);
            if (wrapped_x < -48) wrapped_x += screen_w + 48;

            cloud.sprite.setXY(wrapped_x, cloud.y);
            const surface = try cloud.sprite.getCurrentFrameSurface();
            try self.screen.addRenderSurface(allocator, surface);
        }
    }

    fn renderHUD(self: *PlatformerGame) !void {
        const status = try std.fmt.bufPrint(
            &self.msgbuf,
            "SCORE: {d:>6}  LIVES: {d}  {s}",
            .{
                self.player.score,
                self.player.lives,
                switch (self.state) {
                    .Paused => "PAUSED",
                    .GameOver => "GAME OVER - PRESS SPACE",
                    .PlayerDied => "",
                    else => "",
                },
            },
        );

        _ = self.screen.output_surface.putStrXY(
            status,
            2,
            0,
            movy.color.WHITE,
            movy.color.BLACK,
        );
    }
};

/// Load level 1 data
fn loadLevel1(tilemap: *TileMap) void {
    // Level layout (row 0 is top, row 14 is bottom)
    // . = empty, # = ground, B = brick, ? = question block
    const level_data =
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\........................?...........BBB?BBB..........................?????......................................B?B?B..................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..................................................................................................................................................................................................................................................
        \\..........................................................................................................BBB...............................................................................................
        \\..................................................................................................................................................................................................................................................
        \\################..........###############..........######################..........##########################..........#######################################################............###############
        \\################..........###############..........######################..........##########################..........#######################################################............###############
    ;

    tilemap.loadFromString(level_data);
}

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
