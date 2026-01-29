const std = @import("std");

const layout = @import("layout.zig");
const main = @import("main.zig");
const root = @import("root.zig");
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

pub fn runTodoApp(user: *main.User) !void {
    const gpa = std.heap.page_allocator;
    try clear();
    try setRawMode(.on);

    var tasks: std.ArrayList(Task) = .empty;
    var current_option: i16 = 0;

    defer {
        for (tasks.items) |*task| {
            task.deinit(gpa);
        }
        tasks.deinit(gpa);
    }

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
                // Escape key pressed - exit todo app
                user.currentState = main.userstate.IDLE;
                break;
            }
        } else if (first_byte == '\r' or first_byte == '\n') {
            if (current_option == 0) {
                // Add Task
                const msg_menu_height = options.len + 5;
                const msg_menu_pos = layout.getBoxPosition(19, msg_menu_height);
                const msg_y = layout.getMessageY(msg_menu_height, msg_menu_pos.y);

                try layout.printCenteredMessageColored("✓ Add Task", msg_y, theme.success, null);
                try stdout.flush();
                std.Thread.sleep(1000 * std.time.ns_per_ms);

                const input_y = layout.getInputY(msg_menu_height, msg_menu_pos.y);
                try layout.printCenteredMessageColored("Enter Task Name: ", input_y, theme.text, null);
                try stdout.flush();
                try setRawMode(.off);
                const taskName = try stdin.takeDelimiter('\n');
                if (taskName) |name| {
                    const task_name = try gpa.dupe(u8, name);
                    const new_task = Task{ .date = 0, .name = task_name, .toggled = false };
                    try tasks.append(gpa, new_task);
                }
                try setRawMode(.on);
            } else if (current_option == 1) {
                // See Tasks
                try clear();

                if (tasks.items.len > 0) {
                    var task_selection: usize = 0;
                    var viewing_tasks = true;

                    while (viewing_tasks) {
                        try clear();

                        // Display header
                        const header_y = layout.getSafeY(2, 0);
                        try layout.printCenteredMessageColored("Your Tasks (ESC to exit)", header_y, theme.accent, null);

                        // Display tasks with selection
                        for (tasks.items, 0..) |task, i| {
                            const status = if (task.toggled) "✓" else "○";
                            const selector = if (i == task_selection) "> " else "  ";

                            const task_y = layout.getSafeY(header_y + 2 + i, 0);
                            const task_text = try std.fmt.allocPrint(gpa, "{s}{s} {s}", .{ selector, status, task.name });

                            if (i == task_selection) {
                                try layout.printCenteredMessageColored(task_text, task_y, theme.primary, null);
                            } else {
                                try layout.printCenteredMessage(task_text, task_y);
                            }

                            gpa.free(task_text);
                        }

                        // Display instructions
                        const instructions_y = layout.getSafeY(header_y + 2 + tasks.items.len + 1, 0);
                        try layout.printCenteredMessageColored("↑↓ Navigate | Space/Enter Toggle | ESC Exit", instructions_y, theme.text_dim, null);

                        try stdout.flush();

                        // Handle input
                        const key = try readKey();

                        if (key == 'k') {
                            // vim: k = up
                            if (task_selection > 0) task_selection -= 1;
                        } else if (key == 'j') {
                            // vim: j = down
                            if (task_selection < tasks.items.len - 1) task_selection += 1;
                        } else if (key == '\x1B') {
                            // Escape sequence
                            const second_byte = try readKey();
                            if (second_byte == '[') {
                                const third_byte = try readKey();
                                if (third_byte == 'A') {
                                    // Up arrow
                                    if (task_selection > 0) task_selection -= 1;
                                } else if (third_byte == 'B') {
                                    // Down arrow
                                    if (task_selection < tasks.items.len - 1) task_selection += 1;
                                }
                            } else {
                                // Escape key pressed
                                viewing_tasks = false;
                            }
                        } else if (key == ' ' or key == '\r' or key == '\n') {
                            // Toggle task
                            tasks.items[task_selection].toggled = !tasks.items[task_selection].toggled;
                        }
                    }
                } else {
                    const no_tasks_y = layout.getSafeY(5, 0);
                    try layout.printCenteredMessageColored("No tasks yet!", no_tasks_y, theme.text_dim, null);
                    try stdout.flush();
                    std.Thread.sleep(2000 * std.time.ns_per_ms);
                }
            } else if (current_option == 2) {
                // Back
                // user.currentState = main.userstate.IDLE;
                break;
            }
        } else if (first_byte == 'q') {
            // Quit todo app
            user.currentState = main.userstate.IDLE;
            break;
        }
    }
}
