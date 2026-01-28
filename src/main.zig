const std = @import("std");

const Color = enum {
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

const Theme = struct {
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

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

var stdin_buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
const stdin = &stdin_reader.interface;

const userstate = enum {
    NOTING,
    IDLE,
    INPUTING,
};

// Global theme instance
const theme = Theme.init();

// TODO How to save settings in a file using zig (js*n)
const User = struct {
    name: []const u8,
    currentState: userstate,
    firstTime: bool,
};

// Clearing screen
fn clear() !void {
    try stdout.print("\x1b[2J\x1b[H", .{});
    try stdout.flush();
}
// Raw Mode Thing
fn setRawMode(state: enum(u1) { on, off }) !void {
    var termios = try std.posix.tcgetattr(0);
    termios.lflag.ECHO = state != .on;
    termios.lflag.ICANON = state != .on;
    try std.posix.tcsetattr(0, .FLUSH, termios);
}

fn readKey() !u8 {
    const bytes_read: u8 = try stdin.takeByte();
    if (bytes_read == 0) return error.EndOfFile;
    return bytes_read;
}

fn readArrowKey() !?[]const u8 {
    const first_byte = try readKey();
    if (first_byte != '\x1B') return null;

    const second_byte = try readKey();
    if (second_byte != '[') return null;

    const third_byte = try readKey();
    return switch (third_byte) {
        'A' => "up",
        'B' => "down",
        else => null,
    };
}

// Color utility functions
fn printColored(text: []const u8, fg: Color, bg: ?Color) !void {
    if (bg) |background| {
        try stdout.print("{s}{s}{s}{s}", .{ background.bg(), fg.fg(), text, Color.reset.fg() });
    } else {
        try stdout.print("{s}{s}{s}", .{ fg.fg(), text, Color.reset.fg() });
    }
}

fn printMenuItem(text: []const u8, selected: bool) !void {
    if (selected) {
        try printColored("> ", theme.primary, null);
        try printColored(text, theme.text, theme.primary);
    } else {
        try stdout.print("  {s}", .{text});
    }
}
pub fn main() !void {
    try setRawMode(.on);

    const options: [5][]const u8 = .{ "Note App", "Todo App", "Search (Not Now)", "Date Persistenc", "Exit" };

    var running: bool = true;

    var user: User = .{ .currentState = userstate.IDLE, .name = "angryCar13", .firstTime = true };
    var current_option: i16 = 0;
    // Simple App Loop
    while (running) {
        const key = try readKey();
        if (user.currentState == userstate.IDLE) {
            if (key == 'o') {
                var choosing: bool = true;
                try clear();
                while (choosing) {
                    // Clear screen and move cursor to top-left
                    try clear();

                    // Display menu title
                    try printColored("╭─────────────────╮\n", theme.primary, null);
                    try printColored("│   MAIN MENU    │\n", theme.primary, null);
                    try printColored("╰─────────────────╯\n\n", theme.primary, null);

                    // Display menu items with colors
                    for (options, 0..options.len) |o, i| {
                        try printMenuItem(o, i == current_option);
                        try stdout.print("\n", .{});
                    }
                    try stdout.flush();

                    // Read input
                    const first_byte = try readKey();

                    if (first_byte == '\x1B') {
                        // Read the next two bytes for arrow sequence
                        const second_byte = try readKey();
                        if (second_byte == '[') {
                            const third_byte = try readKey();
                            if (third_byte == 'A') {
                                // Up arrow
                                if (current_option > 0) {
                                    current_option -= 1;
                                }
                            } else if (third_byte == 'B') {
                                // Down arrow
                                if (current_option < options.len - 1) {
                                    current_option += 1;
                                }
                            }
                        } else {
                            // Escape key pressed
                            choosing = false;
                            break;
                        }
                    } else if (first_byte == '\r' or first_byte == '\n') {
                        if (current_option == 0) {
                            current_option = 0;
                            try printColored("✓ Opening Note App...\n", theme.success, null);
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                        } else if (current_option == 1) {
                            current_option = 0;
                            try printColored("✓ Opening Todo App...\n", theme.success, null);
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                        } else if (current_option == 4) { // last element (EXIT)
                            current_option = 0;
                            try printColored("✓ Exiting application...\n", theme.warning, null);
                            try stdout.flush();
                            std.Thread.sleep(500 * std.time.ns_per_ms);
                            try clear();
                            break;
                        }
                    }
                }
            } else if (key == 'C') {
                try clear();
            } else if (key == 'i') {
                user.currentState = userstate.INPUTING;
                if (user.firstTime) {
                    try printColored("╭─────────────────────╮\n", theme.accent, null);
                    try printColored("│    COMMAND MODE     │\n", theme.accent, null);
                    try printColored("╰─────────────────────╯\n\n", theme.accent, null);
                    try printColored("Type 'help' for available commands\n", theme.text_dim, null);
                    try stdout.flush();
                    user.currentState = userstate.IDLE;
                } else if (!user.firstTime) {
                    continue;
                }
                try printColored("> ", theme.secondary, null);
                try stdout.flush();
                try setRawMode(.off);
                const input = try stdin.takeDelimiterExclusive('\n');
                if (std.mem.eql(u8, input, "exit")) {
                    try printColored("✓ Exiting command mode\n", theme.success, null);
                    try stdout.flush();
                } else if (std.mem.eql(u8, input, "whoami")) {
                    try printColored("User: ", theme.accent, null);
                    try stdout.print("{s}\n", .{user.name});
                    try stdout.flush();
                } else if (std.mem.eql(u8, input, "help")) {
                    try printColored("Available commands:\n", theme.accent, null);
                    try printColored("  whoami - Show current user\n", theme.text_dim, null);
                    try printColored("  exit   - Exit command mode\n", theme.text_dim, null);
                    try printColored("  help   - Show this help\n", theme.text_dim, null);
                    try stdout.flush();
                } else {
                    try printColored("Unknown command: ", theme.error_color, null);
                    try printColored("{s}\n", theme.text, null);
                    try stdout.flush();
                }

                try setRawMode(.on);
            } else if (key == 'h') {
                try printColored("Available Commands:\n", theme.accent, null);
                try printColored("  C  - Clear screen\n", theme.text_dim, null);
                try printColored("  i  - Open command shell\n", theme.text_dim, null);
                try printColored("  o  - Open selection menu\n", theme.text_dim, null);
                try printColored("  h  - Show this help\n", theme.text_dim, null);
                try printColored("  q  - Quit application\n", theme.text_dim, null);
                try stdout.flush();
            } else if (key == 'q') {
                running = false;
            } else {
                // try stdout.print("You Pressed: {d}", .{key});
                try stdout.flush();
            }
        }
    }
    try setRawMode(.off);
}
