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

    const Star = struct {
        x: i32,
        y: i32,
        z: i32,
        accumulator: i32, // Accumulator for smooth movement
        adder_value: i32, // Step per frame
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
                .z = self.rng.random().intRangeAtMost(i32, 0, self.depth),
                .accumulator = 0,
                .adder_value = star.z + 50, // Offset for z=0
            };
        }
        return self;
    }

    pub fn deinit(self: *Starfield, allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }

    pub fn update(self: *Starfield) void {
        self.frame_counter += 1;
        const w = self.out_surface.w;
        const h = self.out_surface.h;

        self.out_surface.clearTransparent();

        for (&self.stars) |*star| {
            star.accumulator += star.adder_value;
            if (star.accumulator >= self.threshold) {
                star.y += 2;
                star.accumulator -= self.threshold;
            }

            if (star.y >= h) {
                star.y = 0;
                star.x = self.rng.random().intRangeAtMost(i32, 0, @intCast(w - 1));
                star.z = self.rng.random().intRangeAtMost(i32, 0, self.depth);
                star.adder_value = star.z + 50;
                star.accumulator = 0;
            }

            const idx = @as(usize, @intCast(star.y)) * w +
                @as(usize, @intCast(star.x));

            const dot_char: u21 = switch (star.z) {
                0...49 => 0x00B7, // ·
                50...99 => 0x2022, // •
                100...149 => 0x25E6, // ◦
                150...199 => '*', // ●
                else => 0x25CF, // ● 0x25C9, // ◉
            };
            self.out_surface.char_map[idx] = dot_char;

            const color_val = @as(u8, @intCast(@min(250, star.z + 50)));

            self.out_surface.color_map[idx] = .{
                .r = color_val / 2 + 25,
                .g = color_val / 2 + 25,
                .b = color_val,
            }; // 250 shades of gray ;)
            self.out_surface.shadow_map[idx] = 1;
        }
    }
};
