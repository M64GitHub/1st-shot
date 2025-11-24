# 1ST-SHOT - Claude Code Reference

## Project Overview

**1ST-SHOT** is a terminal-based **Mario-style platformer** game written in **Zig 0.15.2**. The game renders 24-bit color PNG sprites directly in the terminal using the custom **movy** rendering engine.

> **Note**: This project was originally a bullet hell shooter and has been transformed into a horizontal scrolling platformer. The original shooter code files remain in the codebase for reference.

## Build & Run

```bash
# Build the project
zig build

# Run the platformer game
zig build run-1st-shot

# Run the subpixel movement demo
zig build run-demo-subpixel
```

### Requirements
- **Zig 0.15.2** (specified in `build.zig.zon`)
- **SDL2** (for audio playback - optional)
- Terminal with 24-bit color support

## Project Structure

```
1st-shot/
├── build.zig            # Zig build configuration
├── build.zig.zon        # Package dependencies
├── assets/              # Game assets
│   ├── audio/           # WAV sound effects and SID music dumps
│   ├── player.png       # Player spritesheet (6 frames)
│   ├── tile_*.png       # Tile sprites
│   ├── enemy_*.png      # Enemy spritesheets
│   ├── collectible_*.png# Coin animations
│   ├── powerup_*.png    # Power-up sprites
│   └── bg_*.png         # Background elements
├── scripts/
│   └── generate_platformer_assets.py  # Asset generation script
├── src/
│   ├── main.zig              # Entry point, main loop
│   ├── PlatformerGame.zig    # Main game orchestration
│   ├── PlatformerPlayer.zig  # Player with physics
│   ├── TileMap.zig           # Tile-based level system
│   ├── Camera.zig            # Horizontal scrolling camera
│   ├── PlatformerEnemy.zig   # Ground-based enemies
│   ├── Collectible.zig       # Coins, mushrooms, stars
│   └── ...                   # Legacy shooter files
└── Claude.md                 # This file
```

## Platformer Architecture

### Core Systems

| File | Purpose |
|------|---------|
| `main.zig` | Entry point, terminal setup, main loop (~71 FPS) |
| `PlatformerGame.zig` | Central orchestration, collisions, backgrounds, HUD |
| `Camera.zig` | Smooth-following horizontal scrolling viewport |

### Player System

| File | Purpose |
|------|---------|
| `PlatformerPlayer.zig` | Player physics (gravity, jumping, tile collision) |

Player features:
- Variable height jumping (hold to jump higher)
- Coyote time (grace period after leaving platform)
- Subpixel movement for smooth motion
- Power-up states (big Mario)
- Invincibility frames after damage

### Level System

| File | Purpose |
|------|---------|
| `TileMap.zig` | 2D tile grid, collision detection, tile rendering |

Tile types:
- `Ground` - Grass-topped ground blocks
- `Brick` - Breakable brick blocks
- `Question` - Question blocks (spawn coins/power-ups)
- `EmptyBlock` - Hit question blocks
- `PipeTopLeft/Right`, `PipeBodyLeft/Right` - Pipe tiles

### Enemy System

| File | Purpose |
|------|---------|
| `PlatformerEnemy.zig` | Ground enemies with patrol AI |

Enemy types:
- **Goomba** - Walks back and forth, squished when stomped
- **Koopa** - Turns into shell when stomped, can be kicked

### Collectible System

| File | Purpose |
|------|---------|
| `Collectible.zig` | Coins, mushrooms, stars |

Collectible types:
- **Coin** - Spinning animation, 200 points
- **Mushroom** - Moves horizontally, makes player big
- **Star** - Flashing animation, grants invincibility

## Controls

| Key | Action |
|-----|--------|
| Left/Right Arrows | Walk |
| Space or Up Arrow | Jump |
| Down Arrow | Duck |
| P | Pause/Unpause |
| ESC | Quit |

## Code Patterns

### TileMap Collision Detection

```zig
pub fn checkCollision(
    self: *TileMap,
    x: i32,
    y: i32,
    w: i32,
    h: i32,
) CollisionResult {
    var result = CollisionResult{};

    // Check all tiles overlapping bounding box
    const left_tile = @divTrunc(x, self.tile_size);
    const right_tile = @divTrunc(x + w - 1, self.tile_size);
    const top_tile = @divTrunc(y, self.tile_size);
    const bottom_tile = @divTrunc(y + h - 1, self.tile_size);

    // Check each tile for solidity...
    return result;
}
```

### Physics with Subpixel Precision

```zig
// Velocity and accumulator (scaled by 100)
vel_x: i32 = 0,
vel_y: i32 = 0,
sub_x: i32 = 0,
sub_y: i32 = 0,

fn applyVelocity(self: *Player) void {
    // Accumulate subpixel movement
    self.sub_x += self.vel_x;
    self.sub_y += self.vel_y;

    // Convert to pixel movement
    const move_x = @divTrunc(self.sub_x, 100);
    const move_y = @divTrunc(self.sub_y, 100);

    self.sub_x = @mod(self.sub_x, 100);
    self.sub_y = @mod(self.sub_y, 100);

    // Apply with collision detection...
}
```

