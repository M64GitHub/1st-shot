const std = @import("std");
const movy = @import("movy");
const PlayerShip = @import("PlayerShip.zig").PlayerShip;
const WeaponManager = @import("WeaponManager.zig").WeaponManager;
const ShieldManager = @import("ShieldManager.zig").ShieldManager;
const GameStateManager = @import("GameStateManager.zig").GameStateManager;
const ExplosionManager = @import("ExplosionManager.zig").ExplosionManager;
const ExplosionType = @import("ExplosionManager.zig").ExplosionType;
const ObstacleManager = @import("ObstacleManager.zig").ObstacleManager;
const VisualsManager = @import("VisualsManager.zig").VisualsManager;
const GameVisuals = @import("GameVisuals.zig").GameVisuals;
const StatusWindow = @import("StatusWindow.zig").StatusWindow;
const Starfield = @import("Starfield.zig").Starfield;
const PropsManager = @import("PropsManager.zig").PropsManager;
const Prop = @import("PropsManager.zig").Prop;
const DropStacleManager = @import("DropStacleManager.zig").DropStacleManager;
const DropStacleType = @import("DropStacleManager.zig").DropStacleType;
const EnemyManager = @import("EnemyManager.zig").EnemyManager;
const PlayerCenter = @import("EnemyManager.zig").PlayerCenter;
const SoundManager = @import("SoundManager.zig").SoundManager;
const SoundEffectType = @import("SoundManager.zig").SoundEffectType;

const Lives = 3;
const Points_For_Ammo: usize = 3000;
const Points_For_Shield: usize = 5000;
const Points_For_Life: usize = 10000;

const Points_For_Dropstacle: usize = 4000;

