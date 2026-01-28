const std = @import("std");
const root = @import("root.zig");
const print = root.printColored;
const clear = root.clear;
const setRawMode = root.setRawMode;
const readKey = root.readKey;
const theme = root.theme;

const tasks = @import("tasks.zig");

const userstate = enum {
    // NOT USING ANY APPS
    IDLE, // used if the user is not doing anything
    INPUTING, // used if the user is in the app shell
    // APPS STATUS
    TODO, // used if the user is in the todo app
    NOTE, // used if the user is in the note app
    DATE, // used if the user is in the date app
};

// Global theme instance

// TODO How to save settings in a file using zig (js*n)
const User = struct {
    name: []const u8,
    currentState: userstate,
    firstTime: bool,
};

// Color utility functions
fn printMenuItem(text: []const u8, selected: bool) !void {
    if (selected) {
        try print("> ", theme.primary, null);
        try print(text, theme.text, theme.primary);
    } else {
        try root.stdout.print("  {s}", .{text});
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
                    try print("╭─────────────────╮\n", theme.primary, null);
                    try print("│    MAIN MENU    │\n", theme.primary, null);
                    try print("╰─────────────────╯\n\n", theme.primary, null);

                    // Display menu items with colors
                    for (options, 0..options.len) |o, i| {
                        try printMenuItem(o, i == current_option);
                        try root.stdout.print("\n", .{});
                    }
                    try root.stdout.flush();

                    // Read input
                    const first_byte = try readKey();

                    if (first_byte == 'k') {
                        // vim: k = up (decrease index)
                        if (current_option > 0) {
                            current_option -= 1;
                        }
                    } else if (first_byte == 'j') {
                        // vim: j = down (increase index)
                        if (current_option < options.len - 1) {
                            current_option += 1;
                        }
                    } else if (first_byte == '\x1B') {
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
                            try print("✓ Opening Note App...\n", theme.success, null);
                            try root.stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try tasks.runTodoApp();
                            try clear();
                        } else if (current_option == 1) {
                            current_option = 0;
                            try print("✓ Opening Todo App...\n", theme.success, null);
                            try root.stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                        } else if (current_option == 4) { // last element (EXIT)
                            current_option = 0;
                            try print("✓ Exiting application...\n", theme.warning, null);
                            try root.stdout.flush();
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
                    try print("╭─────────────────────╮\n", theme.accent, null);
                    try print("│    COMMAND MODE     │\n", theme.accent, null);
                    try print("╰─────────────────────╯\n\n", theme.accent, null);
                    try print("Type 'help' for available commands\n", theme.text_dim, null);
                    try root.stdout.flush();
                    user.firstTime = false;
                } else if (!user.firstTime) {
                    continue;
                }
                try print("> ", theme.secondary, null);
                try root.stdout.flush();
                try setRawMode(.off);
                const input = try root.stdin.takeDelimiterExclusive('\n');
                if (std.mem.eql(u8, input, "exit")) {
                    try print("✓ Exiting command mode\n", theme.success, null);
                    try root.stdout.flush();
                } else if (std.mem.eql(u8, input, "whoami")) {
                    try print("User: ", theme.accent, null);
                    try root.stdout.print("{s}\n", .{user.name});
                    try root.stdout.flush();
                } else if (std.mem.eql(u8, input, "help")) {
                    try print("Available commands:\n", theme.accent, null);
                    try print("  whoami - Show current user\n", theme.text_dim, null);
                    try print("  exit   - Exit command mode\n", theme.text_dim, null);
                    try print("  help   - Show this help\n", theme.text_dim, null);
                    try root.stdout.flush();
                } else {
                    try print("Unknown command: ", theme.error_color, null);
                    try print("{s}\n", theme.text, null);
                    try root.stdout.flush();
                }

                try setRawMode(.on);
            } else if (key == 'h') {
                try print("Available Commands:\n", theme.accent, null);
                try print("  C  - Clear screen\n", theme.text_dim, null);
                try print("  i  - Open command shell\n", theme.text_dim, null);
                try print("  o  - Open selection menu\n", theme.text_dim, null);
                try print("  h  - Show this help\n", theme.text_dim, null);
                try print("  q  - Quit application\n", theme.text_dim, null);
                try root.stdout.flush();
            } else if (key == 'q') {
                running = false;
            } else {
                // try root.stdout.print("You Pressed: {d}", .{key});
                try root.stdout.flush();
            }
        }
    }
    try setRawMode(.off);
}
