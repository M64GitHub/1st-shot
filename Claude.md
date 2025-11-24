# 1ST-SHOT - Claude Code Reference

## Project Overview

**1ST-SHOT** is a terminal-based bullet hell shooter game written in **Zig 0.15.2**. The game renders 24-bit color PNG sprites directly in the terminal using the custom **movy** rendering engine. It features authentic C64 SID chip music emulation via **zigreSID** with real-time audio mixing.

## Build & Run

```bash
# Build the project
zig build

# Run the main game
zig build run-1st-shot

# Run the subpixel movement demo
zig build run-demo-subpixel
```

### Requirements
- **Zig 0.15.2** (specified in `build.zig.zon`)
- **SDL2** (for audio playback)
- Terminal with 24-bit color support

## Project Structure

```
1st-shot/
├── build.zig           # Zig build configuration
├── build.zig.zon       # Package dependencies
├── assets/             # Game assets
│   ├── audio/          # WAV sound effects and SID music dumps
│   └── *.png           # Sprite sheets and images
├── src/
│   ├── main.zig        # Entry point, main loop, input handling
│   ├── GameManager.zig # Central game orchestration
│   └── ...             # Game subsystems (see Architecture)
└── Claude.md           # This file
```

## Architecture

### Core Components

| File | Purpose |
|------|---------|
| `main.zig` | Entry point, terminal setup, main loop (~71 FPS), keyboard input |
| `GameManager.zig` | Orchestrates all game systems, collision detection, scoring |
| `GameStateManager.zig` | State machine (FadeIn, Playing, Paused, Dying, GameOver, etc.) |

### Entity Components

| File | Purpose |
|------|---------|
| `Ship.zig` | Base ship struct with sprites, position, orientation |
| `PlayerShip.zig` | Player-specific logic, animations, weapon integration |
| `ShipController.zig` | Input-to-movement translation |

### Enemy System

| File | Purpose |
|------|---------|
| `EnemyManager.zig` | Spawns and manages all enemy types with sprite pools |
| `ShooterEnemy.zig` | Enemy that fires projectiles at the player |

Enemy types:
- **SingleEnemy**: Basic enemy with straight or zigzag movement
- **SwarmEnemy**: Snake-like enemy with master + tail sprites
- **ShooterEnemy**: Advanced enemy that targets the player

### Weapons System

| File | Purpose |
|------|---------|
| `WeaponManager.zig` | Manages weapon types and switching |
| `DefaultWeapon.zig` | Standard projectile weapon (unlimited ammo) |
| `SpreadWeapon.zig` | Multi-projectile spread weapon (limited ammo) |

### Shields System

| File | Purpose |
|------|---------|
| `ShieldManager.zig` | Manages shield activation and cooldowns |
| `DefaultShield.zig` | Standard protective shield |
| `SpecialShield.zig` | Enhanced shield variant |

### Visual Effects

| File | Purpose |
|------|---------|
| `ExplosionManager.zig` | Pool-based explosion animations |
| `Starfield.zig` | Scrolling background star effect |
| `GameVisuals.zig` | UI overlays (GAME OVER, PAUSED text) |
| `VisualsManager.zig` | Manages timed visual effects |
| `TimedVisual.zig` | Fade in/out visual effects |
| `GameLogo.zig` | Animated game logo |
| `StatusWindow.zig` | UI status display |

### Collectibles & Obstacles

| File | Purpose |
|------|---------|
| `ObstacleManager.zig` | Asteroids and environmental hazards |
| `PropsManager.zig` | Collectible items (ammo, lives, shields, points) |
| `DropStacleManager.zig` | Destructible containers that drop rewards |

### Audio System

| File | Purpose |
|------|---------|
| `SoundManager.zig` | SDL2 audio, SID music, WAV sound effects |

### Utility

| File | Purpose |
|------|---------|
| `LogFile.zig` | Debug logging to `game.log` |

## Dependencies

Defined in `build.zig.zon`:

```zig
.dependencies = .{
    .movy = "https://github.com/M64GitHub/movy/archive/refs/tags/v0.1.0.tar.gz",
    .resid = "https://github.com/M64GitHub/zigreSID/archive/refs/tags/v0.5.0.tar.gz",
}
```

- **movy**: Terminal rendering engine (sprites, animations, surfaces)
- **zigreSID**: MOS 6581/8580 SID chip emulator with SDL audio

## Code Patterns

### Sprite Loading & Animation

```zig
// Load sprite from PNG
var sprite = try movy.graphic.Sprite.initFromPng(
    allocator,
    "assets/playership.png",
    "player",
);

// Slice into animation frames
try sprite.splitByWidth(allocator, 24);

// Define animation
try sprite.addAnimation(
    allocator,
    "idle",
    movy.graphic.Sprite.FrameAnimation.init(
        1,           // start frame
        4,           // end frame
        .loopForward,
        4,           // speed
    ),
);

// Start animation
try sprite.startAnimation("idle");
```

### Sprite Pooling

The game uses sprite pools for frequently spawned entities:

