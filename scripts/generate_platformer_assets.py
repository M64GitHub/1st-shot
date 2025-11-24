#!/usr/bin/env python3
"""
Generate pixel art assets for Mario-style platformer game.
Creates spritesheets compatible with movy engine (PNG format).
"""

from PIL import Image
import os

# Asset output directory
ASSET_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets')

# Colors (RGBA)
TRANSPARENT = (0, 0, 0, 0)
BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)

# Player colors (Mario-like)
RED = (228, 52, 52, 255)
DARK_RED = (172, 28, 28, 255)
SKIN = (252, 200, 148, 255)
BROWN = (100, 68, 44, 255)
DARK_BROWN = (68, 44, 28, 255)
BLUE = (52, 100, 228, 255)

# Tile colors
BRICK_MAIN = (200, 100, 52, 255)
BRICK_DARK = (140, 68, 28, 255)
BRICK_LIGHT = (228, 140, 84, 255)
GROUND_MAIN = (148, 100, 68, 255)
GROUND_DARK = (100, 68, 44, 255)
GROUND_TOP = (52, 172, 52, 255)  # Grass top
QUESTION_YELLOW = (252, 200, 68, 255)
QUESTION_DARK = (200, 148, 28, 255)
QUESTION_LIGHT = (255, 228, 148, 255)

# Enemy colors (Goomba-like mushroom)
MUSHROOM_CAP = (172, 68, 52, 255)
MUSHROOM_CAP_LIGHT = (228, 100, 68, 255)
MUSHROOM_BODY = (252, 220, 180, 255)
MUSHROOM_FEET = (68, 44, 28, 255)

# Collectible colors
COIN_GOLD = (252, 200, 68, 255)
COIN_LIGHT = (255, 228, 148, 255)
COIN_DARK = (200, 148, 28, 255)
POWERUP_RED = (228, 52, 52, 255)
POWERUP_WHITE = (255, 255, 255, 255)
POWERUP_SPOTS = (252, 200, 68, 255)

# Sky/background colors
SKY_BLUE = (100, 148, 252, 255)
CLOUD_WHITE = (255, 255, 255, 255)
HILL_GREEN = (52, 172, 52, 255)
HILL_DARK = (28, 128, 28, 255)
BUSH_GREEN = (68, 148, 68, 255)


def create_image(width, height):
    """Create a new RGBA image with transparency."""
    return Image.new('RGBA', (width, height), TRANSPARENT)


