const std = @import("std");
const movy = @import("movy");

pub const Starfield = struct {
    stars: [MaxStars]Star = undefined,
    depth: i32 = 250,
    threshold: i32 = 900, // Threshold for movement
    frame_counter: usize = 0,
    out_surface: *movy.RenderSurface,
    rng: std.Random.DefaultPrng,

    const MaxStars = 200;

    const StarType = enum {
        Normal,
        Flashy,
    };

    const FlashyInterval: usize = 100;

    const Star = struct {
        x: i32,
        y: i32,
        z: i32,
        accumulator: i32, // Accumulator for smooth movement
        adder_value: i32, // Step per frame
        kind: StarType,
        flashy_frame: usize = 0, // flashy star extension
        flashy_interval: usize = FlashyInterval, // flash all X frames
        flashy_ani_frame: usize = 0, // current frame in ani
        flashy_speed: usize = 5, // update flashy ani each X frames
        flashy_idx: usize = 0, // index into flashy ani
        flashy_char: u21 = 0x00B7,
        flashy_brightness: u8 = 0x40,
    };

    const StarKindDistribution = struct {
        // const KindWeights = [_]usize{ 90, 10 };
        const KindWeights = [_]usize{ 60, 30 };
        const KindMap = [_]StarType{ .Normal, .Flashy };

        fn randomStarKindWeighted(s: *Starfield) StarType {
            const idx = s.rng.random().weightedIndex(usize, &KindWeights);
            return KindMap[idx];
        }
    };

    pub fn init(
        allocator: std.mem.Allocator,
        screen: *movy.Screen,
    ) !*Starfield {
        const self = try allocator.create(Starfield);

        self.* = .{
            .out_surface = try movy.RenderSurface.init(
                allocator,
                screen.w,
                screen.h,
                movy.color.WHITE,
            ),
            .rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp())),
        };

        const w = screen.w;
        const h = screen.h;

        for (&self.stars) |*star| {
            const kind = StarKindDistribution.randomStarKindWeighted(self);
            const z = self.rng.random().intRangeAtMost(i32, 0, self.depth);
            star.* = .{
                .x = self.rng.random().intRangeAtMost(i32, 0, @as(
                    i32,
                    @intCast(w),
                ) - 1),
                .y = self.rng.random().intRangeAtMost(
                    i32,
                    0,
                    @as(i32, @intCast(h / 2)),
                ) * 2,
                .z = z,
                .accumulator = 0,
                .adder_value = z + 50, // Offs for z=0 to get initial brightness
                .kind = kind,
                .flashy_frame = self.rng.random().intRangeAtMost(u32, 0, 200),
            };
        }
        return self;
    }

    pub fn deinit(self: *Starfield, allocator: std.mem.Allocator) void {
        self.out_surface.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn update(self: *Starfield) void {
        self.frame_counter +%= 1;
        const w = self.out_surface.w;
        const h = self.out_surface.h;

        self.out_surface.clearTransparent();

        const r = self.rng.random();

        for (&self.stars) |*star| {
            star.accumulator += star.adder_value;
            if (star.accumulator >= self.threshold) {
                star.y += 2;
                star.accumulator -= self.threshold;
            }

            if (star.y >= h) {
                // reset the star
                star.y = 0;
                star.x = r.intRangeAtMost(i32, 0, @intCast(w - 1));
                star.z = r.intRangeAtMost(i32, 0, self.depth);
                star.adder_value = star.z + 50;
                star.accumulator = 0;
            }
            const map_idx =
                @as(usize, @intCast(star.y)) * w +
                @as(usize, @intCast(star.x));

            const dot_char: u21 = switch (star.z) {
                0...49 => 0x00B7, // ·
                50...99 => 0x2022, // •
                100...149 => 0x25E6, // ◦
                150...199 => '*', // ●
                else => 0x25CF, // ● 0x25C9, // ◉
            };

            const color_val = @as(u8, @intCast(@min(250, star.z + 50)));

            switch (star.kind) {
                .Normal => {
                    self.out_surface.char_map[map_idx] = dot_char;

                    self.out_surface.color_map[map_idx] = .{
                        .r = color_val / 2 + 25,
                        .g = color_val / 2 + 25,
                        .b = color_val,
                    }; // 250 shades of blueish}
                },
                .Flashy => {
                    const dot_char_ani =
                        [_]u21{
                            0x2022,
                            0x2022,
                            '*',
                            0x25CF,

                            0x25C9,
                            '*',
                            0x2022,
                            0x2022,
                            // '0', '1', '2', '3', '4', '5', '6', '7',
                        };

                    const brightnesses = [_]u8{
                        0x90,
                        0xb0,
                        0xd0,
                        0xff,
                        0xff,
                        0xd0,
                        0xb0,
                        0x90,
                    };

                    star.flashy_frame += 1;

                    // do flashy updates at all
                    if (star.flashy_frame > star.flashy_interval) {
                        star.flashy_ani_frame += 1;

                        // do 1 ani step
                        if (star.flashy_ani_frame > star.flashy_speed) {
                            star.flashy_ani_frame = 0;

                            // start/advance ani
                            star.flashy_char = dot_char_ani[star.flashy_idx];
                            star.flashy_brightness =
                                brightnesses[star.flashy_idx];

                            // advance ani
                            star.flashy_idx += 1;

                            // reset to 0 if at end
                            if (star.flashy_idx >= dot_char_ani.len + 1) {
                                star.flashy_idx = 0;
                                star.flashy_frame = 0;
                                star.flashy_char = dot_char;
                                star.flashy_frame =
                                    self.rng.random().intRangeAtMost(
                                        u32,
                                        0,
                                        FlashyInterval,
                                    );
                                // will set color in else branch next
                            }
                        }

                        self.out_surface.color_map[map_idx] = .{
                            .r = star.flashy_brightness,
                            .g = star.flashy_brightness,
                            .b = star.flashy_brightness,
                        };
                    } else {
                        // default color render
                        self.out_surface.color_map[map_idx] = .{
                            .r = color_val / 2 + 25,
                            .g = color_val / 2 + 25,
                            .b = color_val,
                        };
                    }

                    // render to surface
                    self.out_surface.char_map[map_idx] = star.flashy_char;
                },
            }

            self.out_surface.shadow_map[map_idx] = 1;
        }
    }
};
