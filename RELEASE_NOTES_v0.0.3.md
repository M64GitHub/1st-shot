# Release Notes - v0.0.3

## Gameplay Changes & Fixes

**Overall Impact**: This release adjusts game difficulty through more aggressive enemy spawning and higher asteroid density, while fixing an animation bugs (asteroids did not play animation).  
Shield now holds a bit longer.  
Shooter enemies and Single Enemies can now spawn up to 3 at the same time! More fun!

### Difficulty & Balance Adjustments

**Increased Enemy Pressure**
- Single enemies spawn more frequently (600 → 400 frames between spawns)
- Shooter enemies spawn more frequently (1500 → 1000 frames between spawns)
- Maximum concurrent single enemies increased (2 → 3)
- Maximum concurrent shooter enemies increased (2 → 3)

**Asteroid Field Intensity**
- Target asteroid count increased (8 → 9 active asteroids)
- Asteroid spawn rate increased (60 → 50 frames between spawns)
- More varied asteroid animation speeds for visual diversity:
  - Small asteroids: slower animation (speed 3, previously 1)
  - Big asteroids: much slower animation (speed 6, previously 2)
  - Big2 asteroids: slower animation (speed 5, previously 2)
  - Huge asteroids: slower animation (speed 4, previously 1)

**Shield Balance**
- Default shield cooldown slightly increased (500 → 600 frames)

## Bug Fixes

### Animation Bug in movy Library
- **Fixed `.loopBounce` animation mode causing animations to freeze**
  - Corrected integer wraparound bug in `IndexAnimator` when reversing direction
  - All bounce-style animations (asteroids) now animate smoothly
- **Fixed animation state not fully resetting when sprites are pooled**
  - Sprites reused from pools now properly reset animation timing

### ObstacleManager Fixes
- **Fixed sprite pool release bug**: AsteroidBig2 now properly releases to correct pool (was incorrectly releasing to AsteroidBig pool)

