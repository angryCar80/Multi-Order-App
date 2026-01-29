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

const options: [3][]const u8 = .{ "Add Task", "See Tasks", "Back" };
const see_tasks: [3][]const u8 = .{ "Toggle Tasks", "Rename Tasks", "Back" };

pub const Task = struct {
    name: []const u8,
    date: i32 = 0,
    toggled: bool = false,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) std.mem.Allocator.Error!Task {
        return .{ .name = try allocator.dupe(u8, name) };
    }

    pub fn deinit(self: *const Task, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

pub fn runTodoApp() !void {
    const gpa = std.heap.page_allocator;
    try clear();
    try setRawMode(.on);

    var tasks: std.ArrayList(Task) = .empty;
    var current_option: i16 = 0;

    while (true) {
        try clear();

        const menu_width = 19;
        const menu_height = options.len + 5;
        const pos = layout.getBoxPosition(menu_width, menu_height);

        // Display menu title
        try layout.printColoredAt("╭─────────────────╮", pos.x, pos.y, theme.primary, null);
        try layout.printColoredAt("│     TODO APP    │", pos.x, pos.y + 1, theme.primary, null);
        try layout.printColoredAt("╰─────────────────╯", pos.x, pos.y + 2, theme.primary, null);

        // Display menu items
        for (options, 0..options.len) |o, i| {
            if (i == current_option) {
                try layout.printColoredAt("> ", pos.x, pos.y + 4 + i, theme.primary, null);
                try root.printColored(o, theme.text, theme.primary);
            } else {
                try layout.printAt("  ", pos.x, pos.y + 4 + i);
                try stdout.print("{s}", .{o});
            }
        }
        try stdout.flush();

        const key = try readKey();

        if (key == 'k') {
            // vim: k = up (decrease index)
            if (current_option > 0) {
                current_option -= 1;
            }
        } else if (key == 'j') {
            // vim: j = down (increase index)
            if (current_option < options.len - 1) {
                current_option += 1;
            }
        } else if (key == '\x1B') {
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
                break;
            }
        } else if (key == '\r' or key == '\n') {
            if (current_option == 0) {
                // Add Task
                const msg_menu_height = options.len + 5;
                const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);

                try clear();
                try layout.printCenteredMessageColored("✓ Add Task", msg_y, theme.success, null);
                try stdout.flush();
                std.Thread.sleep(1000 * std.time.ns_per_ms);

                const input_y = layout.getInputY(msg_menu_height, msg_menu_pos.y);
                try layout.printCenteredMessageColored("Enter Task Name: ", input_y, theme.text, null);
                try stdout.flush();
                try setRawMode(.off);
                const taskName = try stdin.takeDelimiter('\n');
                const taskToggled = false;
                try tasks.append(gpa, .{ .date = 0, .name = taskName.?, .toggled = taskToggled });
                try setRawMode(.on);
            } else if (current_option == 1) {
                // See Tasks
                const msg_menu_height = options.len + 5;
                const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);

                try clear();
                try layout.printCenteredMessageColored("✓ See Tasks", msg_y, theme.success, null);
                try stdout.flush();
                std.Thread.sleep(1000 * std.time.ns_per_ms);

                if (tasks.items.len > 0) {
                    const list_y = layout.getSafeY(msg_y, 2);
                    try layout.printCenteredMessageColored("Your Tasks:", list_y, theme.accent, null);
                    for (tasks.items, 0..) |task, i| {
                        const status = if (task.toggled) "✓ " else "○ ";
                        const task_text = try std.fmt.allocPrint(gpa, "{s}{s}", .{ status, task.name });
                        const task_y = layout.getSafeY(list_y + 1 + i, 0);
                        try layout.printCenteredMessage(task_text, task_y);
                        gpa.free(task_text);
                    }
                } else {
                    const no_tasks_y = layout.getSafeY(msg_y, 2);
                    try layout.printCenteredMessageColored("No tasks yet!", no_tasks_y, theme.text_dim, null);
                }
                try stdout.flush();
                std.Thread.sleep(3000 * std.time.ns_per_ms);
            } else if (current_option == 2) {
                // Back
                break;
            }
        } else if (key == 'q') {
            // Quit todo app
            break;
        }
    }
}

// defer {
//     for (tasks.items) |task| {
//         task.deinit(gpa);
//     }
//     tasks.deinit(gpa);
// }

// try tasks.append(gpa, new_task);
