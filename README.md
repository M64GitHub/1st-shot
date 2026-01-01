![License](https://img.shields.io/badge/License-MIT-85adf2?style=flat)
![Version](https://img.shields.io/badge/Version-0.0.4-85adf2?style=flat)
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

### Build and Run

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

- **[movy](https://github.com/M64GitHub/movy)** - Terminal rendering engine
- **[zigreSID](https://github.com/M64GitHub/zigreSID)** - MOS 6581/8580 SID chip emulator & WAV mixer, SDL playback

## License

MIT. Hack it, spread it!

---

Built with `<3` and **Zig** and **movy**.

