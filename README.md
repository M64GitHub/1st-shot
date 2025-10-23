# 1st-shot

```
 ██╗███████╗████████╗      ███████╗██╗  ██╗ ██████╗ ████████╗
███║██╔════╝╚══██╔══╝      ██╔════╝██║  ██║██╔═══██╗╚══██╔══╝
╚██║███████╗   ██║   █████╗███████╗███████║██║   ██║   ██║
 ██║╚════██║   ██║   ╚════╝╚════██║██╔══██║██║   ██║   ██║
 ██║███████║   ██║         ███████║██║  ██║╚██████╔╝   ██║
 ╚═╝╚══════╝   ╚═╝         ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝
```

## **Next-Generation Terminal Bullet Hell**

*Authentic Commodore 64 SID music. Subpixel-smooth sprite animation. Explosions and bonus points. All in your terminal.*

---

## 🎮 What Makes This Next-Gen?

This isn't your typical ASCII roguelike. **1st-shot** pushes terminal gaming into uncharted territory with technology that rivals modern GUI games:

### 🎵 **Authentic SID Chip Music**
The **world's first terminal game** with real Commodore 64 SID chip emulation, running in a dedicated background thread. Experience the iconic sounds of the C64 era while you dodge bullets.

### 🔊 **Real-Time Audio Mixing**
Dynamic WAV sound effects seamlessly mixed into the SID music stream. Explosions, weapons, power-ups — all with zero audio interruption or glitches.

### ✨ **Subpixel-Smooth Animation**
Forget choppy ASCII movement. A custom subpixel accumulator system allows sprites to move at fractional pixel speeds, creating smooth motion at any velocity. Each sprite glides pixel-by-pixel with precise sub-frame positioning.

### 🎯 **Three Enemy Types with Distinct Behaviors**
Different enemy patterns with formation flying, state machines, and targeting:
- **SingleEnemy**: Straight or zigzag patterns with global wave sync
- **SwarmEnemy**: Snake-like formations that grow over time (up to 17 sprites!)
- **ShooterEnemy**: State machine behavior with projectile tracking and orphaned bullet mechanics

### 🎨 **True Sprite Graphics**
PNG sprite sheets with frame-based animation, not ASCII art. Object pooling prevents allocation overhead. Dual-buffered rendering eliminates flicker.

### 🚀 **Multi-Threaded Architecture**
Audio runs in its own thread, updating every 35ms independently of the game loop. No audio stutter, no frame drops.

### 💥 **Complete Game Engine**
- **8 explosion types**
- **200-star parallax starfield** with depth-based speed
- **Multiple weapon systems** (spread shot, default)
- **Shield mechanics** with visual overlays
- **Score-based progression** with auto-unlocking rewards
- **12-state game state machine** (pause, death, respawn, game over)

---

## 🕹️ Screenshots

```
┌──────────────────────────────────────────────────────────────┐
│  ◦     *         ●          ·       *              ·         │
│        ·     ●         ·          ◦        *                 │
│                                                               │
│              🛸                    🛸                         │
│                 ☄️                    ☄️                      │
│                                                               │
│                    👾 👾 👾 👾                                │
│                                                               │
│             ☄️            💎            ☄️                    │
│                                                               │
│                    🚀                                         │
│                                                               │
│  ·        *             ◦        ·           *        ·      │
│                                                               │
│  Lives: ❤️ ❤️ ❤️   Score: 12,450   Ammo: [██████░░] 87      │
└──────────────────────────────────────────────────────────────┘
```
*Actual game uses high-res PNG sprites rendered in 24-bit color*

---

## 🚀 Quick Start

### Requirements
- **Zig 0.14.0+**
- **SDL2** (for audio)
- Terminal with 24-bit color support (most modern terminals)

### Install

```bash
# Clone repository
git clone https://github.com/yourusername/1st-shot.git
cd 1st-shot

# Build (optimized for ReleaseFast)
zig build

# Run the game
zig build run-1st-shot
```

*Note: Dependencies (movy and zigreSID) are automatically fetched during build via Zig's package manager.*

### Controls

| Key | Action |
|-----|--------|
| **Arrow Keys** | Move ship |
| **Space** | Fire weapon |
| **P** | Pause / Unpause |
| **ESC** | Quit |

