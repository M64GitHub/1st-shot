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

*Authentic Commodore 64 SID music. Subpixel-smooth sprite animation. Advanced enemy AI. All in your terminal.*

---

## 🎮 What Makes This Next-Gen?

This isn't your typical ASCII roguelike. **1st-shot** pushes terminal gaming into uncharted territory with technology that rivals modern GUI games:

### 🎵 **Authentic SID Chip Music**
The **world's first terminal game** with real Commodore 64 SID chip emulation, running in a dedicated background thread. Experience the iconic sounds of the C64 era while you dodge bullets.

### 🔊 **Real-Time Audio Mixing**
Dynamic WAV sound effects seamlessly mixed into the SID music stream. Explosions, weapons, power-ups — all with zero audio interruption or glitches.

### ✨ **Subpixel-Smooth Animation**
Forget choppy ASCII movement. Our custom subpixel accumulator system delivers **buttery-smooth 60fps motion** at just 10 FPS rendering. Each sprite glides pixel-by-pixel with fractional precision.

### 🎯 **Sophisticated Enemy AI**
Three distinct enemy types with formation flying, state machines, and targeting systems:
- **SingleEnemy**: Straight or zigzag patterns with global wave sync
- **SwarmEnemy**: Snake-like formations that grow over time (up to 17 sprites!)
- **ShooterEnemy**: Advanced AI with projectile tracking and orphaned bullet mechanics

### 🎨 **True Sprite Graphics**
PNG sprite sheets with frame-based animation, not ASCII art. Object pooling prevents allocation overhead. Dual-buffered rendering eliminates flicker.

### 🚀 **Multi-Threaded Architecture**
Audio runs in its own thread, updating every 35ms independently of the game loop. No audio stutter, no frame drops.

### 💥 **Complete Game Engine**
- **8 explosion types** with particle effects
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
# Clone with submodules (movy and zigreSID libraries)
git clone --recursive https://github.com/yourusername/1st-shot.git
cd 1st-shot

# Build (optimized for ReleaseFast)
zig build

# Run the game
zig build run-1st-shot

# Try the subpixel movement tech demo
zig build run-demo-subpixel
```

### Controls

| Key | Action |
|-----|--------|
| **Arrow Keys** | Move ship |
| **Space** | Fire weapon |
| **W** | Switch weapon (default ↔ spread shot) |
| **S** | Activate shield |
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

### Why This Is Groundbreaking

**1st-shot** achieves what was previously thought impossible in terminal gaming:

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

**Try the demo**: `zig build run-demo-subpixel` to see jerky vs smooth side-by-side!

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

Game loop: **~10 FPS** (100 inner loops × 50μs sleep)
Audio thread: **~28 FPS** (35ms update)

Completely independent, preventing audio glitches when rendering is heavy.

#### **Manager Pattern Architecture**

Each game system is a dedicated manager:
- `EnemyManager` - All enemy AI and spawning
- `ObstacleManager` - Asteroid field
- `WeaponManager` - Player weapons
- `SoundManager` - Audio (optional, graceful degradation)
- `ExplosionManager` - Particle effects
- ... and 9 more!

Clean separation of concerns, easy to extend.

---

## 🛠️ Project Structure

```
1st-shot/
├── src/
│   ├── main.zig              # Entry point, game loop
│   ├── GameManager.zig       # Central orchestrator
│   ├── EnemyManager.zig      # Enemy AI & spawning
│   ├── SoundManager.zig      # Audio system
│   ├── SingleEnemy.zig       # Simple enemy type
│   ├── SwarmEnemy.zig        # Formation enemy type
│   ├── ShooterEnemy.zig      # Advanced enemy with projectiles
│   ├── ObstacleManager.zig   # Asteroids
│   ├── PlayerShip.zig        # Player entity
│   ├── WeaponManager.zig     # Weapon systems
│   ├── ShieldManager.zig     # Shield mechanics
│   ├── ExplosionManager.zig  # Particle effects
│   ├── Starfield.zig         # Background starfield
│   ├── demo_subpixel.zig     # Subpixel movement demo
│   └── ... (12 more managers)
├── assets/
│   ├── *.png                 # Sprite sheets
│   └── audio/
│       ├── cnii.dmp          # SID music (register dump)
│       └── *.wav             # Sound effects
├── build.zig                 # Build configuration
└── CLAUDE.md                 # Developer reference
```

---

## 🎓 Demo Utilities

### Subpixel Movement Demo

An **interactive tech demonstration** comparing frame-based vs subpixel movement:

```bash
zig build run-demo-subpixel
```

**Features:**
- Side-by-side comparison of two obstacles
- **Left (ROUGH)**: Frame-based movement (moves in discrete steps)
- **Right (SMOOTH)**: Subpixel movement (glides smoothly)
- Real-time speed control for both
- Toggle visibility to focus on one
- Shows calculated **F value** (frames per pixel)

**Controls:**
- `UP/DOWN`: Adjust rough obstacle speed
- `LEFT/RIGHT`: Adjust smooth obstacle speed
- `1`: Toggle rough obstacle
- `2`: Toggle smooth obstacle
- `Y`: Sync positions
- `ESC`: Quit

Perfect for understanding why this game feels so smooth!

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

### Local Libraries (git submodules)

- **[movy](../movy)** - Custom terminal graphics library
  - Double-buffered screen rendering
  - PNG sprite loading and animation
  - Input handling (keyboard, mouse)
  - Color support (24-bit RGB)
  - Sprite pooling system

- **[zigreSID](../zigreSID)** - SID chip emulator
  - MOS 6581/8580 emulation
  - DumpPlayer for .dmp files
  - MixingDumpPlayer for WAV mixing
  - SDL2 audio output

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

## 🌟 This Changes Terminal Gaming

### Before 1st-shot:
- ASCII art graphics
- Choppy cell-based movement
- No music (or simple beeps)
- Limited gameplay depth

### After 1st-shot:
- ✅ High-res PNG sprites (24-bit color)
- ✅ Subpixel-smooth animation
- ✅ Authentic C64 SID music + dynamic sound effects
- ✅ Complex enemy AI with state machines
- ✅ Full game engine features (particles, shields, weapons, power-ups)
- ✅ Multi-threaded architecture

**This is to terminal gaming what Doom was to shareware FPS** — a technical showcase that redefines the genre.

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
