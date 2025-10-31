![License](https://img.shields.io/badge/License-MIT-85adf2?style=flat)
![Zig](https://img.shields.io/badge/Zig-0.15.2-orange?style=flat)
```
 ____  ____________________        _________ ___ ___ ___________________
/_   |/   _____/\__    ___/       /   _____//   X   \\_      \__    ___/
 |   |\_____  \   |    |  ______  \_____  \/   _|_   \/  _|_  \|    |   
 |   |/        \  |    | /_____/  /        \    |    /    |    \    |   
 |___/_______  /  |____|         /_______  /\___X_  /\_______  /____|   
             \/                          \/       \/         \/         
```
Next-Level Terminal Bullet Hell — powered by [movy](https://github.com/M64GitHub/movy)  

> **1ST-SHOT** is my first attempt at building a visually rich, animated game inside the terminal — powered entirely by my rendering engine "movy".  
> After [**Zigtoberfest 2025**](https://www.youtube.com/@zigtoberfest), I wanted to make this version public so others can **play with it, study it, and modify it**.  
> It’s not a finished game — it's a *playable demo and learning project* 
> (See the [Release Notes](./RELEASE_NOTES.md) for more background.)

<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 25 08" src="https://github.com/user-attachments/assets/309202bf-c3da-4b80-9536-7d12ffa8b249" />

<p/>

### Highlights

- Renders PNG sprites in 24-bit color, slicing animations from spritesheets
- Implements subpixel movement for smooth motion
- Steady 71 FPS! (new)
- Generates authentic C64 SID music on a dedicated audio thread, mixing PCM in real time

## What's New

- **Upgraded to Zig 0.15.2**
- **Constant FPS rendering:** gameplay now runs at a stable frame rate across all terminals — 71 silky-smooth and consistent FPS no matter your window size! (When font is too small, it will slow down though, no frame is skipped ;) )

## Quick Start

### Requirements
- **Zig 0.15.2**
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

**Destroy enemies and asteroids** to earn points. **Collect power-ups** to upgrade your ship. **Avoid collision** to survive.

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
- Simple "intelligence" with state machine
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

The blue round objects. Shoot these to collect rewards (but don't touch them!):
- **ShieldDrop** (25%)
- **LifeDrop** (20%)
- **AmmoDrop** (40%)
- **Jackpot** (5%): Shield + Life + 100 Ammo!

They all look the same, the actual reward will be a surprise.  
(numbers in brackets are the chance for the reward type)

### Score Milestones

Reach these scores to auto-unlock bonuses:
- **3,000**: Ammo bonus
- **5,000**: Shield bonus
- **10,000**: Extra life

## Dependencies

### Zig Libraries

- **movy** - Terminal rendering engine

- **zigreSID** - MOS 6581/8580 SID chip emulator
  - MixingDumpPlayer for WAV mixing
  - SDL2 audio output

### System Dependencies

- **SDL2** - Audio output and WAV loading
- **Zig 0.15.2** - Build system and language

## License

MIT. Hack it, spread it!

## Join the Terminal Revolution!

The revolution isn’t about this game — it’s about what comes next.
If 1ST-SHOT sparks your curiosity, grab Zig, explore the code, and start shaping your own terminal world.
Whether it’s a small demo, a new effect, or a full game — build something that glows in the terminal.  

> *"The limitations aren't in the medium — they're in our imagination."*

---

Built with <3 and **Zig** and **movy**.

