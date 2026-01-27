const std = @import("std");

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

                    // Display menu
                    for (options, 0..options.len) |o, i| {
                        if (i == current_option) {
                            try stdout.print("> {s}\n", .{o});
                        } else {
                            try stdout.print("  {s}\n", .{o});
                        }
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
                            try stdout.print("BROOOO THIS IS WORKING DUMBASS\n", .{});
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                        } else if (current_option == 1) {
                            current_option = 0;
                            try stdout.print("BROOOO THIS IS WORKING DUMBASS\n", .{});
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                        } else if (current_option == 4) { // last element (EXIT)
                            current_option = 0;
                            try stdout.print("Exitting..\n", .{});
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
                    try stdout.print("So This is the command screen\n", .{});
                    try stdout.print("You Can Write Some Commands to see available ones try 'help'\n", .{});
                    try stdout.flush();
                } else if (!user.firstTime) {
                    continue;
                }
                try stdout.print("> ", .{});
                try stdout.flush();
                try setRawMode(.off);
                const input = try stdin.takeDelimiterExclusive('\n');
                if (std.mem.eql(u8, input, "exit")) {
                    break;
                } else if (std.mem.eql(u8, input, "whoami")) {
                    try stdout.print("You are: {s}\n", .{user.name});
                    try stdout.flush();
                } else if (std.mem.eql(u8, input, "help")) {
                    try stdout.print("I Dont Know What I Should Do Here\n", .{});
                    try stdout.flush();
                } else {
                    try stdout.print("You Said: {s}\n", .{input});
                    try stdout.flush();
                }
                try setRawMode(.on);
            } else if (key == 'h') {
                try stdout.print("Available Commands: (Only Letters To press)\n", .{});
                try stdout.print("  - `C`  clears screen\n", .{});
                try stdout.print("  - `i`  opens the app shell\n", .{});
                try stdout.print("  - `o`  opens the selecet pallet\n", .{});
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