pub const GameManager = struct {
    player: PlayerShip,
    gamestate: GameStateManager,
    shields: *ShieldManager,
    exploder: *ExplosionManager,
    obstacles: *ObstacleManager,
    enemies: *EnemyManager,
    visuals: GameVisuals,
    vismanager: VisualsManager,
    statuswin: StatusWindow,
    starfield: *Starfield,
    props: *PropsManager,
    dropstacles: *DropStacleManager,
    sound: ?*SoundManager,
    screen: *movy.Screen,
    frame_counter: usize = 0,

    msgbuf: [1024]u8 = [_]u8{0} ** 1024,
    message: []const u8 = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !GameManager {
        // Try to initialize sound manager (optional - game continues if it fails)
        const sound_manager = SoundManager.init(allocator);

        return GameManager{
            .player = try PlayerShip.init(allocator, screen, Lives),
            .gamestate = GameStateManager.init(),
            .statuswin = try StatusWindow.init(allocator, 16, 8, movy.color.DARK_BLUE, movy.color.GRAY),
            .starfield = try Starfield.init(allocator, screen),
            .props = try PropsManager.init(allocator, screen),
            .visuals = try GameVisuals.init(allocator, screen),
            .vismanager = VisualsManager.init(allocator, screen),
            .exploder = try ExplosionManager.init(allocator, screen),
            .obstacles = try ObstacleManager.init(allocator, screen),
            .enemies = try EnemyManager.init(allocator, screen),
            .dropstacles = try DropStacleManager.init(allocator, screen),
            .shields = try ShieldManager.init(allocator, screen),
            .sound = sound_manager,
            .screen = screen,
        };
    }

    pub fn deinit(self: *GameManager, allocator: std.mem.Allocator) void {
        self.player.deinit(allocator);
        self.exploder.deinit(allocator);
        self.obstacles.deinit(allocator);
        self.enemies.deinit(allocator);
        self.starfield.deinit(allocator);
        self.props.deinit(allocator);
        self.dropstacles.deinit(allocator);

        // Clean up sound manager if it was initialized
        if (self.sound) |sound| {
            sound.deinit();
            allocator.destroy(sound);
        }
    }

    pub fn onKeyDown(self: *GameManager, key: movy.input.Key) void {
        if (self.gamestate.state == .GameOver) {
            if (key.type == .Char and key.sequence[0] == ' ') {
                self.gamestate.transitionTo(.FadeIn);
                self.player.lives = Lives;

                if (self.visuals.game.visual) |visual| {
                    visual.stop();
                    self.visuals.game.visual = null;
                }
                if (self.visuals.over.visual) |visual| {
                    visual.stop();
                    self.visuals.over.visual = null;
                }
            }
            return;
        }
        if (!self.player.ship.visible) return;

        self.player.onKeyDown(key);

        if (key.type == .Char and key.sequence[0] == ' ') {
            self.player.tryFire();
            if (self.player.weapon_manager.just_fired) {
                if (self.sound) |sound|
                    sound.triggerSound(.Weapon1Fired);
            }
        }
        // switch weapon key
        if (key.type == .Char and key.sequence[0] == 'w') {
            self.switchWeapon();
        }

        // shield key
        if (key.type == .Char and key.sequence[0] == 's') {
            self.shields.activate(.Default);
            if (self.sound) |sound|
                sound.triggerSound(.ShieldActivated);
        }

        // pops test key
        if (key.type == .Char and key.sequence[0] == 'z') {
            _ = try self.props.spawnShieldBonus(self.player.ship.x, -10);
        }

        // pops test key
        if (key.type == .Char and key.sequence[0] == 'x') {
            _ = try self.props.spawnPointsBonus(self.player.ship.x, -10, 100);
        }

        // pops test key
        if (key.type == .Char and key.sequence[0] == 'c') {
            _ = try self.props.spawnExtraLife(self.player.ship.x, -10);
        }

        // pops test key
        if (key.type == .Char and key.sequence[0] == 'v') {
            _ = try self.props.spawnAmmoBonus(self.player.ship.x, -10, 500);
        }

        // pause key
        if (key.type == .Char and key.sequence[0] == 'p') {
            if (self.gamestate.state != .Paused and
                self.gamestate.state != .FadingToPause and
                self.gamestate.state != .FadingFromPause)
            {
                self.gamestate.transitionTo(.FadingToPause);
            }

            if (self.gamestate.state == .Paused) {
                self.gamestate.transitionTo(.FadingFromPause);
            }
        }
    }

    pub fn onKeyUp(self: *GameManager, key: movy.input.Key) void {
        self.player.onKeyUp(key);
    }

    // Handle game logic depending on state
    pub fn update(self: *GameManager, allocator: std.mem.Allocator) !void {
        switch (self.gamestate.state) {
            .FadeIn => {
                self.player.ship.visible = false;
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                self.starfield.update();
                try self.props.update();
                try self.dropstacles.update();
                // maybe animate screen brightness here
                // spawn the weapon
                const spawn_x = @as(i32, @intCast(self.screen.w / 2));
                if (self.gamestate.justTransitioned()) {
                    try self.dropstacles.trySpawn(spawn_x, -10, .AmmoDrop);
                }
            },
            .StartingInvincible, .AlmostVulnerable, .Playing => {
                if (self.gamestate.justTransitioned()) {
                    self.player.ship.visible = true;
                    if (self.gamestate.state == .Playing) {
                        self.shields.activate(.None);
                    }
                    if (self.gamestate.state == .StartingInvincible) {
                        self.shields.activate(.Default);
                        self.shields.default_shield.cooldown_ctr = 250;

                        if (self.sound) |sound|
                            sound.triggerSound(.ShieldActivated);
                    }
                    if (self.gamestate.state == .AlmostVulnerable) {}
                }
                try self.player.update();
                try self.shields.update(
                    self.player.ship.x,
                    self.player.ship.y,
                );
                try self.exploder.update();
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                self.starfield.update();
                try self.props.update();
                try self.dropstacles.update();
                self.doShipCollision();
                self.doEnemyShipCollision();
                self.doShooterEnemyShipCollision();
                self.doProjectileCollisions();
                self.doEnemyCollisions();
                self.doShooterEnemyCollisions();
                self.doDropStacleCollisions();
                self.handlePropCollision();
                self.handleDropCollision();
            },
            .Dying,
            => {
                if (self.gamestate.justTransitioned()) {
                    if (self.player.lives > 0)
                        self.player.lives -= 1;
                    self.player.ship.visible = false;
                    self.player.controller.reset();
                    self.shields.reset();
                }
                try self.player.weapon_manager.update();
                try self.exploder.update();
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                try self.dropstacles.update();
                self.starfield.update();
                try self.props.update();
                self.doProjectileCollisions();
                self.doEnemyCollisions();
                self.handlePropCollision();
                self.handleDropCollision();
            },
            .Respawning,
            => {
                // transition start
                if (self.player.lives == 0) {
                    self.gamestate.transitionTo(.FadeToGameOver);
                }
                try self.player.weapon_manager.update();
                try self.exploder.update();
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                try self.dropstacles.update();
                self.starfield.update();
                try self.props.update();
                self.doProjectileCollisions();
                self.doEnemyCollisions();
            },
            .FadeToGameOver => {
                if (self.gamestate.justTransitioned()) {
                    self.visuals.game.visual =
                        try self.vismanager.startSprite(
                            allocator,
                            self.visuals.game.sprite,
                            self.visuals.game.fade_in,
                            self.visuals.game.fade_out,
                        );
                    self.visuals.over.visual =
                        try self.vismanager.startSprite(
                            allocator,
                            self.visuals.over.sprite,
                            self.visuals.over.fade_in,
                            self.visuals.over.fade_out,
                        );
                }

                try self.player.weapon_manager.update();
                try self.exploder.update();
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                try self.dropstacles.update();
                self.starfield.update();
                try self.props.update();
                self.doProjectileCollisions();
                self.doEnemyCollisions();
            },
            .GameOver => {
                try self.player.weapon_manager.update();
                try self.exploder.update();
                try self.obstacles.update();
                const player_center_pos = self.player.ship.getCenterCoords();
                try self.enemies.updateWithPlayerCenter(PlayerCenter{ .x = player_center_pos.x, .y = player_center_pos.y });
                try self.dropstacles.update();
                self.starfield.update();
                try self.props.update();
                self.doProjectileCollisions();
                self.doEnemyCollisions();
            },
            .FadingToPause => {
                if (self.gamestate.justTransitioned()) {
                    self.visuals.paused.visual =
                        try self.vismanager.startSprite(
                            allocator,
                            self.visuals.paused.sprite,
                            self.visuals.paused.fade_in,
                            self.visuals.paused.fade_out,
                        );
                }
            },
            .FadingFromPause => {
                if (self.gamestate.justTransitioned()) {
                    if (self.visuals.paused.visual) |visual| {
                        visual.stop();
                        self.visuals.paused.visual = null;
                    }
                }
            },
            .Paused => {
                // don't update anything except screen dimming, pause visuals
            },
            else => {},
        }
        try self.vismanager.update(allocator, self.frame_counter);

        // Update state transitions or timers
        self.gamestate.update(self.frame_counter);

        self.frame_counter += 1;
    }

    // -- render
    pub fn renderFrame(self: *GameManager) !void {
        try self.screen.renderInit(); // clears output surfaces
        try self.exploder.addRenderSurfaces();
        try self.player.ship.addRenderSurfaces();
        try self.player.weapon_manager.addRenderSurfaces();
        try self.shields.addRenderSurfaces();
        try self.props.addRenderSurfaces();
        try self.dropstacles.addRenderSurfaces();
        try self.enemies.addRenderSurfaces();
        try self.obstacles.addRenderSurfaces();

        try self.screen.addRenderSurface(self.starfield.out_surface);
        self.screen.render();

        // VisualsManager adds its surfaces on demand, and dims, etc
        self.screen.output_surfaces.clearRetainingCapacity();
        try self.vismanager.addRenderSurfaces();
        self.screen.renderOnTop();

        self.message = try std.fmt.bufPrint(
            &self.msgbuf,
            "GameState: {s:>20} | Shield: {s} / Cooldown: {d} | Frame: {d}",
            .{
                @tagName(self.gamestate.state),
                @tagName(self.shields.active_shield),
                self.shields.getCooldown(),
                self.gamestate.frame_counter,
            },
        );
        _ = self.screen.output_surface.putStrXY(
            self.message,
            0,
            0,
            movy.color.LIGHT_BLUE,
            movy.color.BLACK,
        );

        try self.player.setMessage();
        if (self.player.message) |msg| {
            _ = self.screen.output_surface.putStrXY(
                msg,
                0,
                1,
                movy.color.LIGHT_BLUE,
                movy.color.BLACK,
            );
        }
    }

    pub fn switchWeapon(self: *GameManager) void {
        if (self.player.weapon_manager.active_weapon == .Default) {
            self.player.weapon_manager.switchWeapon(.Spread);
        } else {
            self.player.weapon_manager.switchWeapon(.Default);
        }
    }

    pub fn switchWeaponTo(self: *GameManager, t: WeaponManager.WeaponType) void {
        if (self.player.weapon_manager.active_weapon == t) return;

        self.player.weapon_manager.switchWeapon(t);
    }

    // -- collision logic

    // check collision of a with inset bounds of b
    inline fn checkCollision(
        a: *movy.Sprite,
        b: *movy.Sprite,
        inset: i32,
    ) bool {
        const a_w: i32 = @as(i32, @intCast(a.w));
        const a_h: i32 = @as(i32, @intCast(a.h));
        const b_w: i32 = @as(i32, @intCast(b.w));
        const b_h: i32 = @as(i32, @intCast(b.h));

        return a.x < b.x + b_w - inset and
            a.x + a_w > b.x + inset and
            a.y < b.y + b_h - inset and
            a.y + a_h > b.y + inset;
    }

    // check collision of a with individual inset bounds for a(x/y) and b
    inline fn checkCollisionShip(
        a: *movy.Sprite,
        b: *movy.Sprite,
        inset_ship_x: i32,
        inset_ship_y: i32,
        inset: i32,
    ) bool {
        const a_w: i32 = @as(i32, @intCast(a.w));
        const a_h: i32 = @as(i32, @intCast(a.h));
        const b_w: i32 = @as(i32, @intCast(b.w));
        const b_h: i32 = @as(i32, @intCast(b.h));

        var rv = a.x + inset_ship_x < b.x + b_w - inset and
            a.x + a_w - inset_ship_x > b.x + inset and
            a.y + inset_ship_y < b.y + b_h - inset and
            a.y + a_h - inset_ship_y > b.y + inset;

        // extra check for tip
        if (!rv) {
            const tip_x: i32 = a.x + @divTrunc(a_w, 2);
            rv = tip_x < b.x + b_w - inset * 4 and
                tip_x > b.x + inset * 4 and
                a.y < b.y + b_h - inset and
                a.y + a_h > b.y + inset;
        }

        return rv;
    }

    pub fn doProjectileCollisions(self: *GameManager) void {
        self.doDefaultWeaponCollisions();
        self.doSpreadWeaponCollisions();
    }

    pub fn doShipCollision(self: *GameManager) void {
        // check ship collision with obstacles:
        for (&self.obstacles.active_obstacles) |*obstacle| {
            if (!obstacle.active) continue;

            const coll_inset: i32 = switch (obstacle.kind) {
                .AsteroidSmall => 1,
                .AsteroidBig => 1,
                .AsteroidBig2 => 1,
                .AsteroidHuge => 2,
            };

            // check collision
            if (checkCollisionShip(
                self.player.ship.sprite_ship,
                obstacle.sprite,
                1,
                11,
                coll_inset,
            )) {
                const pos_ship = self.player.ship.getCenterCoords();
                const pos_obs = obstacle.getCenterCoords();
                var sign: i32 = 1;

                if (pos_ship.x < pos_obs.x) {
                    sign = -1;
                }
                if (self.shields.active_shield == .None) {
                    self.exodus(sign);
                } else {
                    if (obstacle.tryDestroy()) {
                        const exp_type: ExplosionType = switch (obstacle.kind) {
                            .AsteroidSmall => .Big,
                            .AsteroidBig => .Big,
                            .AsteroidBig2 => .Big,
                            .AsteroidHuge => .Huge,
                        };

                        self.exploder.tryExplode(
                            pos_obs.x,
                            pos_obs.y,
                            exp_type,
                        ) catch {};

                        if (self.sound) |sound| {
                            const et: SoundEffectType = switch (obstacle.kind) {
                                .AsteroidSmall => .ExplosionSmall,
                                .AsteroidBig, .AsteroidBig2 => .ExplosionBig,
                                .AsteroidHuge => .ExplosionHuge,
                            };
                            sound.triggerSound(et);
                        }

                        self.player.score += obstacle.score;

                        _ = self.props.spawnPointsBonus(
                            pos_obs.x - 6,
                            pos_obs.y - 3,
                            obstacle.score,
                        ) catch {};

                        // Check for milestone rewards
                        self.checkScoreMilestones();
                    }
                }
            }
        }
    }

    pub fn exodus(self: *GameManager, sign: i32) void {
        const pos_ship = self.player.ship.getCenterCoords();

        self.exploder.tryExplodeDelayed(
            pos_ship.x - 5 * sign,
            pos_ship.y - 5,
            .Small,
            0,
        ) catch {};

        self.exploder.tryExplodeDelayed(
            pos_ship.x + 5 * sign,
            pos_ship.y + 5,
            .Small,
            10,
        ) catch {};

        self.exploder.tryExplodeDelayed(
            pos_ship.x + 5 * sign,
            pos_ship.y - 5,
            .Small,
            20,
        ) catch {};

        self.exploder.tryExplodeDelayed(
            pos_ship.x - 5 * sign,
            pos_ship.y + 5,
            .Small,
            30,
        ) catch {};

        self.exploder.tryExplodeDelayed(
            pos_ship.x,
            pos_ship.y,
            .Huge,
            40,
        ) catch {};
        if (self.sound) |sound| sound.triggerSound(.ExplosionHuge);

        self.gamestate.transitionTo(.Dying);
    }

    pub fn doDefaultWeaponCollisions(self: *GameManager) void {
        // for all active projectiles: check collisions with: obstacles, enemies
        for (&self.player.weapon_manager.default_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            // check obstacle collisions
            for (&self.obstacles.active_obstacles) |*obstacle| {
                if (!obstacle.active) continue;

                const coll_inset: i32 = switch (obstacle.kind) {
                    .AsteroidSmall => 1,
                    .AsteroidBig => 3,
                    .AsteroidBig2 => 3,
                    .AsteroidHuge => 5,
                };

                // check collision
                if (checkCollision(proj.sprite, obstacle.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();
                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .Small,
                    ) catch {};

                    if (self.sound) |sound|
                        sound.triggerSound(.ExplosionSmall);

                    if (obstacle.tryDestroy()) {
                        const pos_obs = obstacle.getCenterCoords();

                        const exp_type: ExplosionType = switch (obstacle.kind) {
                            .AsteroidSmall => .Big,
                            .AsteroidBig => .Big,
                            .AsteroidBig2 => .Big,
                            .AsteroidHuge => .Huge,
                        };

                        self.exploder.tryExplode(
                            pos_obs.x,
                            pos_obs.y,
                            exp_type,
                        ) catch {};

                        if (self.sound) |sound| {
                            const et: SoundEffectType = switch (obstacle.kind) {
                                .AsteroidSmall => .ExplosionHuge,
                                .AsteroidBig, .AsteroidBig2 => .ExplosionHuge,
                                .AsteroidHuge => .ExplosionHuge,
                            };
                            sound.triggerSound(et);
                        }

                        self.player.score += obstacle.score;

                        _ = self.props.spawnPointsBonus(
                            pos_obs.x - 6,
                            pos_obs.y - 3,
                            obstacle.score,
                        ) catch {};

                        // Check for milestone rewards
                        self.checkScoreMilestones();
                    }
                }
            }
        }
    }

    pub fn doSpreadWeaponCollisions(self: *GameManager) void {
        // for all active projectiles: check collisions with: obstacles, enemies
        for (&self.player.weapon_manager.spread_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            // check obstacle collisions
            for (&self.obstacles.active_obstacles) |*obstacle| {
                if (!obstacle.active) continue;

                const coll_inset: i32 = switch (obstacle.kind) {
                    .AsteroidSmall => 1,
                    .AsteroidBig => 3,
                    .AsteroidBig2 => 3,
                    .AsteroidHuge => 5,
                };

                // check collision
                if (checkCollision(proj.sprite, obstacle.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();
                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    if (self.sound) |sound|
                        sound.triggerSound(.ExplosionSmall);

                    if (obstacle.tryDestroy()) {
                        const pos_obs = obstacle.getCenterCoords();

                        const exp_type: ExplosionType = switch (obstacle.kind) {
                            .AsteroidSmall => .Big,
                            .AsteroidBig => .Big,
                            .AsteroidBig2 => .Big,
                            .AsteroidHuge => .Huge,
                        };

                        self.exploder.tryExplode(
                            pos_obs.x,
                            pos_obs.y,
                            exp_type,
                        ) catch {};

                        if (self.sound) |sound| {
                            const et: SoundEffectType = switch (obstacle.kind) {
                                .AsteroidSmall => .ExplosionHuge,
                                .AsteroidBig, .AsteroidBig2 => .ExplosionHuge,
                                .AsteroidHuge => .ExplosionHuge,
                            };
                            sound.triggerSound(et);
                        }

                        self.player.score += obstacle.score;

                        _ = self.props.spawnPointsBonus(
                            pos_obs.x - 7,
                            pos_obs.y - 9,
                            obstacle.score,
                        ) catch {};

                        // Check for milestone rewards
                        self.checkScoreMilestones();
                    }
                }
            }
        }
    }

    pub fn handlePropCollision(self: *GameManager) void {
        // Check ship collision with props
        for (&self.props.active_props) |*prop| {
            if (!prop.active) continue;

            // Check collision between ship and prop (generous hitbox for pickups)
            const coll_inset: i32 = -2; // Negative inset = larger hitbox for easier pickup

            if (checkCollision(
                self.player.ship.sprite_ship,
                prop.sprite,
                coll_inset,
            )) {
                // Collect the prop and apply its effect
                self.applyPropEffect(prop);
                prop.collect();
            }
        }
    }

    pub fn handleDropCollision(self: *GameManager) void {
        // Check ship collision with props
        if (self.shields.active_shield != .None) return;

        for (&self.dropstacles.active_dropstacles) |*drop| {
            if (!drop.active) continue;

            // Check collision between ship and prop (generous hitbox for pickups)
            const coll_inset: i32 = -4; // Negative inset = larger hitbox for easier pickup

            if (checkCollision(
                self.player.ship.sprite_ship,
                drop.sprite,
                coll_inset,
            )) {
                self.exodus(1);

                const pos_drop = drop.getCenterCoords();

                // Bigger explosion when dropstacle is destroyed
                self.exploder.tryExplode(
                    pos_drop.x,
                    pos_drop.y,
                    .BigBlu,
                ) catch {};
                if (self.sound) |sound| sound.triggerSound(.ExplosionBig);
                drop.active = false;
            }
        }
    }

    pub fn applyPropEffect(self: *GameManager, prop: *Prop) void {
        switch (prop.kind) {
            .AmmoBonus => {
                // Add ammo to current weapon
                self.switchWeaponTo(.Spread);
                const current_ammo = self.player.weapon_manager.getAmmo();
                self.player.weapon_manager.setAmmo(current_ammo + prop.value);

                const pos = prop.getCenterCoords();
                self.exploder.tryExplode(pos.x, pos.y, .SmallPurple) catch {};
                if (self.sound) |sound| sound.triggerSound(.Collectible);
            },
            .ExtraLife => {
                self.player.lives += 1;

                const pos = prop.getCenterCoords();
                self.exploder.tryExplode(pos.x, pos.y, .SmallCyan) catch {};
                if (self.sound) |sound| sound.triggerSound(.Collectible);
            },
            .ShieldBonus => {
                self.shields.activate(.Default);

                if (self.sound) |sound|
                    sound.triggerSound(.ShieldActivated);

                const pos = prop.getCenterCoords();
                self.exploder.tryExplode(pos.x, pos.y, .SmallCyan) catch {};
                if (self.sound) |sound| sound.triggerSound(.Collectible);
            },
            .PointsBonus => {
                self.player.score += prop.value;

                const pos = prop.getCenterCoords();
                self.exploder.tryExplode(pos.x, pos.y, .Small) catch {};
                if (self.sound) |sound| sound.triggerSound(.Collectible);

                // Check for milestone rewards
                self.checkScoreMilestones();
            },
        }
    }

    pub fn checkScoreMilestones(self: *GameManager) void {
        const score = self.player.score;

        // Check for ammo bonus every X points
        const current_ammo_milestone = score / Points_For_Ammo;
        if (current_ammo_milestone > self.player.last_ammo_milestone) {
            // Spawn ammo at random position near top of screen
            const rand_x: i32 = self.obstacles.rng.random().intRangeAtMost(
                i32,
                20,
                @as(i32, @intCast(self.screen.w)) - 20,
            );
            _ = self.props.spawnAmmoBonus(rand_x, -10, 100) catch {};
            self.player.last_ammo_milestone = current_ammo_milestone;
        }

        // Check for shield bonus every X points
        const current_shield_milestone = score / Points_For_Shield;
        if (current_shield_milestone > self.player.last_shield_milestone) {
            // Spawn shield at random position near top of screen
            const rand_x: i32 = self.obstacles.rng.random().intRangeAtMost(
                i32,
                20,
                @as(i32, @intCast(self.screen.w)) - 20,
            );
            _ = self.props.spawnShieldBonus(rand_x, -10) catch {};
            self.player.last_shield_milestone = current_shield_milestone;
        }

        // Check for extra life every X points
        const current_life_milestone = score / Points_For_Life;
        if (current_life_milestone > self.player.last_life_milestone) {
            // Spawn life at random position near top of screen
            const rand_x: i32 = self.obstacles.rng.random().intRangeAtMost(
                i32,
                20,
                @as(i32, @intCast(self.screen.w)) - 20,
            );
            _ = self.props.spawnExtraLife(rand_x, -10) catch {};
            self.player.last_life_milestone = current_life_milestone;
        }

        // Check for extra life every X points
        const current_dropstacle_milestone = score / Points_For_Dropstacle;
        if (current_dropstacle_milestone > self.player.last_dropstacle_milestone) {
            // Spawn life at random position near top of screen
            self.dropstacles.spawnOne() catch {};
            self.player.last_dropstacle_milestone = current_dropstacle_milestone;
        }
    }

    // Add to GameManager.zig

    pub fn doDropStacleCollisions(self: *GameManager) void {
        // Check default weapon collisions
        for (&self.player.weapon_manager.default_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.dropstacles.active_dropstacles) |*dropstacle| {
                if (!dropstacle.active) continue;

                // Generous hitbox for dropstacles (easier to hit)
                const coll_inset: i32 = 0;

                if (checkCollision(proj.sprite, dropstacle.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    // Small explosion at projectile hit
                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    if (dropstacle.tryDestroy()) {
                        const pos_drop = dropstacle.getCenterCoords();

                        // Bigger explosion when dropstacle is destroyed
                        self.exploder.tryExplode(
                            pos_drop.x,
                            pos_drop.y,
                            .BigBlu,
                        ) catch {};

                        // Spawn props based on dropstacle type
                        self.spawnDropStacleReward(
                            pos_drop.x - 8,
                            pos_drop.y - 6,
                            dropstacle.kind,
                        );
                    }
                }
            }
        }

        // Check spread weapon collisions
        for (&self.player.weapon_manager.spread_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.dropstacles.active_dropstacles) |*dropstacle| {
                if (!dropstacle.active) continue;

                const coll_inset: i32 = 0;

                if (checkCollision(proj.sprite, dropstacle.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    if (dropstacle.tryDestroy()) {
                        const pos_drop = dropstacle.getCenterCoords();

                        self.exploder.tryExplode(
                            pos_drop.x,
                            pos_drop.y,
                            .BigBlu,
                        ) catch {};

                        self.spawnDropStacleReward(
                            pos_drop.x - 8,
                            pos_drop.y - 6,
                            dropstacle.kind,
                        );
                    }
                }
            }
        }
    }

    pub fn spawnDropStacleReward(
        self: *GameManager,
        x: i32,
        y: i32,
        kind: DropStacleType,
    ) void {
        switch (kind) {
            .ShieldDrop => {
                // Spawn shield prop
                _ = self.props.spawnShieldBonus(x, y) catch {};
            },
            .LifeDrop => {
                // Spawn extra life prop
                _ = self.props.spawnExtraLife(x, y) catch {};
            },
            .AmmoDrop => {
                // Spawn ammo prop (50-100 ammo)
                const ammo_amount = self.dropstacles.rng.random().intRangeAtMost(u32, 50, 100);
                _ = self.props.spawnAmmoBonus(x, y, ammo_amount) catch {};
            },
            .SpecialWeapon => {
                // Spawn special weapon prop with 50 ammo
                // TODO: Implement when special weapon system is ready
                _ = self.props.spawnAmmoBonus(x, y, 50) catch {};
            },
            .Jackpot => {
                // JACKPOT! Spawn ALL THREE props with slight offset
                _ = self.props.spawnShieldBonus(x - 8, y) catch {};
                _ = self.props.spawnExtraLife(x, y) catch {};
                _ = self.props.spawnAmmoBonus(x + 8, y, 100) catch {};

                // Extra big explosion for jackpot!
                self.exploder.tryExplode(x, y, .Huge) catch {};
                if (self.sound) |sound| sound.triggerSound(.ExplosionHuge);
            },
        }
    }

    // -- Enemy collision with player ship
    pub fn doEnemyShipCollision(self: *GameManager) void {
        // Check SingleEnemy collisions
        for (&self.enemies.active_single_enemies) |*enemy| {
            if (!enemy.active) continue;

            const coll_inset: i32 = 1;

            if (checkCollisionShip(
                self.player.ship.sprite_ship,
                enemy.sprite,
                1,
                11,
                coll_inset,
            )) {
                const pos_ship = self.player.ship.getCenterCoords();
                const pos_enemy = enemy.getCenterCoords();
                var sign: i32 = 1;

                if (pos_ship.x < pos_enemy.x) {
                    sign = -1;
                }

                if (self.shields.active_shield == .None) {
                    self.exodus(sign);
                } else {
                    // Destroy enemy on shield collision
                    enemy.active = false;
                    self.enemies.single_enemy_pool.release(enemy.sprite);

                    // Explosion
                    self.exploder.tryExplode(
                        pos_enemy.x,
                        pos_enemy.y,
                        .Big,
                    ) catch {};
                }
            }
        }

        // Check SwarmEnemy collisions
        for (&self.enemies.active_swarm_enemies) |*swarm| {
            if (!swarm.active) continue;

            const coll_inset: i32 = 1;

            // Check collision with master
            if (checkCollisionShip(
                self.player.ship.sprite_ship,
                swarm.master_sprite,
                1,
                11,
                coll_inset,
            )) {
                const pos_ship = self.player.ship.getCenterCoords();
                const pos_swarm = swarm.getCenterCoords();
                var sign: i32 = 1;

                if (pos_ship.x < pos_swarm.x) {
                    sign = -1;
                }

                if (self.shields.active_shield == .None) {
                    self.exodus(sign);
                } else {
                    // Destroy swarm on shield collision
                    swarm.active = false;
                    for (0..swarm.tail_count) |i| {
                        swarm.tail_pool.release(swarm.tail_sprites[i]);
                    }
                    swarm.tail_pool.release(swarm.master_sprite);

                    // Explosion
                    self.exploder.tryExplode(
                        pos_swarm.x,
                        pos_swarm.y,
                        .Big,
                    ) catch {};
                }
                continue;
            }

            // Check collision with tail sprites
            for (0..swarm.tail_count) |i| {
                if (checkCollisionShip(
                    self.player.ship.sprite_ship,
                    swarm.tail_sprites[i],
                    1,
                    11,
                    coll_inset,
                )) {
                    const pos_ship = self.player.ship.getCenterCoords();
                    const tail_sprite = swarm.tail_sprites[i];
                    const s_w: i32 = @as(i32, @intCast(tail_sprite.w));
                    const s_h: i32 = @as(i32, @intCast(tail_sprite.h));
                    const pos_tail = .{
                        .x = tail_sprite.x + @divTrunc(s_w, 2),
                        .y = tail_sprite.y + @divTrunc(s_h, 2),
                    };
                    var sign: i32 = 1;

                    if (pos_ship.x < pos_tail.x) {
                        sign = -1;
                    }

                    if (self.shields.active_shield == .None) {
                        self.exodus(sign);
                    } else {
                        // Destroy swarm on shield collision
                        swarm.active = false;
                        for (0..swarm.tail_count) |j| {
                            swarm.tail_pool.release(swarm.tail_sprites[j]);
                        }
                        swarm.tail_pool.release(swarm.master_sprite);

                        // Explosion
                        self.exploder.tryExplode(
                            pos_tail.x,
                            pos_tail.y,
                            .Big,
                        ) catch {};
                    }
                    break;
                }
            }
        }
    }

    // -- Enemy collision with player bullets
    pub fn doEnemyCollisions(self: *GameManager) void {
        // Check default weapon against SingleEnemy
        for (&self.player.weapon_manager.default_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_single_enemies) |*enemy| {
                if (!enemy.active) continue;

                const coll_inset: i32 = 1;

                if (checkCollision(proj.sprite, enemy.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    // Small explosion at hit
                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .Small,
                    ) catch {};

                    if (enemy.tryDestroy()) {
                        const pos_enemy = enemy.getCenterCoords();

                        // Big explosion when destroyed
                        self.exploder.tryExplode(
                            pos_enemy.x,
                            pos_enemy.y,
                            .Big,
                        ) catch {};
                        if (self.sound) |sound| sound.triggerSound(.ExplosionBig);

                        self.player.score += enemy.score;

                        _ = self.props.spawnPointsBonus(
                            pos_enemy.x - 6,
                            pos_enemy.y - 3,
                            enemy.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }

        // Check spread weapon against SingleEnemy
        for (&self.player.weapon_manager.spread_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_single_enemies) |*enemy| {
                if (!enemy.active) continue;

                const coll_inset: i32 = 1;

                if (checkCollision(proj.sprite, enemy.sprite, coll_inset)) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    if (enemy.tryDestroy()) {
                        const pos_enemy = enemy.getCenterCoords();

                        self.exploder.tryExplode(
                            pos_enemy.x,
                            pos_enemy.y,
                            .Big,
                        ) catch {};

                        self.player.score += enemy.score;

                        _ = self.props.spawnPointsBonus(
                            pos_enemy.x - 6,
                            pos_enemy.y - 3,
                            enemy.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }

        // Check default weapon against SwarmEnemy
        for (&self.player.weapon_manager.default_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_swarm_enemies) |*swarm| {
                if (!swarm.active) continue;

                const coll_inset: i32 = 1;
                var hit = false;
                var hit_pos_x: i32 = undefined;
                var hit_pos_y: i32 = undefined;

                // Check master
                if (checkCollision(proj.sprite, swarm.master_sprite, coll_inset)) {
                    hit = true;
                    const center = swarm.getCenterCoords();
                    hit_pos_x = center.x;
                    hit_pos_y = center.y;
                }

                // Check tail sprites
                if (!hit) {
                    for (0..swarm.tail_count) |i| {
                        if (checkCollision(proj.sprite, swarm.tail_sprites[i], coll_inset)) {
                            hit = true;
                            const tail_sprite = swarm.tail_sprites[i];
                            const s_w: i32 = @as(i32, @intCast(tail_sprite.w));
                            const s_h: i32 = @as(i32, @intCast(tail_sprite.h));
                            hit_pos_x = tail_sprite.x + @divTrunc(s_w, 2);
                            hit_pos_y = tail_sprite.y + @divTrunc(s_h, 2);
                            break;
                        }
                    }
                }

                if (hit) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .Small,
                    ) catch {};

                    if (swarm.tryDestroy()) {
                        // Get all positions before destroying
                        const positions = swarm.getAllSpritePositions();

                        // Explosion for each sprite
                        for (0..(swarm.tail_count + 1)) |i| {
                            self.exploder.tryExplode(
                                positions[i].x,
                                positions[i].y,
                                .Big,
                            ) catch {};
                        }

                        self.player.score += swarm.score;

                        _ = self.props.spawnPointsBonus(
                            hit_pos_x - 6,
                            hit_pos_y - 3,
                            swarm.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }

        // Check spread weapon against SwarmEnemy
        for (&self.player.weapon_manager.spread_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_swarm_enemies) |*swarm| {
                if (!swarm.active) continue;

                const coll_inset: i32 = 1;
                var hit = false;
                var hit_pos_x: i32 = undefined;
                var hit_pos_y: i32 = undefined;

                // Check master
                if (checkCollision(proj.sprite, swarm.master_sprite, coll_inset)) {
                    hit = true;
                    const center = swarm.getCenterCoords();
                    hit_pos_x = center.x;
                    hit_pos_y = center.y;
                }

                // Check tail sprites
                if (!hit) {
                    for (0..swarm.tail_count) |i| {
                        if (checkCollision(proj.sprite, swarm.tail_sprites[i], coll_inset)) {
                            hit = true;
                            const tail_sprite = swarm.tail_sprites[i];
                            const s_w: i32 = @as(i32, @intCast(tail_sprite.w));
                            const s_h: i32 = @as(i32, @intCast(tail_sprite.h));
                            hit_pos_x = tail_sprite.x + @divTrunc(s_w, 2);
                            hit_pos_y = tail_sprite.y + @divTrunc(s_h, 2);
                            break;
                        }
                    }
                }

                if (hit) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    if (swarm.tryDestroy()) {
                        // Get all positions before destroying
                        const positions = swarm.getAllSpritePositions();

                        // Explosion for each sprite
                        for (0..(swarm.tail_count + 1)) |i| {
                            self.exploder.tryExplode(
                                positions[i].x,
                                positions[i].y,
                                .Big,
                            ) catch {};
                        }

                        self.player.score += swarm.score;

                        _ = self.props.spawnPointsBonus(
                            hit_pos_x - 6,
                            hit_pos_y - 3,
                            swarm.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }
    }

    // -- ShooterEnemy collision with player ship
    pub fn doShooterEnemyShipCollision(self: *GameManager) void {
        for (&self.enemies.active_shooter_enemies) |*shooter| {
            const coll_inset: i32 = 1;

            // Check collision with launched projectiles (including orphaned ones)
            // This must be checked ALWAYS, even if shooter is inactive (for orphaned projectiles)
            for (&shooter.launched_projectiles) |*launched| {
                if (!launched.active) continue;

                if (checkCollisionShip(
                    self.player.ship.sprite_ship,
                    launched.sprite,
                    1,
                    11,
                    coll_inset,
                )) {
                    const pos_ship = self.player.ship.getCenterCoords();
                    const pos_launched = launched.getCenterCoords();
                    var sign: i32 = 1;

                    if (pos_ship.x < pos_launched.x) {
                        sign = -1;
                    }

                    if (self.shields.active_shield == .None) {
                        self.exodus(sign);
                    } else {
                        // Deactivate launched projectile on shield hit
                        launched.active = false;

                        // If orphaned, release sprite since parent is gone
                        if (launched.orphaned) {
                            launched.sprite_pool.release(launched.sprite);
                            launched.ever_used = false;
                            launched.orphaned = false;
                        }

                        self.exploder.tryExplode(
                            pos_launched.x,
                            pos_launched.y,
                            .Small,
                        ) catch {};
                    }
                    break;
                }
            }

            // Skip remaining checks if shooter is inactive (master and attached projectiles)
            if (!shooter.active) continue;

            // Check collision with master sprite
            if (checkCollisionShip(
                self.player.ship.sprite_ship,
                shooter.master_sprite,
                1,
                11,
                coll_inset,
            )) {
                const pos_ship = self.player.ship.getCenterCoords();
                const pos_shooter = shooter.getCenterCoords();
                var sign: i32 = 1;

                if (pos_ship.x < pos_shooter.x) {
                    sign = -1;
                }

                if (self.shields.active_shield == .None) {
                    self.exodus(sign);
                } else {
                    // Destroy shooter on shield collision and release sprites
                    shooter.release(&self.enemies.shooter_master_pool, &self.enemies.shooter_projectile_pool);

                    // Explosion
                    self.exploder.tryExplode(
                        pos_shooter.x,
                        pos_shooter.y,
                        .Big,
                    ) catch {};
                }
                continue;
            }

            // Check collision with attached projectiles
            if (shooter.left_projectile) |left_proj| {
                if (checkCollisionShip(
                    self.player.ship.sprite_ship,
                    left_proj,
                    1,
                    11,
                    coll_inset,
                )) {
                    const pos_ship = self.player.ship.getCenterCoords();
                    const s_w: i32 = @as(i32, @intCast(left_proj.w));
                    const s_h: i32 = @as(i32, @intCast(left_proj.h));
                    const pos_proj = .{
                        .x = left_proj.x + @divTrunc(s_w, 2),
                        .y = left_proj.y + @divTrunc(s_h, 2),
                    };
                    var sign: i32 = 1;

                    if (pos_ship.x < pos_proj.x) {
                        sign = -1;
                    }

                    if (self.shields.active_shield == .None) {
                        self.exodus(sign);
                    } else {
                        // Destroy shooter on shield collision with attached projectile
                        shooter.release(&self.enemies.shooter_master_pool, &self.enemies.shooter_projectile_pool);

                        // Explosion
                        self.exploder.tryExplode(
                            pos_proj.x,
                            pos_proj.y,
                            .Big,
                        ) catch {};
                    }
                    continue;
                }
            }

            if (shooter.right_projectile) |right_proj| {
                if (checkCollisionShip(
                    self.player.ship.sprite_ship,
                    right_proj,
                    1,
                    11,
                    coll_inset,
                )) {
                    const pos_ship = self.player.ship.getCenterCoords();
                    const s_w: i32 = @as(i32, @intCast(right_proj.w));
                    const s_h: i32 = @as(i32, @intCast(right_proj.h));
                    const pos_proj = .{
                        .x = right_proj.x + @divTrunc(s_w, 2),
                        .y = right_proj.y + @divTrunc(s_h, 2),
                    };
                    var sign: i32 = 1;

                    if (pos_ship.x < pos_proj.x) {
                        sign = -1;
                    }

                    if (self.shields.active_shield == .None) {
                        self.exodus(sign);
                    } else {
                        // Destroy shooter on shield collision with attached projectile
                        shooter.release(&self.enemies.shooter_master_pool, &self.enemies.shooter_projectile_pool);

                        // Explosion
                        self.exploder.tryExplode(
                            pos_proj.x,
                            pos_proj.y,
                            .Big,
                        ) catch {};
                    }
                    continue;
                }
            }
        }
    }

    // -- ShooterEnemy collision with player bullets
    pub fn doShooterEnemyCollisions(self: *GameManager) void {
        // Check default weapon against ShooterEnemy
        for (&self.player.weapon_manager.default_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_shooter_enemies) |*shooter| {
                if (!shooter.active) continue;

                const coll_inset: i32 = 1;
                var hit = false;
                var hit_projectile = false; // Track if we hit a projectile vs master
                var hit_pos_x: i32 = undefined;
                var hit_pos_y: i32 = undefined;

                // Check master
                if (checkCollision(proj.sprite, shooter.master_sprite, coll_inset)) {
                    hit = true;
                    hit_projectile = false;
                    const center = shooter.getCenterCoords();
                    hit_pos_x = center.x;
                    hit_pos_y = center.y;
                }

                // Check attached projectiles
                if (!hit) {
                    if (shooter.left_projectile) |left_proj| {
                        if (checkCollision(proj.sprite, left_proj, coll_inset)) {
                            hit = true;
                            hit_projectile = true;
                            const s_w: i32 = @as(i32, @intCast(left_proj.w));
                            const s_h: i32 = @as(i32, @intCast(left_proj.h));
                            hit_pos_x = left_proj.x + @divTrunc(s_w, 2);
                            hit_pos_y = left_proj.y + @divTrunc(s_h, 2);
                        }
                    }
                }

                if (!hit) {
                    if (shooter.right_projectile) |right_proj| {
                        if (checkCollision(proj.sprite, right_proj, coll_inset)) {
                            hit = true;
                            hit_projectile = true;
                            const s_w: i32 = @as(i32, @intCast(right_proj.w));
                            const s_h: i32 = @as(i32, @intCast(right_proj.h));
                            hit_pos_x = right_proj.x + @divTrunc(s_w, 2);
                            hit_pos_y = right_proj.y + @divTrunc(s_h, 2);
                        }
                    }
                }

                if (hit) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .Small,
                    ) catch {};

                    // reverted: Hitting a projectile deals more damage (instant kill with threshold 2)
                    const damage = if (hit_projectile) @as(usize, 1) else @as(usize, 1);
                    if (shooter.tryDestroyWithDamage(damage)) {
                        const pos_shooter = shooter.getCenterCoords();

                        // Release sprites
                        shooter.release(&self.enemies.shooter_master_pool, &self.enemies.shooter_projectile_pool);

                        // Big explosion when destroyed
                        self.exploder.tryExplode(
                            pos_shooter.x,
                            pos_shooter.y,
                            .Big,
                        ) catch {};
                        if (self.sound) |sound| sound.triggerSound(.ExplosionBig);

                        self.player.score += shooter.score;

                        _ = self.props.spawnPointsBonus(
                            hit_pos_x - 6,
                            hit_pos_y - 3,
                            shooter.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }

        // Check spread weapon against ShooterEnemy
        for (&self.player.weapon_manager.spread_weapon.projectiles) |*proj| {
            if (!proj.active) continue;

            for (&self.enemies.active_shooter_enemies) |*shooter| {
                if (!shooter.active) continue;

                const coll_inset: i32 = 1;
                var hit = false;
                var hit_projectile = false; // Track if we hit a projectile vs master
                var hit_pos_x: i32 = undefined;
                var hit_pos_y: i32 = undefined;

                // Check master
                if (checkCollision(proj.sprite, shooter.master_sprite, coll_inset)) {
                    hit = true;
                    hit_projectile = false;
                    const center = shooter.getCenterCoords();
                    hit_pos_x = center.x;
                    hit_pos_y = center.y;
                }

                // Check attached projectiles
                if (!hit) {
                    if (shooter.left_projectile) |left_proj| {
                        if (checkCollision(proj.sprite, left_proj, coll_inset)) {
                            hit = true;
                            hit_projectile = true;
                            const s_w: i32 = @as(i32, @intCast(left_proj.w));
                            const s_h: i32 = @as(i32, @intCast(left_proj.h));
                            hit_pos_x = left_proj.x + @divTrunc(s_w, 2);
                            hit_pos_y = left_proj.y + @divTrunc(s_h, 2);
                        }
                    }
                }

                if (!hit) {
                    if (shooter.right_projectile) |right_proj| {
                        if (checkCollision(proj.sprite, right_proj, coll_inset)) {
                            hit = true;
                            hit_projectile = true;
                            const s_w: i32 = @as(i32, @intCast(right_proj.w));
                            const s_h: i32 = @as(i32, @intCast(right_proj.h));
                            hit_pos_x = right_proj.x + @divTrunc(s_w, 2);
                            hit_pos_y = right_proj.y + @divTrunc(s_h, 2);
                        }
                    }
                }

                if (hit) {
                    proj.release();
                    const pos_proj = proj.getCenterCoords();

                    self.exploder.tryExplode(
                        pos_proj.x,
                        pos_proj.y,
                        .SmallPurple,
                    ) catch {};

                    // Hitting a projectile deals more damage (instant kill with threshold 2)
                    const damage = if (hit_projectile) @as(usize, 2) else @as(usize, 1);
                    if (shooter.tryDestroyWithDamage(damage)) {
                        const pos_shooter = shooter.getCenterCoords();

                        // Release sprites
                        shooter.release(&self.enemies.shooter_master_pool, &self.enemies.shooter_projectile_pool);

                        // Big explosion when destroyed
                        self.exploder.tryExplode(
                            pos_shooter.x,
                            pos_shooter.y,
                            .Big,
                        ) catch {};
                        if (self.sound) |sound| sound.triggerSound(.ExplosionBig);

                        self.player.score += shooter.score;

                        _ = self.props.spawnPointsBonus(
                            hit_pos_x - 6,
                            hit_pos_y - 3,
                            shooter.score,
                        ) catch {};

                        self.checkScoreMilestones();
                    }
                }
            }
        }
    }
};
