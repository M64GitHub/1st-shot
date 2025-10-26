```
 ____  ____________________        _________ ___ ___ ___________________
/_   |/   _____/\__    ___/       /   _____//   X   \\_      \__    ___/
 |   |\_____  \   |    |  ______  \_____  \/   _|_   \/  _|_  \|    |   
 |   |/        \  |    | /_____/  /        \    |    /    |    \    |   
 |___/_______  /  |____|         /_______  /\___X_  /\_______  /____|   
             \/                          \/       \/         \/         
```
> **1ST-SHOT** is my first attempt at building a visually rich, animated game inside the terminal — powered entirely by my rendering engine [movy](https://github.com/M64GitHub/movy).  
> After **Zigtoberfest 2025**, I wanted to make this version public so others can **play with it, study it, and modify it**.  
> It’s not a finished game — but a *playable demo and learning project*: a smooth main loop, sub-pixel motion, sprite animations, explosions, and SID-style sound — all written in pure Zig.  
> I built it to show that the terminal can still surprise us — and shine in pixels
> (See the `RELEASE-NOTES.md` for more background.)


## **Next-Level Terminal Bullet Hell**

A fast-paced, retro-inspired shooter rendered completely in text-mode graphics.

<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 25 08" src="https://github.com/user-attachments/assets/309202bf-c3da-4b80-9536-7d12ffa8b249" />

<p/>

> *"The limitations aren't in the medium — they're in our imagination."*

### What makes 1ST-SHOT special:

- High-res PNG sprites with 24-bit color
- Subpixel movement system for smooth movements
- Authentic C64 SID chip music with dynamic sound effects
- Three enemy types with different behavior patterns
- Fully animated effects, shields, weapons, and power-ups
- Multi-threaded architecture for audio independence

#### **Authentic SID Chip Music**
One of the first terminal games to integrate authentic Commodore 64 SID chip emulation, running in its own audio thread.

#### **Real-Time Audio Mixing**
Dynamic WAV sound effects seamlessly mixed into the SID music stream. Explosions, weapons, power-ups — all with zero audio interruption or glitches.

#### **Three Enemy Types with Distinct Behaviors**
Distinct enemy behaviors implemented through formation logic, state machines, and simple targeting:
- **SingleEnemy**: Straight or zigzag patterns with global wave sync
- **SwarmEnemy**: Snake-like formations that grow over time (up to 17 sprites!)
- **ShooterEnemy**: State machine behavior with projectile tracking and orphaned bullet mechanics - beware, it aims at You!

#### **True Sprite Graphics**
Uses real PNG sprite sheets for frame-based animation. Rendering is buffered to eliminate flicker, and object pooling minimizes runtime allocations.

### **Complete Game Engine**
- **3 explosion types**
- **200-star parallax starfield** with depth-based speed
- **Multiple weapon systems** (spread shot, default)
- **Shield mechanics** with visual overlays
- **Score-based progression** with auto-unlocking rewards
- **12-state game state machine** (pause, death, respawn, game over)



## Quick Start

### Requirements
- **Zig 0.14.0+**
- **SDL2** (for audio)
- Terminal with 24-bit color support (most modern terminals)

### Install

```bash
# Clone repository
git clone https://github.com/M64GitHub/1st-shot.git
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

Check the source for the cheat codes ;) !

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

## Some Development Notes

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


## License

MIT. Hack it, spread it!



## Join the Terminal Revolution

**1ST-SHOT** proves that terminal gaming can be a serious platform for creativity and design.  
The medium never limits us — only imagination does.

*What’s your shot?*

---

**Made with ❤️ and Zig**