def draw_pixel(img, x, y, color):
    """Draw a single pixel."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def draw_rect(img, x, y, w, h, color):
    """Draw a filled rectangle."""
    for py in range(y, y + h):
        for px in range(x, x + w):
            draw_pixel(img, px, py, color)


def draw_outline(img, x, y, w, h, color):
    """Draw rectangle outline."""
    for px in range(x, x + w):
        draw_pixel(img, px, y, color)
        draw_pixel(img, px, y + h - 1, color)
    for py in range(y, y + h):
        draw_pixel(img, x, py, color)
        draw_pixel(img, x + w - 1, py, color)


# ============================================================================
# PLAYER SPRITES (16x24 each, 6 frames: idle, walk1, walk2, walk3, jump, duck)
# ============================================================================

def draw_player_base(img, x_offset, color_hat, color_shirt, jumping=False, ducking=False):
    """Draw base player sprite at offset."""
    x = x_offset

    if ducking:
        # Ducking pose (shorter)
        # Hat
        draw_rect(img, x+4, 8, 8, 3, color_hat)
        draw_rect(img, x+3, 11, 10, 2, color_hat)
        # Face
        draw_rect(img, x+5, 13, 6, 4, SKIN)
        draw_pixel(img, x+6, 14, BLACK)  # Eye
        draw_pixel(img, x+9, 14, BLACK)  # Eye
        # Body (compressed)
        draw_rect(img, x+4, 17, 8, 4, color_shirt)
        # Feet
        draw_rect(img, x+3, 21, 4, 3, BROWN)
        draw_rect(img, x+9, 21, 4, 3, BROWN)
    elif jumping:
        # Jumping pose
        # Hat
        draw_rect(img, x+4, 2, 8, 3, color_hat)
        draw_rect(img, x+3, 5, 10, 2, color_hat)
        # Face
        draw_rect(img, x+5, 7, 6, 4, SKIN)
        draw_pixel(img, x+6, 8, BLACK)  # Eye
        draw_pixel(img, x+9, 8, BLACK)  # Eye
        # Body
        draw_rect(img, x+4, 11, 8, 5, color_shirt)
        draw_rect(img, x+4, 16, 8, 3, BLUE)  # Pants
        # Arms up
        draw_rect(img, x+2, 9, 2, 4, color_shirt)
        draw_rect(img, x+12, 9, 2, 4, color_shirt)
        # Legs spread
        draw_rect(img, x+3, 19, 3, 5, BLUE)
        draw_rect(img, x+10, 19, 3, 5, BLUE)
        draw_rect(img, x+2, 21, 3, 3, BROWN)  # Feet
        draw_rect(img, x+11, 21, 3, 3, BROWN)
    else:
        # Standing pose
        # Hat
        draw_rect(img, x+4, 2, 8, 3, color_hat)
        draw_rect(img, x+3, 5, 10, 2, color_hat)
        # Face
        draw_rect(img, x+5, 7, 6, 4, SKIN)
        draw_pixel(img, x+6, 8, BLACK)  # Eye
        draw_pixel(img, x+9, 8, BLACK)  # Eye
        # Body
        draw_rect(img, x+4, 11, 8, 5, color_shirt)
        draw_rect(img, x+4, 16, 8, 3, BLUE)  # Pants
        # Arms
        draw_rect(img, x+2, 12, 2, 4, color_shirt)
        draw_rect(img, x+12, 12, 2, 4, color_shirt)
        # Legs
        draw_rect(img, x+4, 19, 3, 5, BLUE)
        draw_rect(img, x+9, 19, 3, 5, BLUE)
        draw_rect(img, x+3, 21, 4, 3, BROWN)  # Feet
        draw_rect(img, x+9, 21, 4, 3, BROWN)


def draw_player_walk(img, x_offset, frame, color_hat, color_shirt):
    """Draw walking animation frame."""
    x = x_offset

    # Hat
    draw_rect(img, x+4, 2, 8, 3, color_hat)
    draw_rect(img, x+3, 5, 10, 2, color_hat)
    # Face
    draw_rect(img, x+5, 7, 6, 4, SKIN)
    draw_pixel(img, x+6, 8, BLACK)
    draw_pixel(img, x+9, 8, BLACK)
    # Body
    draw_rect(img, x+4, 11, 8, 5, color_shirt)
    draw_rect(img, x+4, 16, 8, 3, BLUE)

    # Animated legs
    if frame == 0:
        # Left leg forward
        draw_rect(img, x+3, 19, 3, 5, BLUE)
        draw_rect(img, x+10, 19, 3, 4, BLUE)
        draw_rect(img, x+2, 21, 4, 3, BROWN)
        draw_rect(img, x+10, 20, 4, 3, BROWN)
    elif frame == 1:
        # Neutral
        draw_rect(img, x+4, 19, 3, 5, BLUE)
        draw_rect(img, x+9, 19, 3, 5, BLUE)
        draw_rect(img, x+3, 21, 4, 3, BROWN)
        draw_rect(img, x+9, 21, 4, 3, BROWN)
    else:
        # Right leg forward
        draw_rect(img, x+3, 19, 3, 4, BLUE)
        draw_rect(img, x+10, 19, 3, 5, BLUE)
        draw_rect(img, x+2, 20, 4, 3, BROWN)
        draw_rect(img, x+10, 21, 4, 3, BROWN)

    # Arms swing
    if frame == 0:
        draw_rect(img, x+1, 11, 2, 4, color_shirt)
        draw_rect(img, x+13, 13, 2, 4, color_shirt)
    elif frame == 1:
        draw_rect(img, x+2, 12, 2, 4, color_shirt)
        draw_rect(img, x+12, 12, 2, 4, color_shirt)
    else:
        draw_rect(img, x+1, 13, 2, 4, color_shirt)
        draw_rect(img, x+13, 11, 2, 4, color_shirt)


def create_player_spritesheet():
    """Create player spritesheet: 6 frames x 16 pixels wide = 96 pixels."""
    width = 16 * 6  # 6 frames
    height = 24
    img = create_image(width, height)

    # Frame 0: Idle
    draw_player_base(img, 0, RED, RED)

    # Frame 1-3: Walk animation
    draw_player_walk(img, 16, 0, RED, RED)
    draw_player_walk(img, 32, 1, RED, RED)
    draw_player_walk(img, 48, 2, RED, RED)

    # Frame 4: Jump
    draw_player_base(img, 64, RED, RED, jumping=True)

    # Frame 5: Duck
    draw_player_base(img, 80, RED, RED, ducking=True)

    return img


# ============================================================================
# TILE SPRITES (16x16 each)
# ============================================================================

def create_ground_tile():
    """Create grass-topped ground tile."""
    img = create_image(16, 16)

    # Grass top
    draw_rect(img, 0, 0, 16, 4, GROUND_TOP)
    # Some grass detail
    draw_pixel(img, 2, 0, HILL_GREEN)
    draw_pixel(img, 7, 0, HILL_GREEN)
    draw_pixel(img, 12, 0, HILL_GREEN)

    # Dirt body
    draw_rect(img, 0, 4, 16, 12, GROUND_MAIN)

    # Dirt texture
    for y in range(6, 15, 3):
        for x in range(2, 15, 4):
            draw_pixel(img, x, y, GROUND_DARK)
            draw_pixel(img, x+1, y+1, GROUND_DARK)

    return img


def create_brick_tile():
    """Create brick tile."""
    img = create_image(16, 16)

    # Base color
    draw_rect(img, 0, 0, 16, 16, BRICK_MAIN)

    # Brick pattern
    # Row 1
    draw_rect(img, 0, 0, 7, 7, BRICK_MAIN)
    draw_rect(img, 8, 0, 8, 7, BRICK_MAIN)
    draw_pixel(img, 7, 0, BRICK_DARK)
    draw_pixel(img, 7, 1, BRICK_DARK)
    draw_pixel(img, 7, 2, BRICK_DARK)
    draw_pixel(img, 7, 3, BRICK_DARK)
    draw_pixel(img, 7, 4, BRICK_DARK)
    draw_pixel(img, 7, 5, BRICK_DARK)
    draw_pixel(img, 7, 6, BRICK_DARK)

    # Mortar lines
    draw_rect(img, 0, 7, 16, 1, BRICK_DARK)
    draw_rect(img, 0, 15, 16, 1, BRICK_DARK)

    # Row 2 (offset)
    draw_rect(img, 0, 8, 3, 7, BRICK_MAIN)
    draw_rect(img, 4, 8, 8, 7, BRICK_MAIN)
    draw_rect(img, 13, 8, 3, 7, BRICK_MAIN)
    draw_pixel(img, 3, 8, BRICK_DARK)
    draw_pixel(img, 3, 9, BRICK_DARK)
    draw_pixel(img, 3, 10, BRICK_DARK)
    draw_pixel(img, 3, 11, BRICK_DARK)
    draw_pixel(img, 3, 12, BRICK_DARK)
    draw_pixel(img, 3, 13, BRICK_DARK)
    draw_pixel(img, 3, 14, BRICK_DARK)
    draw_pixel(img, 12, 8, BRICK_DARK)
    draw_pixel(img, 12, 9, BRICK_DARK)
    draw_pixel(img, 12, 10, BRICK_DARK)
    draw_pixel(img, 12, 11, BRICK_DARK)
    draw_pixel(img, 12, 12, BRICK_DARK)
    draw_pixel(img, 12, 13, BRICK_DARK)
    draw_pixel(img, 12, 14, BRICK_DARK)

    # Highlights
    draw_pixel(img, 1, 1, BRICK_LIGHT)
    draw_pixel(img, 9, 1, BRICK_LIGHT)
    draw_pixel(img, 5, 9, BRICK_LIGHT)

    return img


def create_question_tile():
    """Create question block tile (animated, 4 frames)."""
    width = 16 * 4
    img = create_image(width, 16)

    for frame in range(4):
        x = frame * 16

        # Base
        draw_rect(img, x, 0, 16, 16, QUESTION_YELLOW)
        draw_outline(img, x, 0, 16, 16, QUESTION_DARK)

        # Inner border highlight
        draw_rect(img, x+1, 1, 14, 1, QUESTION_LIGHT)
        draw_rect(img, x+1, 1, 1, 14, QUESTION_LIGHT)

        # Question mark (animate slightly)
        qx = x + 5
        qy = 3 + (frame % 2)  # Bobbing

        # ? shape
        draw_rect(img, qx+1, qy, 4, 2, QUESTION_DARK)
        draw_rect(img, qx+4, qy+2, 2, 2, QUESTION_DARK)
        draw_rect(img, qx+2, qy+4, 2, 2, QUESTION_DARK)
        draw_rect(img, qx+2, qy+7, 2, 2, QUESTION_DARK)  # Dot

    return img


def create_empty_block_tile():
    """Create empty (hit) question block."""
    img = create_image(16, 16)

    draw_rect(img, 0, 0, 16, 16, GROUND_MAIN)
    draw_outline(img, 0, 0, 16, 16, GROUND_DARK)
    draw_rect(img, 2, 2, 12, 12, GROUND_DARK)
    draw_outline(img, 2, 2, 12, 12, GROUND_MAIN)

    return img


def create_pipe_top():
    """Create pipe top tile."""
    img = create_image(32, 16)

    # Pipe opening
    draw_rect(img, 0, 0, 32, 16, (52, 172, 52, 255))
    draw_rect(img, 2, 0, 28, 14, (68, 200, 68, 255))
    draw_rect(img, 4, 0, 24, 12, (28, 128, 28, 255))  # Dark interior

    # Highlight
    draw_rect(img, 2, 2, 2, 12, (100, 228, 100, 255))

    return img


def create_pipe_body():
    """Create pipe body tile."""
    img = create_image(32, 16)

    draw_rect(img, 2, 0, 28, 16, (52, 172, 52, 255))
    draw_rect(img, 4, 0, 24, 16, (68, 200, 68, 255))

    # Highlight
    draw_rect(img, 4, 0, 2, 16, (100, 228, 100, 255))

    # Shadow
    draw_rect(img, 26, 0, 2, 16, (28, 128, 28, 255))

    return img


# ============================================================================
# ENEMY SPRITES
# ============================================================================

def create_goomba_spritesheet():
    """Create goomba (mushroom enemy) spritesheet: 2 walk frames + squished."""
    width = 16 * 3
    height = 16
    img = create_image(width, height)

    for frame in range(2):
        x = frame * 16

        # Mushroom cap
        draw_rect(img, x+2, 0, 12, 8, MUSHROOM_CAP)
        draw_rect(img, x+4, 0, 8, 2, MUSHROOM_CAP_LIGHT)

        # Face
        draw_rect(img, x+3, 8, 10, 4, MUSHROOM_BODY)
        # Eyes (angry)
        draw_rect(img, x+4, 9, 2, 2, BLACK)
        draw_rect(img, x+10, 9, 2, 2, BLACK)
        draw_pixel(img, x+4, 9, WHITE)
        draw_pixel(img, x+10, 9, WHITE)

        # Feet (animated)
        if frame == 0:
            draw_rect(img, x+2, 12, 4, 4, MUSHROOM_FEET)
            draw_rect(img, x+10, 12, 4, 4, MUSHROOM_FEET)
        else:
            draw_rect(img, x+3, 12, 4, 4, MUSHROOM_FEET)
            draw_rect(img, x+9, 12, 4, 4, MUSHROOM_FEET)

    # Frame 2: Squished
    x = 32
    draw_rect(img, x+2, 12, 12, 4, MUSHROOM_CAP)
    draw_rect(img, x+4, 14, 8, 2, MUSHROOM_CAP_LIGHT)

    return img


def create_koopa_spritesheet():
    """Create koopa (turtle enemy) spritesheet: 2 walk frames + shell."""
    width = 16 * 3
    height = 24
    img = create_image(width, height)

    GREEN = (52, 172, 52, 255)
    GREEN_LIGHT = (100, 200, 100, 255)
    GREEN_DARK = (28, 128, 28, 255)
    SHELL_YELLOW = (252, 228, 100, 255)

    for frame in range(2):
        x = frame * 16

        # Head
        draw_rect(img, x+4, 2, 8, 6, GREEN)
        draw_rect(img, x+5, 2, 6, 4, GREEN_LIGHT)
        # Eyes
        draw_pixel(img, x+5, 4, BLACK)
        draw_pixel(img, x+10, 4, BLACK)

        # Shell
        draw_rect(img, x+2, 8, 12, 10, GREEN)
        draw_rect(img, x+4, 10, 8, 6, SHELL_YELLOW)

        # Feet
        if frame == 0:
            draw_rect(img, x+1, 18, 4, 6, GREEN_DARK)
            draw_rect(img, x+11, 18, 4, 6, GREEN_DARK)
        else:
            draw_rect(img, x+2, 18, 4, 6, GREEN_DARK)
            draw_rect(img, x+10, 18, 4, 6, GREEN_DARK)

    # Frame 2: Shell only
    x = 32
    draw_rect(img, x+2, 14, 12, 10, GREEN)
    draw_rect(img, x+4, 16, 8, 6, SHELL_YELLOW)
    draw_outline(img, x+2, 14, 12, 10, GREEN_DARK)

    return img


# ============================================================================
# COLLECTIBLES
# ============================================================================

def create_coin_spritesheet():
    """Create spinning coin spritesheet: 4 frames."""
    width = 12 * 4
    height = 16
    img = create_image(width, height)

    widths = [8, 6, 2, 6]  # Spinning effect

    for frame in range(4):
        x = frame * 12
        w = widths[frame]
        offset = (8 - w) // 2

        # Coin body
        draw_rect(img, x + 2 + offset, 2, w, 12, COIN_GOLD)

        if w > 2:
            # Highlight
            draw_rect(img, x + 3 + offset, 3, max(1, w-2), 2, COIN_LIGHT)
            # Shadow
            draw_rect(img, x + 2 + offset + w - 2, 10, 2, 3, COIN_DARK)

    return img


def create_mushroom_powerup():
    """Create mushroom power-up sprite."""
    img = create_image(16, 16)

    # Cap
    draw_rect(img, 2, 0, 12, 8, POWERUP_RED)
    draw_rect(img, 0, 4, 16, 4, POWERUP_RED)

    # White spots
    draw_rect(img, 4, 2, 3, 3, POWERUP_WHITE)
    draw_rect(img, 9, 2, 3, 3, POWERUP_WHITE)
    draw_rect(img, 6, 5, 4, 2, POWERUP_WHITE)

    # Stem
    draw_rect(img, 4, 8, 8, 8, POWERUP_WHITE)
    draw_rect(img, 5, 10, 2, 4, (240, 240, 240, 255))  # Shading

    # Eyes
    draw_pixel(img, 5, 11, BLACK)
    draw_pixel(img, 10, 11, BLACK)

    return img


def create_star_spritesheet():
    """Create star power-up spritesheet: 4 frames (flashing)."""
    width = 16 * 4
    height = 16
    img = create_image(width, height)

    colors = [
        (255, 255, 100, 255),  # Yellow
        (255, 200, 50, 255),   # Gold
        (255, 255, 200, 255),  # Light
        (255, 200, 50, 255),   # Gold
    ]

    for frame in range(4):
        x = frame * 16
        color = colors[frame]

        # Star shape
        # Center
        draw_rect(img, x+5, 4, 6, 8, color)
        # Top point
        draw_rect(img, x+6, 0, 4, 4, color)
        draw_rect(img, x+7, 0, 2, 2, (255, 255, 255, 255))
        # Left point
        draw_rect(img, x+0, 5, 5, 4, color)
        # Right point
        draw_rect(img, x+11, 5, 5, 4, color)
        # Bottom left
        draw_rect(img, x+3, 12, 4, 4, color)
        # Bottom right
        draw_rect(img, x+9, 12, 4, 4, color)

        # Eyes
        draw_pixel(img, x+6, 7, BLACK)
        draw_pixel(img, x+9, 7, BLACK)

    return img


# ============================================================================
# BACKGROUND ELEMENTS
# ============================================================================

def create_cloud():
    """Create cloud sprite."""
    img = create_image(48, 24)

    # Cloud puffs
    draw_rect(img, 8, 8, 32, 12, CLOUD_WHITE)
    draw_rect(img, 4, 10, 8, 8, CLOUD_WHITE)
    draw_rect(img, 36, 10, 8, 8, CLOUD_WHITE)
    draw_rect(img, 12, 4, 12, 8, CLOUD_WHITE)
    draw_rect(img, 24, 4, 12, 8, CLOUD_WHITE)
    draw_rect(img, 16, 0, 16, 8, CLOUD_WHITE)

    # Subtle shading
    draw_rect(img, 10, 16, 28, 2, (240, 240, 255, 255))

    return img


def create_bush():
    """Create bush sprite."""
    img = create_image(48, 16)

    BUSH_MAIN = (68, 172, 68, 255)
    BUSH_LIGHT = (100, 200, 100, 255)
    BUSH_DARK = (28, 128, 28, 255)

    # Bush body
    draw_rect(img, 4, 8, 40, 8, BUSH_MAIN)
    draw_rect(img, 8, 4, 16, 8, BUSH_MAIN)
    draw_rect(img, 24, 4, 16, 8, BUSH_MAIN)
    draw_rect(img, 12, 0, 8, 8, BUSH_MAIN)
    draw_rect(img, 28, 0, 8, 8, BUSH_MAIN)

    # Highlights
    draw_rect(img, 14, 2, 4, 4, BUSH_LIGHT)
    draw_rect(img, 30, 2, 4, 4, BUSH_LIGHT)

    return img


def create_hill():
    """Create background hill sprite."""
    img = create_image(64, 32)

    # Hill body (triangular-ish)
    for y in range(32):
        width = (32 - y) * 2
        x_start = 32 - (32 - y)
        draw_rect(img, x_start, y, width, 1, HILL_GREEN)

    # Darker spots
    draw_rect(img, 24, 16, 8, 8, HILL_DARK)
    draw_rect(img, 32, 20, 6, 6, HILL_DARK)

    return img


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Generate all assets."""
    os.makedirs(ASSET_DIR, exist_ok=True)

    print("Generating platformer assets...")

    # Player
    player = create_player_spritesheet()
    player.save(os.path.join(ASSET_DIR, 'player.png'))
    print("  Created player.png (96x24, 6 frames)")

    # Tiles
    ground = create_ground_tile()
    ground.save(os.path.join(ASSET_DIR, 'tile_ground.png'))
    print("  Created tile_ground.png (16x16)")

    brick = create_brick_tile()
    brick.save(os.path.join(ASSET_DIR, 'tile_brick.png'))
    print("  Created tile_brick.png (16x16)")

    question = create_question_tile()
    question.save(os.path.join(ASSET_DIR, 'tile_question.png'))
    print("  Created tile_question.png (64x16, 4 frames)")

    empty = create_empty_block_tile()
    empty.save(os.path.join(ASSET_DIR, 'tile_empty.png'))
    print("  Created tile_empty.png (16x16)")

    pipe_top = create_pipe_top()
    pipe_top.save(os.path.join(ASSET_DIR, 'tile_pipe_top.png'))
    print("  Created tile_pipe_top.png (32x16)")

    pipe_body = create_pipe_body()
    pipe_body.save(os.path.join(ASSET_DIR, 'tile_pipe_body.png'))
    print("  Created tile_pipe_body.png (32x16)")

    # Enemies
    goomba = create_goomba_spritesheet()
    goomba.save(os.path.join(ASSET_DIR, 'enemy_goomba.png'))
    print("  Created enemy_goomba.png (48x16, 3 frames)")

    koopa = create_koopa_spritesheet()
    koopa.save(os.path.join(ASSET_DIR, 'enemy_koopa.png'))
    print("  Created enemy_koopa.png (48x24, 3 frames)")

    # Collectibles
    coin = create_coin_spritesheet()
    coin.save(os.path.join(ASSET_DIR, 'collectible_coin.png'))
    print("  Created collectible_coin.png (48x16, 4 frames)")

    mushroom = create_mushroom_powerup()
    mushroom.save(os.path.join(ASSET_DIR, 'powerup_mushroom.png'))
    print("  Created powerup_mushroom.png (16x16)")

    star = create_star_spritesheet()
    star.save(os.path.join(ASSET_DIR, 'powerup_star.png'))
    print("  Created powerup_star.png (64x16, 4 frames)")

    # Background
    cloud = create_cloud()
    cloud.save(os.path.join(ASSET_DIR, 'bg_cloud.png'))
    print("  Created bg_cloud.png (48x24)")

    bush = create_bush()
    bush.save(os.path.join(ASSET_DIR, 'bg_bush.png'))
    print("  Created bg_bush.png (48x16)")

    hill = create_hill()
    hill.save(os.path.join(ASSET_DIR, 'bg_hill.png'))
    print("  Created bg_hill.png (64x32)")

    print("\nAll assets generated successfully!")
    print(f"Output directory: {ASSET_DIR}")


if __name__ == '__main__':
    main()
