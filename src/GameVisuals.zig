const std = @import("std");
const movy = @import("movy");

const TimedVisual = @import("TimedVisual.zig").TimedVisual;

pub const GameVisual = struct {
    sprite: *movy.Sprite,
    fade_in: usize,
    hold: usize,
    fade_out: usize,
    visual: ?*TimedVisual = null,

    pub fn init(
        allocator: std.mem.Allocator,
        file_name: []const u8,
        name: []const u8,
        fade_in: usize,
        hold: usize,
        fade_out: usize,
    ) !GameVisual {
        const sprite = try movy.Sprite.initFromPng(allocator, file_name, name);

        return GameVisual{
            .sprite = sprite,
            .fade_in = fade_in,
            .hold = hold,
            .fade_out = fade_out,
        };
    }
};

pub const GameVisuals = struct {
    screen: *movy.Screen,
    paused: GameVisual,
    game: GameVisual,
    over: GameVisual,

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !GameVisuals {
        const paused = try GameVisual.init(
            allocator,
            "assets/paused.png",
            "game",
            20,
            1,
            20,
        );
        var pos = screen.getCenterCoords(paused.sprite.w, paused.sprite.h);
        paused.sprite.setXY(pos.x, pos.y);

        const game = try GameVisual.init(
            allocator,
            "assets/game.png",
            "game",
            50,
            1,
            50,
        );
        pos = screen.getCenterCoords(game.sprite.w, game.sprite.h);
        pos.y -= 20;
        game.sprite.setXY(pos.x, pos.y);

        const over = try GameVisual.init(
            allocator,
            "assets/over.png",
            "game",
            50,
            1,
            50,
        );
        pos = screen.getCenterCoords(over.sprite.w, over.sprite.h);
        pos.y += 20;
        over.sprite.setXY(pos.x, pos.y);

        return GameVisuals{
            .screen = screen,
            .game = game,
            .over = over,
            .paused = paused,
        };
    }

    pub fn deinit(self: *GameVisuals, allocator: std.mem.Allocator) void {
        self.game.sprite.deinit(allocator);
        self.over.sprite.deinit(allocator);
        self.paused.sprite.deinit(allocator);
    }
};