```zig
// Initialize pool
var pool = movy.graphic.SpritePool.init();

// Add sprites to pool
for (0..MaxEnemies) |_| {
    const s = try Sprite.initFromPng(allocator, path, name);
    try pool.addSprite(allocator, s);
}

// Acquire sprite from pool
const sprite = pool.get() orelse return;

// Release back to pool
pool.release(sprite);
```

### Entity Manager Pattern

Managers use fixed-size arrays for active entities:

```zig
pub const Manager = struct {
    active_entities: [MaxEntities]Entity,
    screen: *movy.Screen,

    pub fn update(self: *Manager) !void {
        for (&self.active_entities) |*entity| {
            if (!entity.active) continue;
            entity.update();
            // Deactivate if off-screen
            if (entity.y > self.screen.h) {
                entity.active = false;
                self.pool.release(entity.sprite);
            }
        }
    }

    pub fn addRenderSurfaces(self: *Manager, allocator: std.mem.Allocator) !void {
        for (&self.active_entities) |*entity| {
            if (entity.active) {
                try self.screen.addRenderSurface(
                    allocator,
                    try entity.sprite.getCurrentFrameSurface(),
                );
            }
        }
    }
};
```

### Collision Detection

```zig
inline fn checkCollision(
    a: *movy.Sprite,
    b: *movy.Sprite,
    inset: i32,
) bool {
    const a_w: i32 = @intCast(a.w);
    const a_h: i32 = @intCast(a.h);
    const b_w: i32 = @intCast(b.w);
    const b_h: i32 = @intCast(b.h);

    return a.x < b.x + b_w - inset and
           a.x + a_w > b.x + inset and
           a.y < b.y + b_h - inset and
           a.y + a_h > b.y + inset;
}
```

### Subpixel Movement (Fractional Speed)

For smooth movement at non-integer speeds:

```zig
speed_adder: usize = 0,    // Speed numerator
speed_value: usize = 0,    // Accumulator
speed_threshold: usize = 0, // Speed denominator

pub fn update(self: *Entity) void {
    self.speed_value += self.speed_adder;
    if (self.speed_value >= self.speed_threshold) {
        self.speed_value -= self.speed_threshold;
        self.y += 1; // Actual movement
    }
}
```

### Wave-Based Movement

```zig
const TrigWave = movy.animation.TrigWave;

// Zigzag horizontal movement
wave: TrigWave = TrigWave.init(duration, amplitude),

fn update(self: *Entity) void {
    self.x = self.start_x + self.wave.tickSine();
}
```

### Game State Machine

```zig
pub const GameState = enum {
    FadeIn,
    StartingInvincible,
    AlmostVulnerable,
    Playing,
    FadingToPause,
    Paused,
    FadingFromPause,
    Dying,
    Respawning,
    FadeToGameOver,
    GameOver,
};

pub fn transitionTo(self: *GameStateManager, new_state: GameState) void {
    self.state = new_state;
    self.frame_counter = 0;
    self.just_transitioned = true;
}
```

### Render Loop Pattern

```zig
// In GameManager.renderFrame()
try self.screen.renderInit();                      // Clear surfaces
try self.exploder.addRenderSurfaces(allocator);    // Add explosions
try self.player.ship.addRenderSurfaces(allocator); // Add player
// ... add other entities ...
self.screen.render();                              // Composite all
try self.screen.output();                          // Blast to terminal
```

## Game Constants

```zig
// Frame timing (main.zig)
const FRAME_DELAY_NS = 14 * std.time.ns_per_ms; // ~71 FPS

// Scoring milestones (GameManager.zig)
const Points_For_Ammo: usize = 3000;
const Points_For_Shield: usize = 5000;
const Points_For_Life: usize = 10000;
const Points_For_Dropstacle: usize = 4000;

// Player settings
const Lives = 3;
```

## Controls

| Key | Action |
|-----|--------|
| Arrow Left/Right | Move ship |
| Space | Fire weapon |
| W | Switch weapon |
| S | Activate shield |
| P / Up | Pause/Unpause |
| ESC | Quit |

### Cheat Codes (debug keys)
- `Z` - Spawn shield bonus
- `X` - Spawn points bonus
- `C` - Spawn extra life
- `V` - Spawn ammo bonus

## Debugging

The game writes debug logs to `game.log` via `LogFile.zig`:

```zig
log_file.log("[Component]", "Message: {}", .{value});
```

## Asset Naming Conventions

- `playership.png` - Player ship spritesheet
- `enemy_*.png` - Enemy spritesheets
- `explosion_*.png` - Explosion animations
- `prop_*.png` - Collectible items
- `dropstacle_*.png` - Destructible containers
- `shield_*.png` - Shield effects
- `projectiles_*.png` - Weapon projectiles

## Tips for Development

1. **No Zig in sandbox**: If Zig 0.15.2 is unavailable, use existing code patterns as reference
2. **Sprite dimensions**: Always use `splitByWidth()` to slice spritesheets
3. **Memory**: Use `std.heap.page_allocator` for simplicity
4. **Pool management**: Always release sprites back to pools when entities deactivate
5. **State transitions**: Use `justTransitioned()` for one-time initialization per state
6. **Sound effects**: Sound is optional - game continues if `SoundManager.init()` returns null