---

## 🎯 How to Play

### Survive the onslaught!

**Destroy enemies and asteroids** to earn points. **Collect power-ups** to upgrade your ship. **Avoid collision** or use shields to survive.

### Enemy Types

#### 🟢 **SingleEnemy** (250 pts)
- Simple but deadly
- Two movement patterns: Straight or Zigzag
- Unlocked from start
- Health: 5 hits

#### 🔵 **SwarmEnemy** (500 pts)
- Snake-like formations
- Grows longer the longer you survive (up to 17 segments!)
- Graduated amplitude creates mesmerizing wave patterns
- Unlocks at **1000 frames (~16 seconds)**
- Health: 15 hits (hit the head!)

#### 🔴 **ShooterEnemy** (350 pts)
- Advanced AI with state machine
- Fires two tracking projectiles at your position
- **Danger**: When destroyed, attached bullets become orphans and fall!
- Unlocks at **2000 frames (~33 seconds)**
- Health: 3 hits (shoot the bullets for instant kill!)

### Power-Ups

- 💎 **Ammo**: Refills spread weapon
- 🛡️ **Shield**: Temporary invincibility
- ❤️ **Extra Life**: Gain 1 life
- 🎯 **Score Bonus**: Instant points

### Dropstacles

Shoot these to collect rewards (but don't touch them!):
- **ShieldDrop** (25%)
- **LifeDrop** (20%)
- **AmmoDrop** (40%)
- **Jackpot** (5%): Shield + Life + 100 Ammo!

### Score Milestones

Reach these scores to auto-unlock bonuses:
- **3,000**: Ammo bonus
- **5,000**: Shield bonus
- **10,000**: Extra life

---

## 🔬 Technical Deep Dive

### How It Works

**1st-shot** combines several techniques to create a smooth terminal gaming experience:

#### **Subpixel Movement Algorithm**

Traditional terminal games move objects 1 cell at a time. We use a **fractional accumulator**:

```zig
self.speed_value += self.speed_adder;
while (self.speed_value >= self.speed_threshold) {
    self.speed_value -= self.speed_threshold;
    self.y += 1;  // Move one pixel
}
```

This allows speeds like **0.33 pixels/frame**, creating smooth motion impossible with frame-based movement.

#### **SID Chip Emulation Integration**

Using the **zigreSID** library, we emulate the legendary MOS Technology 6581/8580 SID chip:

```zig
// Background thread continuously fills audio buffer
fn playerThreadFunc() void {
    while (running) {
        player.update();  // Generate SID samples
        std.time.sleep(35_000_000);  // 35ms
    }
}
```

The `MixingDumpPlayer` wraps SID emulation + WAV mixing:
- Reads SID register dumps (`.dmp` format)
- Emulates authentic C64 sound synthesis
- Mixes WAV samples in real-time when effects trigger

#### **Sprite Pooling**

Pre-allocate sprite pools at startup, never allocate during gameplay:

```zig
// Example: ShooterEnemy pools
shooter_master_pool: 6 sprites (4 active + 2 surplus)
shooter_projectile_pool: 12 sprites (8 active + 4 surplus)
```

Benefits:
- Zero allocation overhead during gameplay
- Predictable memory usage
- No garbage collection pauses
- `get()` / `release()` pattern for instant reuse

#### **Multi-Threaded Audio**

Game loop: **~180 FPS** (~5600μs per frame including rendering and output)
Audio thread: **~28 FPS** (35ms update interval)

Runs independently, preventing audio glitches during heavy rendering.

#### **Manager Pattern Architecture**

Each game system is a dedicated manager:
- `EnemyManager` - Enemy behaviors and spawning
- `ObstacleManager` - Asteroid field
- `WeaponManager` - Player weapons
- `SoundManager` - Audio (optional, graceful degradation)
- `ExplosionManager` - Spawns as many as required, also delayed
- ... and 9 more!

Clean separation of concerns, easy to extend.

---

## 🛠️ Project Structure

```
1st-shot/
├── src/
│   ├── main.zig              # Entry point, game loop
│   ├── GameManager.zig       # Central orchestrator
│   ├── EnemyManager.zig      # Enemy behaviors & spawning
│   ├── SoundManager.zig      # Audio system
│   ├── SingleEnemy.zig       # Simple enemy type
│   ├── SwarmEnemy.zig        # Formation enemy type
│   ├── ShooterEnemy.zig      # Enemy with projectiles
│   ├── ObstacleManager.zig   # Asteroids
│   ├── PlayerShip.zig        # Player entity
│   ├── WeaponManager.zig     # Weapon systems
│   ├── ShieldManager.zig     # Shield mechanics
│   ├── ExplosionManager.zig  # Spawns Explosions
│   ├── Starfield.zig         # Background starfield
│   └── ... (12 more managers)
├── assets/
│   ├── *.png                 # Sprite sheets
│   └── audio/
│       ├── cnii.dmp          # SID music (register dump)
│       └── *.wav             # Sound effects
└─── build.zig                 # Build configuration
```

---

## 🏗️ Development

### Architecture Highlights

**Flicker-Free Rendering:**
```zig
while (true) {
    inner_loop += 1;
    poll_input();  // Every loop (responsive)

    if (inner_loop % 100 == 0) {
        update_game_state();
        render_everything();
        screen.output();  // Single output = no flicker
    } else {
        sleep(50μs);  // Fast polling
    }
}
```

**State Machine:**
- FadeIn → StartingInvincible → AlmostVulnerable → Playing
- Death loop: Dying → Respawning → FadeIn
- Pause transitions with fade effects
- Game over on lives == 0

**Collision Detection:**
- Inset-based AABB (adjustable hitboxes)
- Asymmetric insets for player ship (forgiving bottom, tight top)
- Props have negative inset (easier to collect)

### Adding New Enemies

1. Create enemy struct with state
2. Implement `update()` and collision methods
3. Add sprite pool to `EnemyManager`
4. Register in spawn system with unlock frame
5. Add collision detection in `GameManager`
6. Trigger sounds on destruction

### Adding Sound Effects

1. Add WAV file to `assets/audio/`
2. Add enum variant to `SoundEffectType`
3. Load in `SoundManager.init()`
4. Call `triggerSound()` at event locations

---

## 🔧 Dependencies

### Zig Libraries (by M64)

- **movy** - Terminal graphics library
  - Double-buffered screen rendering
  - PNG sprite loading and animation
  - Input handling (keyboard, mouse)
  - Color support (24-bit RGB)
  - Sprite pooling system

- **zigreSID** - SID chip emulator
  - MOS 6581/8580 emulation
  - DumpPlayer for .dmp files
  - MixingDumpPlayer for WAV mixing
  - SDL2 audio output

*Currently referenced locally during development. Will be published as Zig packages.*

### System Dependencies

- **SDL2** - Audio output and WAV loading
- **Zig 0.14.0+** - Build system and language

---

## 🎼 Why Zig?

This project showcases Zig's strengths:

- **C Interop**: Seamless SDL2 and C library integration
- **Manual Memory Control**: Zero GC, predictable performance
- **Comptime**: Type-safe sprite pools, efficient generics
- **Error Handling**: Explicit error propagation, no hidden exceptions
- **Performance**: ReleaseFast builds rival C++ performance
- **Safety**: Optional overflow checks, bounds checking in debug mode

---

## 🌟 Features

### What 1st-shot brings to terminal gaming:

- High-res PNG sprites with 24-bit color
- Subpixel movement system for smooth movements
- Authentic C64 SID chip music with dynamic sound effects
- Three enemy types with different behavior patterns
- Fully animated effects, shields, weapons, and power-ups
- Multi-threaded architecture for audio independence

---

## 📜 License

[Your License Here]

---

## 🙏 Credits

- **zigreSID** - SID chip emulation library
- **SDL2** - Simple DirectMedia Layer for audio
- **movy** - Custom terminal graphics library
- **SID music**: "CN II" by [Original Artist]

---

## 🚀 Join the Revolution

**1st-shot** proves that terminal gaming can be a serious platform for sophisticated game development. The limitations aren't in the medium — they're in our imagination.

*What will you build?*

---

**Made with ❤️ and Zig**
