const std = @import("std");
const main_zig = @import("src/main.zig");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {

    // Test color system
    try stdout.print("{s}Color System Test:{s}\n", .{ main_zig.Color.bright_blue.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}Success:{s} {s}✓{s}\n", .{ main_zig.Color.bright_cyan.fg(), main_zig.Color.reset.fg(), main_zig.Color.green.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}Warning:{s} {s}⚠{s}\n", .{ main_zig.Color.bright_cyan.fg(), main_zig.Color.reset.fg(), main_zig.Color.yellow.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}Error:{s} {s}✗{s}\n", .{ main_zig.Color.bright_cyan.fg(), main_zig.Color.reset.fg(), main_zig.Color.red.fg(), main_zig.Color.reset.fg() });

    try stdout.print("\n{s}Menu Preview:{s}\n", .{ main_zig.Color.bright_blue.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}╭─────────────────╮{s}\n", .{ main_zig.Color.blue.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}│   MAIN MENU    │{s}\n", .{ main_zig.Color.blue.fg(), main_zig.Color.reset.fg() });
    try stdout.print("{s}╰─────────────────╯{s}\n\n", .{ main_zig.Color.blue.fg(), main_zig.Color.reset.fg() });

    try stdout.print("{s}> {s}Note App{s}\n", .{ main_zig.Color.blue.fg(), main_zig.Color.white.fg(), main_zig.Color.reset.fg() });
    try stdout.print("  Todo App\n");
    try stdout.print("{s}> {s}Exit{s}\n", .{ main_zig.Color.blue.fg(), main_zig.Color.white.fg(), main_zig.Color.reset.fg() });
}
