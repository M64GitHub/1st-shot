# 1ST-SHOT

```
 ____  ____________________        _________ ___ ___ ___________________
/_   |/   _____/\__    ___/       /   _____//   X   \\_      \__    ___/
 |   |\_____  \   |    |  ______  \_____  \/   _|_   \/  _|_  \|    |   
 |   |/        \  |    | /_____/  /        \    |    /    |    \    |   
 |___/_______  /  |____|         /_______  /\___X_  /\_______  /____|   
             \/                          \/       \/         \/         
```

## **Next-Level Terminal Bullet Hell**

Authentic SID sound. Smooth subpixel motion. Explosions, power-ups, and bonus points — all rendered right inside your terminal.

<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 25 08" src="https://github.com/user-attachments/assets/309202bf-c3da-4b80-9536-7d12ffa8b249" />

> *"The limitations aren't in the medium — they're in our imagination."*

1st-shot isn’t a typical ASCII roguelike. It explores how far a terminal can go — combining modern rendering and sound techniques with retro precision.

### **Authentic SID Chip Music**
One of the first terminal games to integrate authentic Commodore 64 SID chip emulation, running in its own audio thread.

### **Real-Time Audio Mixing**
Dynamic WAV sound effects seamlessly mixed into the SID music stream. Explosions, weapons, power-ups — all with zero audio interruption or glitches.

### **Subpixel-Smooth Motion**
A custom subpixel accumulator system enables fractional pixel speeds, producing motion that feels fluid and continuous — even in a text terminal.

### **Three Enemy Types with Distinct Behaviors**
Distinct enemy behaviors implemented through formation logic, state machines, and simple targeting:
- **SingleEnemy**: Straight or zigzag patterns with global wave sync
- **SwarmEnemy**: Snake-like formations that grow over time (up to 17 sprites!)
- **ShooterEnemy**: State machine behavior with projectile tracking and orphaned bullet mechanics - beware, it aims at You!

### **True Sprite Graphics**
Uses real PNG sprite sheets for frame-based animation. Rendering is buffered to eliminate flicker, and object pooling minimizes runtime allocations.

### **Multi-Threaded Architecture**
Audio runs in its own thread, updating every 35ms independently of the game loop. No audio stutter, no frame drops.

### **Complete Game Engine**
- **3 explosion types**
- **200-star parallax starfield** with depth-based speed
- **Multiple weapon systems** (spread shot, default)
- **Shield mechanics** with visual overlays
- **Score-based progression** with auto-unlocking rewards
- **12-state game state machine** (pause, death, respawn, game over)

---

## Screen-SHOTS
<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 26 36" src="https://github.com/user-attachments/assets/17550389-9988-4033-9a63-f78259d974d0" />


<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 27 02" src="https://github.com/user-attachments/assets/f677b3bf-bd40-45a6-8758-0e97dec800fe" />


---

## Quick Start

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
| **Arrow Keys** | Move ship left / right |
| **Space** | Fire weapon |
| **P** / **Up**| Pause / Unpause |
| **ESC** | Quit |

---

## How to Play

### Survive the onslaught!

**Destroy enemies and asteroids** to earn points. **Collect power-ups** to upgrade your ship. **Avoid collision** or use shields to survive.

### Enemy Types

#### **SingleEnemy** (250 pts)
- Simple but deadly
- Two movement patterns: Straight or Zigzag
- Unlocked from start
- Health: 5 hits

#### **SwarmEnemy** (500 pts)
- Snake-like formations
- Grows longer the longer you survive (up to 17 segments!)
- Graduated amplitude creates mesmerizing wave patterns
- Unlocks at **1000 frames (~16 seconds)**
- Health: 15 hits (hit the head!)

#### **ShooterEnemy** (350 pts)
- Advanced AI with state machine
- Fires two tracking projectiles at your position
- **Danger**: When destroyed, attached bullets become orphans and fall!
- Unlocks at **2000 frames (~33 seconds)**
- Health: 3 hits (shoot the bullets for instant kill!)

### Power-Ups

- **Ammo**: Refills spread weapon
- **Shield**: Temporary invincibility
- **Extra Life**: Gain 1 life
- **Score Bonus**: Instant points

### Dropstacles

Shoot these to collect rewards (but don't touch them!):
- **ShieldDrop** (25%)
- **LifeDrop** (20%)
- **AmmoDrop** (40%)
- **Jackpot** (5%): Shield + Life + 100 Ammo!

They all look the same, the actual reward will be a surprise.

### Score Milestones

Reach these scores to auto-unlock bonuses:
- **3,000**: Ammo bonus
- **5,000**: Shield bonus
- **10,000**: Extra life

---

## Technical Deep Dive

### How It Works

**1st-shot** combines several techniques to create a smooth terminal gaming experience:

#### **Subpixel Movement Algorithm**

Traditional terminal games move objects 1 cell at a time. We use a **fractional accumulator**:

This allows speeds like **0.33 pixels/frame**, creating smooth motion impossible with frame-based movement.

#### **SID Chip Emulation Integration**

Using the **zigreSID** library, we emulate the legendary MOS Technology 6581/8580 SID chip:

The `MixingDumpPlayer` wraps SID emulation + WAV mixing:
- Reads SID register dumps (`.dmp` format)
- Emulates authentic C64 sound synthesis
- Mixes WAV samples in real-time when effects trigger

#### **Sprite Pooling**

Pre-allocate sprite pools at startup, never allocate during gameplay:

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
└─── build.zig                # Build configuration
```

---

## Development

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

## Dependencies

### Zig Libraries

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

### System Dependencies

- **SDL2** - Audio output and WAV loading
- **Zig 0.14.0+** - Build system and language

---

## Why Zig?

Built with Zig, this project demonstrates some of the language’s strongest capabilities:

- **C Interop**: Seamless SDL2 and C library integration
- **Manual Memory Control**: Zero GC, predictable performance
- **Comptime**: Type-safe sprite pools, efficient generics
- **Error Handling**: Explicit error propagation, no hidden exceptions
- **Performance**: ReleaseFast builds rival C++ performance
- **Safety**: Optional overflow checks, bounds checking in debug mode

---

## Features

### What 1st-shot brings to terminal gaming:

- High-res PNG sprites with 24-bit color
- Subpixel movement system for smooth movements
- Authentic C64 SID chip music with dynamic sound effects
- Three enemy types with different behavior patterns
- Fully animated effects, shields, weapons, and power-ups
- Multi-threaded architecture for audio independence

---

## License

MIT. Hack it, spread it!

---

## Join the Terminal Revolution

**1st-shot** wants to proove that terminal gaming can be a serious platform for sophisticated game development. The medium never limits us — only imagination does.

*What's your shot?*

---

**Made with ❤️ and Zig**
