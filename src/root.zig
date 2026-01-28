//! PUTTING HERE EVERYTHING THAT AM GOING TO USE ON ALL FILES
const std = @import("std");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
pub const stdout = &stdout_writer.interface;

var stdin_buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
pub const stdin = &stdin_reader.interface;

pub const Color = enum {
    // Standard colors
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    // Bright colors
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
    reset,

    pub fn fg(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[30m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
            .bright_black => "\x1b[90m",
            .bright_red => "\x1b[91m",
            .bright_green => "\x1b[92m",
            .bright_yellow => "\x1b[93m",
            .bright_blue => "\x1b[94m",
            .bright_magenta => "\x1b[95m",
            .bright_cyan => "\x1b[96m",
            .bright_white => "\x1b[97m",
            .reset => "\x1b[0m",
        };
    }

    pub fn bg(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[40m",
            .red => "\x1b[41m",
            .green => "\x1b[42m",
            .yellow => "\x1b[43m",
            .blue => "\x1b[44m",
            .magenta => "\x1b[45m",
            .cyan => "\x1b[46m",
            .white => "\x1b[47m",
            .bright_black => "\x1b[100m",
            .bright_red => "\x1b[101m",
            .bright_green => "\x1b[102m",
            .bright_yellow => "\x1b[103m",
            .bright_blue => "\x1b[104m",
            .bright_magenta => "\x1b[105m",
            .bright_cyan => "\x1b[106m",
            .bright_white => "\x1b[107m",
            .reset => "\x1b[0m",
        };
    }
};

pub const Theme = struct {
    primary: Color,
    secondary: Color,
    accent: Color,
    success: Color,
    warning: Color,
    error_color: Color,
    background: Color,
    surface: Color,
    text: Color,
    text_dim: Color,

    pub fn init() Theme {
        return Theme{
            .primary = Color.blue,
            .secondary = Color.cyan,
            .accent = Color.bright_magenta,
            .success = Color.green,
            .warning = Color.yellow,
            .error_color = Color.red,
            .background = Color.black,
            .surface = Color.bright_black,
            .text = Color.white,
            .text_dim = Color.bright_white,
        };
    }
};

// INITIALIZING THE APP THEME
pub const theme = Theme.init();

// COLOR PRINTING USING THE STRUCT ABOVE
pub fn printColored(text: []const u8, fg: Color, bg: ?Color) !void {
    if (bg) |background| {
        try stdout.print("{s}{s}{s}{s}", .{ background.bg(), fg.fg(), text, Color.reset.fg() });
    } else {
        try stdout.print("{s}{s}{s}", .{ fg.fg(), text, Color.reset.fg() });
    }
}

// USING COLOR TO PRINT STUFF
pub fn printMenuItem(text: []const u8, selected: bool) !void {
    if (selected) {
        try printColored("> ", theme.primary, null);
        try printColored(text, theme.text, theme.primary);
    } else {
        try stdout.print("  {s}", .{text});
    }
}

// RAW MODE HANDELING
pub fn setRawMode(state: enum(u1) { on, off }) !void {
    var termios = try std.posix.tcgetattr(0);
    termios.lflag.ECHO = state != .on;
    termios.lflag.ICANON = state != .on;
    try std.posix.tcsetattr(0, .FLUSH, termios);
}

// READING KEYS (STDIN)
pub fn readKey() !u8 {
    const bytes_read: u8 = try stdin.takeByte();
    if (bytes_read == 0) return error.EndOfFile;
    return bytes_read;
}

pub fn clear() !void {
    try stdout.print("\x1b[2J\x1b[H", .{});
    try stdout.flush();
}
