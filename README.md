![License](https://img.shields.io/badge/License-MIT-85adf2?style=flat)
![Version](https://img.shields.io/badge/Version-0.0.3-85adf2?style=flat)
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

I started to track versions, and include a versionized [RELEASE_NOTES_v0.0.3.md](./RELEASE_NOTES_v0.0.3.md) file for the current release.

<img width="1920" height="1080" alt="Screenshot 2025-10-24 at 01 25 08" src="https://github.com/user-attachments/assets/309202bf-c3da-4b80-9536-7d12ffa8b249" />

<p/>

### Highlights

- PNG sprites in 24-bit color, slicing animations from spritesheets
- Subpixel movement for smooth motion
- Steady 71 FPS! (new)
- Authentic C64 SID music on a dedicated audio thread, mixing PCM in real time

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

Built with `<3` and **Zig** and **movy**.

