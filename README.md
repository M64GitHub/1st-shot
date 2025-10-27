![License](https://img.shields.io/badge/License-MIT-85adf2?style=flat)
![Zig](https://img.shields.io/badge/Zig-0.14.1-orange?style=flat)
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
> (See the [Release Notes](./RELEASE_NOTES.md) for more background.)


## **Next-Level Terminal Bullet Hell**

A fast-paced, retro-inspired shooter rendered completely in text-mode graphics.

<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 25 08" src="https://github.com/user-attachments/assets/309202bf-c3da-4b80-9536-7d12ffa8b249" />

<p/>

> *"The limitations aren't in the medium — they're in our imagination."*

### What makes 1ST-SHOT special:

- PNG sprites with 24-bit color, slicing of animations from spritesheets
- Subpixel movement system for smooth movements
- Authentic C64 SID chip music (dedicated audio thread for SID data generation and wav mixing)
- Three enemy types with different behavior patterns
- Fully animated effects, shields, weapons, and power-ups

## Quick Start

### Requirements
- **Zig 0.14.1**
- **SDL2** (for audio)
- Terminal with 24-bit color support (most modern terminals)

(zig 0.14.0 should also work, but I stopped testing on different version, am currently on 14.1 for all my repos)

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

## Dependencies

### Zig Libraries

- **movy** - Terminal rendering engine

- **zigreSID** - MOS 6581/8580 SID chip emulator
  - MixingDumpPlayer for WAV mixing
  - SDL2 audio output

### System Dependencies

- **SDL2** - Audio output and WAV loading
- **Zig 0.14.0+** - Build system and language

## License

MIT. Hack it, spread it!

## Join the Terminal Revolution

**1ST-SHOT** wants to prove that terminal gaming can be a serious platform for creativity and design.  

The medium never limits us — only imagination does.

*What’s your shot?*

---

**Made with ❤️ and Zig**
