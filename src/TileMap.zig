const std = @import("std");
const movy = @import("movy");
const Sprite = movy.graphic.Sprite;

/// Tile types in the game
pub const TileType = enum(u8) {
    Empty = 0,
    Ground = 1,
    Brick = 2,
    Question = 3,
    EmptyBlock = 4,
    PipeTopLeft = 5,
    PipeTopRight = 6,
    PipeBodyLeft = 7,
    PipeBodyRight = 8,

    pub fn isSolid(self: TileType) bool {
        return switch (self) {
            .Empty => false,
            else => true,
        };
    }

    pub fn isBreakable(self: TileType) bool {
        return self == .Brick;
    }

    pub fn isQuestion(self: TileType) bool {
        return self == .Question;
    }
};

/// Single tile instance
pub const Tile = struct {
    tile_type: TileType = .Empty,
    // For animated tiles like question blocks
    animation_frame: usize = 0,
    // For question blocks that have been hit
    hit: bool = false,
};

/// Tile sprites holder
pub const TileSprites = struct {
    ground: *Sprite,
    brick: *Sprite,
    question: *Sprite,
    empty_block: *Sprite,
    pipe_top: *Sprite,
    pipe_body: *Sprite,

    pub fn init(allocator: std.mem.Allocator) !TileSprites {
        // Load all tile sprites
        var ground = try Sprite.initFromPng(
            allocator,
            "assets/tile_ground.png",
            "ground",
        );

        var brick = try Sprite.initFromPng(
            allocator,
            "assets/tile_brick.png",
            "brick",
        );

        var question = try Sprite.initFromPng(
            allocator,
            "assets/tile_question.png",
            "question",
        );
        try question.splitByWidth(allocator, 16);
        try question.addAnimation(
            allocator,
            "idle",
            Sprite.FrameAnimation.init(0, 3, .loopForward, 8),
        );

        var empty_block = try Sprite.initFromPng(
            allocator,
            "assets/tile_empty.png",
            "empty",
        );

        var pipe_top = try Sprite.initFromPng(
            allocator,
            "assets/tile_pipe_top.png",
            "pipe_top",
        );

        var pipe_body = try Sprite.initFromPng(
            allocator,
            "assets/tile_pipe_body.png",
            "pipe_body",
        );

        return TileSprites{
            .ground = ground,
            .brick = brick,
            .question = question,
            .empty_block = empty_block,
            .pipe_top = pipe_top,
            .pipe_body = pipe_body,
        };
    }

    pub fn deinit(self: *TileSprites, allocator: std.mem.Allocator) void {
        self.ground.deinit(allocator);
        self.brick.deinit(allocator);
        self.question.deinit(allocator);
        self.empty_block.deinit(allocator);
        self.pipe_top.deinit(allocator);
        self.pipe_body.deinit(allocator);
    }
};

