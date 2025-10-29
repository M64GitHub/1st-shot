const std = @import("std");

/// LogFile wrapper for centralized logging across all game modules
pub const LogFile = struct {
    file: std.fs.File,

    /// Initialize LogFile by creating/truncating the log file and allocating on heap
    pub fn init(allocator: std.mem.Allocator, path: []const u8) !*LogFile {
        const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        errdefer file.close();

        const self = try allocator.create(LogFile);
        self.* = LogFile{ .file = file };
        return self;
    }

    /// Log a message with a module prefix
    /// Example: log_file.log("[GameManager]", "Starting initialization", .{})
    pub fn log(
        self: *LogFile,
        prefix: []const u8,
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        var buffer: [4096]u8 = undefined;
        const message = std.fmt.bufPrint(
            &buffer,
            "{s} " ++ fmt ++ "\n",
            .{prefix} ++ args,
        ) catch return;
        _ = self.file.write(message) catch {};
    }

    /// Close the log file and free heap allocation
    pub fn deinit(self: *LogFile, allocator: std.mem.Allocator) void {
        self.file.close();
        allocator.destroy(self);
    }
};
