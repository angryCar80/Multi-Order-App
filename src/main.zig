const std = @import("std");

const root = @import("root.zig");
const layout = @import("layout.zig");
const print = root.printColored;
const clear = root.clear;
const setRawMode = root.setRawMode;
const readKey = root.readKey;
const theme = root.theme;
const stdout = root.stdout;
const stdin = root.stdin;
const tasks = @import("tasks.zig");
const notes = @import("notes.zig");
const search = @import("search.zig");

pub const userstate = enum {
    // NOT USING ANY APPS
    IDLE, // used if the user is not doing anything
    INPUTING, // used if the user is in app shell
    // APPS STATUS
    TODO, // used if the user is in the todo app
    NOTE, // used if the user is in the note app
    DATE, // used if the user is in the date app
    SEARCH, // used if the user is in the Search app
};

// TODO How to save settings in a file using zig (js*n)
pub const User = struct {
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

    var user: User = .{ .currentState = userstate.IDLE, .name = "angryCar13", .firstTime = true };
    var current_option: i16 = 0;

    var running: bool = true; // Tracking app status
    // Simple App Loop
    while (running) {
        const key = try readKey();
        if (user.currentState == userstate.IDLE) {
            if (key == 'o') {
                var choosing: bool = true;
                try clear();
                while (choosing) {
                    // Clear screen
                    try clear();

                    const menu_width = 19;
                    const menu_height = options.len + 5;
                    const pos = layout.getBoxPosition(menu_width, menu_height);

                    // Display menu title
                    try layout.printColoredAt("╭─────────────────╮", pos.x, pos.y, theme.primary, null);
                    try layout.printColoredAt("│    MAIN MENU    │", pos.x, pos.y + 1, theme.primary, null);
                    try layout.printColoredAt("╰─────────────────╯", pos.x, pos.y + 2, theme.primary, null);

                    // Display menu items
                    for (options, 0..options.len) |o, i| {
                        if (i == current_option) {
                            try layout.printColoredAt("> ", pos.x, pos.y + 4 + i, theme.primary, null);
                            try root.printColored(o, theme.text, theme.primary);
                        } else {
                            try layout.printAt("  ", pos.x, pos.y + 4 + i);
                            try root.stdout.print("{s}", .{o});
                        }
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
                            user.currentState = userstate.IDLE;
                            break;
                        }
                    } else if (first_byte == '\r' or first_byte == '\n') {
                        if (current_option == 0) {
                            current_option = 0;
                            const msg_menu_height = options.len + 5;
                            const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                            const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);
                            try layout.printCenteredMessageColored("✓ Opening Note App...", msg_y, theme.success, null);
                            try root.stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                            try notes.runNoteApp(&user);
                        } else if (current_option == 1) {
                            user.currentState = userstate.TODO;
                            current_option = 0;
                            const msg_menu_height = options.len + 5;
                            const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                            const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);
                            try layout.printCenteredMessageColored("✓ Opening Todo App...", msg_y, theme.success, null);
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                            try tasks.runTodoApp(&user);
                        } else if (current_option == 2) {
                            user.currentState = userstate.SEARCH;
                            current_option = 0;
                            const msg_menu_height = options.len + 5;
                            const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                            const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);
                            try layout.printCenteredMessageColored("✓ Opening Search App...", msg_y, theme.success, null);
                            try stdout.flush();
                            std.Thread.sleep(1000 * std.time.ns_per_ms);
                            try clear();
                            _ = try search.runSearch();
                        } else if (current_option == 4) { // last element (EXIT)
                            current_option = 0;
                            const msg_menu_height = options.len + 5;
                            const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                            const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);
                            try layout.printCenteredMessageColored("✓ Exiting application...", msg_y, theme.warning, null);
                            try stdout.flush();
                            std.Thread.sleep(500 * std.time.ns_per_ms);
                            try clear();
                            user.currentState = userstate.IDLE;
                            break;
                        }
                    }
                }
            } else if (key == 'C') {
                try clear();
            } else if (key == 'i') {
                user.currentState = userstate.INPUTING;
                try clear();

                const cmd_width = 23;
                const cmd_pos = layout.getBoxPosition(cmd_width, 10);

                try layout.printColoredAt("╭─────────────────────╮", cmd_pos.x, cmd_pos.y, theme.accent, null);
                try layout.printColoredAt("│    COMMAND MODE     │", cmd_pos.x, cmd_pos.y + 1, theme.accent, null);
                try layout.printColoredAt("╰─────────────────────╯", cmd_pos.x, cmd_pos.y + 2, theme.accent, null);

                if (user.firstTime) {
                    try layout.printCenteredMessageColored("Type 'help' for available commands", cmd_pos.y + 4, theme.text_dim, null);
                    user.firstTime = false;
                }

                // Command loop - stay in command mode until user types "exit"
                while (user.currentState == userstate.INPUTING) {
                    try layout.printColoredAt("> ", cmd_pos.x, cmd_pos.y + 6, theme.secondary, null);
                    try stdout.flush();
                    try setRawMode(.off);
                    const input = try stdin.takeDelimiterExclusive('\n');
                    try setRawMode(.on);

                    if (std.mem.eql(u8, input, "exit")) {
                        try clear();
                        try layout.printCenteredMessageColored("✓ Exiting command mode", layout.getCenterY(1), theme.success, null);
                        try stdout.flush();
                        user.currentState = userstate.IDLE;
                    } else if (std.mem.eql(u8, input, "whoami")) {
                        try clear();
                        const user_y = layout.getCenterY(2);
                        try layout.printCenteredMessageColored("User: ", user_y, theme.accent, null);
                        try root.stdout.print("{s}", .{user.name});
                        try stdout.flush();
                    } else if (std.mem.eql(u8, input, "help")) {
                        try clear();
                        try layout.printColoredAt("╭─────────────────────╮", cmd_pos.x, cmd_pos.y, theme.accent, null);
                        try layout.printColoredAt("│    COMMAND MODE     │", cmd_pos.x, cmd_pos.y + 1, theme.accent, null);
                        try layout.printColoredAt("╰─────────────────────╯", cmd_pos.x, cmd_pos.y + 2, theme.accent, null);

                        const help_y = layout.getSafeY(cmd_pos.y + 2, 2);
                        try layout.printCenteredMessageColored("Available commands:", help_y, theme.accent, null);
                        try layout.printCenteredMessage("  whoami - Show current user", help_y + 1);
                        try layout.printCenteredMessage("  exit   - Exit command mode", help_y + 2);
                        try layout.printCenteredMessage("  help   - Show this help", help_y + 3);
                        try layout.printCenteredMessage("  clear  - Clear screen", help_y + 4);
                        try stdout.flush();
                    } else if (std.mem.eql(u8, input, "clear")) {
                        try clear();
                        try layout.printColoredAt("╭─────────────────────╮", cmd_pos.x, cmd_pos.y, theme.accent, null);
                        try layout.printColoredAt("│    COMMAND MODE     │", cmd_pos.x, cmd_pos.y + 1, theme.accent, null);
                        try layout.printColoredAt("╰─────────────────────╯", cmd_pos.x, cmd_pos.y + 2, theme.accent, null);
                    } else {
                        try clear();
                        const msg_y = layout.getCenterY(3);
                        try layout.printCenteredMessageColored("Unknown command: ", msg_y, theme.error_color, null);
                        try root.stdout.print("{s}", .{input});
                        try layout.printCenteredMessageColored("Type 'help' for available commands", msg_y + 2, theme.text_dim, null);
                        try stdout.flush();
                    }
                }
            } else if (key == 'h') {
                const help_y = layout.getCenterY(7);
                try layout.printCenteredMessageColored("Available Commands:", help_y, theme.accent, null);
                try layout.printCenteredMessage("  C  - Clear screen", help_y + 1);
                try layout.printCenteredMessage("  i  - Open command shell (Change Settings 'LATER')", help_y + 2);
                try layout.printCenteredMessage("  o  - Open selection menu", help_y + 3);
                try layout.printCenteredMessage("  h  - Show this help", help_y + 4);
                try layout.printCenteredMessage("  q  - Quit application", help_y + 5);
                try stdout.flush();
            } else if (key == 'q') {
                running = false;
            } else {
                try stdout.flush();
            }
        }
    }
    try setRawMode(.off);
}