### Variable Jump Height

```zig
// Jump tuning constants
jump_force: i32 = -900,           // Initial upward velocity
jump_hold_force: i32 = -30,       // Extra force while holding
max_jump_hold_time: i32 = 15,     // Max frames to boost jump

fn handleJumping(self: *Player) void {
    // Start jump
    if (self.input_jump and !self.jump_held and self.on_ground) {
        self.vel_y = self.jump_force;
        self.jump_held = true;
        self.jump_timer = self.max_jump_hold_time;
    }

    // Variable height (hold to jump higher)
    if (self.jump_held and self.input_jump and self.jump_timer > 0) {
        self.vel_y += self.jump_hold_force;
        self.jump_timer -= 1;
    }
}
```

### Camera Following with Dead Zone

```zig
pub fn follow(self: *Camera, target_x: i32, target_y: i32, velocity_x: i32) void {
    // Look-ahead based on movement direction
    const look_ahead: i32 = if (velocity_x > 0) 60 else if (velocity_x < 0) -60 else 0;

    self.target_x = target_x - @divTrunc(self.screen_width, 2) + look_ahead;

    // Only move camera outside dead zone
    const dx = self.target_x - self.x;
    if (@abs(dx) > self.dead_zone_x) {
        self.x += @as(i32, @intFromFloat(@as(f32, @floatFromInt(dx)) * self.smoothing));
    }

    self.clampToBounds();
}
```

### Level Data Format

```zig
const level_data =
    \\........................
    \\........?...BBB?BBB....
    \\........................
    \\####..........#########
    \\####..........#########
;

// Legend:
// . = Empty
// # = Ground
// B = Brick
// ? = Question block
// [ ] = Pipe top
// { } = Pipe body

tilemap.loadFromString(level_data);
```

### Enemy Stomp Detection

```zig
fn checkPlayerEnemyCollisions(self: *Game) void {
    for (&self.enemies.enemies) |*enemy| {
        if (!enemy.active) continue;

        if (checkOverlap(player_bounds, enemy_bounds)) {
            const player_bottom = self.player.y + self.player.height;
            const enemy_top = enemy.y + 4;
            const player_falling = self.player.vel_y > 0;

            if (player_falling and player_bottom <= enemy_top + 8) {
                // Stomp!
                enemy.stomp();
                self.player.bounceOffEnemy();
            } else {
                // Player hurt
                self.player.takeDamage();
            }
        }
    }
}
```

## Asset Generation

The platformer assets are generated programmatically using Python/Pillow:

```bash
# Generate all platformer assets
python3 scripts/generate_platformer_assets.py
```

Generated assets:
- `player.png` - 96x24 (6 frames: idle, walk1-3, jump, duck)
- `tile_ground.png` - 16x16
- `tile_brick.png` - 16x16
- `tile_question.png` - 64x16 (4 animation frames)
- `enemy_goomba.png` - 48x16 (walk1, walk2, squished)
- `enemy_koopa.png` - 48x24 (walk1, walk2, shell)
- `collectible_coin.png` - 48x16 (4 spin frames)
- `powerup_mushroom.png` - 16x16
- `powerup_star.png` - 64x16 (4 flash frames)
- `bg_cloud.png`, `bg_bush.png`, `bg_hill.png` - Background elements

## Physics Constants

```zig
// Player physics (PlatformerPlayer.zig)
gravity: i32 = 60,              // Subpixel gravity per frame
max_fall_speed: i32 = 800,      // Terminal velocity
jump_force: i32 = -900,         // Initial jump impulse
walk_accel: i32 = 50,           // Ground acceleration
walk_decel: i32 = 40,           // Ground friction
max_walk_speed: i32 = 350,      // Max horizontal speed
air_control: i32 = 30,          // Air acceleration

// Enemy physics
walk_speed: i32 = 80,           // Goomba/Koopa walk speed
shell_speed: i32 = 500,         // Kicked shell speed
```

## Tips for Development

1. **Tile coordinates**: World position to tile: `grid_x = world_x / TILE_SIZE`
2. **Collision insets**: Use small insets for forgiving collision boxes
3. **Subpixel precision**: Scale velocities by 100 for smooth sub-pixel movement
4. **Camera smoothing**: Use lerp factor (0.1) for smooth camera following
5. **Coyote time**: Allow 5-8 frames of jump grace after leaving platform
6. **Enemy patrol**: Enemies turn at walls and platform edges

## Legacy Shooter Files

The original bullet hell shooter code remains in the codebase:
- `GameManager.zig` - Original shooter orchestration
- `Ship.zig`, `PlayerShip.zig` - Shooter player
- `EnemyManager.zig`, `ShooterEnemy.zig` - Vertical shooter enemies
- `WeaponManager.zig`, `DefaultWeapon.zig`, `SpreadWeapon.zig` - Weapons
- `ShieldManager.zig`, `DefaultShield.zig`, `SpecialShield.zig` - Shields
- `Starfield.zig` - Vertical scrolling background
- `ExplosionManager.zig` - Explosion effects
- `SoundManager.zig` - SID music + WAV effects

These files can be referenced for patterns or reactivated if needed.