/// Tile map for level geometry
pub const TileMap = struct {
    tiles: [][]Tile,
    width: usize,
    height: usize,
    tile_size: i32,
    sprites: TileSprites,
    screen: *movy.Screen,
    allocator: std.mem.Allocator,

    // Rendered tile surface (cached)
    tile_surfaces: std.ArrayList(*movy.graphic.Surface),

    pub const TILE_SIZE: i32 = 16;

    pub fn init(
        allocator: std.mem.Allocator,
        width: usize,
        height: usize,
        screen: *movy.Screen,
    ) !*TileMap {
        const self = try allocator.create(TileMap);

        // Allocate 2D tile array
        const tiles = try allocator.alloc([]Tile, height);
        for (tiles) |*row| {
            row.* = try allocator.alloc(Tile, width);
            for (row.*) |*tile| {
                tile.* = Tile{};
            }
        }

        self.* = TileMap{
            .tiles = tiles,
            .width = width,
            .height = height,
            .tile_size = TILE_SIZE,
            .sprites = try TileSprites.init(allocator),
            .screen = screen,
            .allocator = allocator,
            .tile_surfaces = std.ArrayList(*movy.graphic.Surface).init(allocator),
        };

        return self;
    }

    pub fn deinit(self: *TileMap) void {
        self.sprites.deinit(self.allocator);
        for (self.tiles) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.tiles);
        self.tile_surfaces.deinit();
        self.allocator.destroy(self);
    }

    /// Set a tile at grid position
    pub fn setTile(self: *TileMap, grid_x: usize, grid_y: usize, tile_type: TileType) void {
        if (grid_x < self.width and grid_y < self.height) {
            self.tiles[grid_y][grid_x] = Tile{
                .tile_type = tile_type,
            };
        }
    }

    /// Get tile at grid position
    pub fn getTile(self: *TileMap, grid_x: usize, grid_y: usize) ?*Tile {
        if (grid_x < self.width and grid_y < self.height) {
            return &self.tiles[grid_y][grid_x];
        }
        return null;
    }

    /// Get tile at world pixel position
    pub fn getTileAtPixel(self: *TileMap, world_x: i32, world_y: i32) ?*Tile {
        if (world_x < 0 or world_y < 0) return null;

        const grid_x = @as(usize, @intCast(@divTrunc(world_x, self.tile_size)));
        const grid_y = @as(usize, @intCast(@divTrunc(world_y, self.tile_size)));

        return self.getTile(grid_x, grid_y);
    }

    /// Check if a world position is solid
    pub fn isSolidAt(self: *TileMap, world_x: i32, world_y: i32) bool {
        if (self.getTileAtPixel(world_x, world_y)) |tile| {
            return tile.tile_type.isSolid();
        }
        return false;
    }

    /// Check collision with a bounding box (returns collision info)
    pub fn checkCollision(
        self: *TileMap,
        x: i32,
        y: i32,
        w: i32,
        h: i32,
    ) CollisionResult {
        var result = CollisionResult{};

        // Check all tiles that overlap with the bounding box
        const left_tile = @max(0, @divTrunc(x, self.tile_size));
        const right_tile = @divTrunc(x + w - 1, self.tile_size);
        const top_tile = @max(0, @divTrunc(y, self.tile_size));
        const bottom_tile = @divTrunc(y + h - 1, self.tile_size);

        var ty: i32 = top_tile;
        while (ty <= bottom_tile) : (ty += 1) {
            var tx: i32 = left_tile;
            while (tx <= right_tile) : (tx += 1) {
                if (tx < 0 or ty < 0) continue;
                const grid_x = @as(usize, @intCast(tx));
                const grid_y = @as(usize, @intCast(ty));

                if (self.getTile(grid_x, grid_y)) |tile| {
                    if (tile.tile_type.isSolid()) {
                        const tile_x = tx * self.tile_size;
                        const tile_y = ty * self.tile_size;

                        // Determine collision direction
                        const center_x = x + @divTrunc(w, 2);
                        const center_y = y + @divTrunc(h, 2);
                        const tile_center_x = tile_x + @divTrunc(self.tile_size, 2);
                        const tile_center_y = tile_y + @divTrunc(self.tile_size, 2);

                        const dx = center_x - tile_center_x;
                        const dy = center_y - tile_center_y;

                        if (@abs(dx) > @abs(dy)) {
                            if (dx > 0) {
                                result.left = true;
                                result.left_x = tile_x + self.tile_size;
                            } else {
                                result.right = true;
                                result.right_x = tile_x;
                            }
                        } else {
                            if (dy > 0) {
                                result.top = true;
                                result.top_y = tile_y + self.tile_size;
                                result.hit_tile = tile;
                            } else {
                                result.bottom = true;
                                result.bottom_y = tile_y;
                            }
                        }
                    }
                }
            }
        }

        return result;
    }

    /// Update animated tiles
    pub fn update(self: *TileMap) void {
        // Step question block animations
        self.sprites.question.stepActiveAnimation();
    }

    /// Render visible tiles to screen
    pub fn render(
        self: *TileMap,
        allocator: std.mem.Allocator,
        camera_x: i32,
        camera_y: i32,
    ) !void {
        const screen_w = @as(i32, @intCast(self.screen.w));
        const screen_h = @as(i32, @intCast(self.screen.h));

        // Calculate visible tile range
        const start_tile_x = @max(0, @divTrunc(camera_x, self.tile_size));
        const end_tile_x = @divTrunc(camera_x + screen_w, self.tile_size) + 1;
        const start_tile_y = @max(0, @divTrunc(camera_y, self.tile_size));
        const end_tile_y = @divTrunc(camera_y + screen_h, self.tile_size) + 1;

        var ty: i32 = start_tile_y;
        while (ty <= end_tile_y) : (ty += 1) {
            var tx: i32 = start_tile_x;
            while (tx <= end_tile_x) : (tx += 1) {
                if (tx < 0 or ty < 0) continue;
                const grid_x = @as(usize, @intCast(tx));
                const grid_y = @as(usize, @intCast(ty));

                if (grid_x >= self.width or grid_y >= self.height) continue;

                const tile = &self.tiles[grid_y][grid_x];
                if (tile.tile_type == .Empty) continue;

                // Calculate screen position
                const screen_x = tx * self.tile_size - camera_x;
                const screen_y = ty * self.tile_size - camera_y;

                // Get appropriate sprite
                const sprite: *Sprite = switch (tile.tile_type) {
                    .Ground => self.sprites.ground,
                    .Brick => self.sprites.brick,
                    .Question => if (tile.hit) self.sprites.empty_block else self.sprites.question,
                    .EmptyBlock => self.sprites.empty_block,
                    .PipeTopLeft, .PipeTopRight => self.sprites.pipe_top,
                    .PipeBodyLeft, .PipeBodyRight => self.sprites.pipe_body,
                    .Empty => continue,
                };

                sprite.setXY(screen_x, screen_y);
                const surface = try sprite.getCurrentFrameSurface();
                try self.screen.addRenderSurface(allocator, surface);
            }
        }
    }

    /// Load level from string data
    pub fn loadFromString(self: *TileMap, data: []const u8) void {
        var y: usize = 0;
        var x: usize = 0;

        for (data) |char| {
            if (char == '\n') {
                y += 1;
                x = 0;
                continue;
            }

            if (y >= self.height or x >= self.width) {
                x += 1;
                continue;
            }

            const tile_type: TileType = switch (char) {
                '.' => .Empty,
                '#' => .Ground,
                'B' => .Brick,
                '?' => .Question,
                'X' => .EmptyBlock,
                '[' => .PipeTopLeft,
                ']' => .PipeTopRight,
                '{' => .PipeBodyLeft,
                '}' => .PipeBodyRight,
                else => .Empty,
            };

            self.setTile(x, y, tile_type);
            x += 1;
        }
    }
};

/// Result of collision check
pub const CollisionResult = struct {
    top: bool = false,
    bottom: bool = false,
    left: bool = false,
    right: bool = false,

    top_y: i32 = 0,
    bottom_y: i32 = 0,
    left_x: i32 = 0,
    right_x: i32 = 0,

    hit_tile: ?*Tile = null,

    pub fn any(self: CollisionResult) bool {
        return self.top or self.bottom or self.left or self.right;
    }
};
