# 1ST-SHOT — My First Shot at a Terminal Game

Hi everyone,

After **Zigtoberfest 2025**, I wanted to make this version public so others can **play with it, study it, and modify it**.
This is **1ST-SHOT**, my very first experiment in building a *visually rich, animated game right inside the terminal*.
It’s powered entirely by my rendering engine **movy**, which I created to bring color, motion, and even SID-style sound to text-mode environments.

I originally built this as part of my talk at Zigtoberfest, and I’m releasing it exactly as it is today — not because it’s finished, but because it already *feels alive*.

## What this release is

Think of 1ST-SHOT as both a **playable demo** and a **learning project**.
It’s here to show how you can structure a smooth game loop in Zig, how to animate sprites with movy, and how to trigger sounds through the SoundManager.

You can fly, shoot, destroy asteroids, and see real explosions — all running in real time inside your terminal.
Beware of the shootin enemies! They are evil and aim directly at you!

At the beginning, please make sure you destroy the blueish something falling down slowly, it will give you the better weapon!
And as I know my zig hacker friends, you will soon discover all the cheat codes, I left in the source (for testing).

## What’s still missing

This isn’t a polished game yet — it’s my *first shot*.
There’s no proper HUD yet; instead, you’ll still see some debug overlays on the screen.
The current music track is a **temporary placeholder** too.
But everything else is there: the logic, the loop, the movement, and hopefully the joy!

## I encourage you to experiment

Please don’t hesitate to dive in!

* Change the spritesheets, add new ships or effects
* Try out new sounds or SID tunes
* Extend the gameplay logic
* Use the little **asset-creation helper tool** in `assets/code/` to make your own art

This release is meant to **invite you in** — to learn from it, remix it, and make it your own.

## What comes next

I’ll keep developing the game — adding the missing HUD, improving level flow, balancing gameplay, and composing an original soundtrack.
But for now, I’m proud to share this snapshot with you.

1ST-SHOT is my love letter to the Commodore 64 spirit — and a demonstration of what’s possible when you bring that energy into Zig.

Enjoy exploring it, playing it, and maybe breaking it.
Have fun — and fire your first shot!

— Mario (“M64”)

