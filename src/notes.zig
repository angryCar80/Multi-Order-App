const std = @import("std");

const layout = @import("layout.zig");
const root = @import("root.zig");
const main = @import("main.zig");
const stdout = root.stdout;
const stdin = root.stdin;
const readKey = root.readKey;
const setRawMode = root.setRawMode;
const theme = root.theme;

const clear = root.clear;
const options: [3][]const u8 = .{ "Add Note", "See Notes", "Back" };

pub const Note_Status = enum {
    Work,
    Study,
    New,
    Normal,
};

pub const Note = struct {
    title: []const u8,
    content: []const u8,
    current_status: Note_Status,

    pub fn init(allocator: std.mem.Allocator, title: []const u8, content: []const u8) std.mem.Allocator.Error!Note {
        return .{ .title = try allocator.dupe(u8, title), .content = try allocator.dupe(u8, content), .current_status = Note_Status.New };
    }
    pub fn deinit(self: *const Note, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
        allocator.free(self.content);
    }
};

pub fn runNoteApp(user: *main.User) !void {
    const gpa = std.heap.page_allocator;
    try clear();
    try setRawMode(.on);

    var notes: std.ArrayList(Note) = .empty;
    var current_option: i16 = 0;
    defer {
        for (notes.items) |*note| {
            note.deinit(gpa);
        }
        notes.deinit(gpa);
    }

    while (true) {
        try clear();

        const menu_width = 19;
        const menu_height = options.len + 5;
        const pos = layout.getBoxPosition(menu_width, menu_height);

        // Display menu title
        try layout.printColoredAt("╭─────────────────╮", pos.x, pos.y, theme.primary, null);
        try layout.printColoredAt("│     NOTE APP    │", pos.x, pos.y + 1, theme.primary, null);
        try layout.printColoredAt("╰─────────────────╯", pos.x, pos.y + 2, theme.primary, null);

        for (options, 0..options.len) |o, option_index| {
            if (option_index == current_option) {
                try layout.printColoredAt("> ", pos.x + 1, pos.y + 4 + option_index, theme.primary, null);
                try layout.printColoredAt(o, pos.x + 3, pos.y + 4 + option_index, theme.text, theme.primary);
            } else {
                try layout.printAt("  ", pos.x + 1, pos.y + 4 + option_index);
                try layout.printAt(o, pos.x + 3, pos.y + 4 + option_index);
            }
        }
        try stdout.flush();

        const first_byte = try readKey();
        if (first_byte == 'k') {
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
                // Escape key pressed - exit todo app
                user.currentState = main.userstate.IDLE;
                break;
            }
        } else if (first_byte == '\r' or first_byte == '\n') {
            if (current_option == 0) {
                // Add Note
                const msg_menu_height = options.len + 5;
                const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);

                try layout.printCenteredMessageColored("✓ Add Note", msg_y, theme.success, null);
                try stdout.flush();
                std.Thread.sleep(1000 * std.time.ns_per_ms);

                const input_y = layout.getInputY(msg_menu_height, msg_menu_pos.y);
                try layout.printCenteredMessageColored("Enter Note Title: ", input_y, theme.text, null);
                try stdout.flush();
                try setRawMode(.off);

                const noteTitle = try stdin.takeDelimiter('\n');
                const content_input_y = layout.getInputY(msg_menu_height, msg_menu_pos.y);
                try layout.printCenteredMessageColored("Enter Note Content: ", content_input_y, theme.text, null);
                try stdout.flush();
                const noteContent = try stdin.takeDelimiter('\n');
                if (noteTitle) |title| {
                    if (noteContent) |content| {
                        const new_note = try Note.init(gpa, title, content);
                        try notes.append(gpa, new_note);
                    }
                }
                try setRawMode(.on);
            } else if (current_option == 1) {
                // See Notes
                try clear();

                if (notes.items.len > 0) {
                    var note_selection: usize = 0;
                    var viewing_note = true;

                    while (viewing_note) {
                        try clear();

                        // Display header
                        const header_y = layout.getSafeY(2, 0);
                        try layout.printCenteredMessageColored("Your Notes (ESC to exit)", header_y, theme.accent, null);

                        // Display Notes with selection
                        for (notes.items, 0..) |note, i| {
                            const status_str = @tagName(note.current_status);
                            const note_y = header_y + 2 + i;

                            if (i == note_selection) {
                                try layout.printColoredAt("> ", 5, note_y, theme.primary, null);
                                try layout.printColoredAt(status_str, 8, note_y, theme.accent, null);
                                try layout.printColoredAt(" ", 8 + status_str.len, note_y, theme.text, null);
                                try layout.printColoredAt(note.title, 9 + status_str.len, note_y, theme.text, theme.primary);
                            } else {
                                try layout.printAt("  ", 5, note_y);
                                try layout.printAt(status_str, 8, note_y);
                                try layout.printAt(" ", 8 + status_str.len, note_y);
                                try layout.printAt(note.title, 9 + status_str.len, note_y);
                            }
                        }

                        // Display instructions
                        const instructions_y = header_y + 2 + notes.items.len + 1;
                        try layout.printAt("↑↓ Navigate | Space/Enter Toggle | ESC Exit", 5, instructions_y);

                        try stdout.flush();

                        // Handle input
                        const key = try readKey();

                        if (key == 'k') {
                            // vim: k = up
                            if (note_selection > 0) note_selection -= 1;
                        } else if (key == 'j') {
                            // vim: j = down
                            if (note_selection < notes.items.len - 1) note_selection += 1;
                        } else if (key == '\x1B') {
                            // Escape sequence
                            const second_byte = try readKey();
                            if (second_byte == '[') {
                                const third_byte = try readKey();
                                if (third_byte == 'A') {
                                    // Up arrow
                                    if (note_selection > 0) note_selection -= 1;
                                } else if (third_byte == 'B') {
                                    // Down arrow
                                    if (note_selection < notes.items.len - 1) note_selection += 1;
                                }
                            } else {
                                // Escape key pressed
                                viewing_note = false;
                            }
                        } else if (key == ' ' or key == '\r' or key == '\n') {
                            // Cycle through note statuses
                            const current_status = notes.items[note_selection].current_status;
                            notes.items[note_selection].current_status = switch (current_status) {
                                .New => .Work,
                                .Work => .Study,
                                .Study => .Normal,
                                .Normal => .New,
                            };
                        }
                    }
                } else {
                    const no_notes_y = layout.getSafeY(5, 0);
                    try layout.printCenteredMessageColored("No Notes yet!", no_notes_y, theme.text_dim, null);
                    try stdout.flush();
                    std.Thread.sleep(2000 * std.time.ns_per_ms);
                }
            } else if (current_option == 2) {
                // Back
                break;
            }
        } else if (first_byte == 'q') {
            // Quit todo app
            user.currentState = main.userstate.IDLE;
            break;
        }
    }
}
