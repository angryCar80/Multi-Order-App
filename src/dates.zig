const std = @import("std");
const root = @import("root.zig");

pub const Date = struct {
    day: i32,
    month: i32,
    year: i32,

    pub fn init(self: *const Date) !void {
        _ = self;
    }
};

pub fn runDateApp() !void {}
