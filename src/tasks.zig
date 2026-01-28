const std = @import("std");
const root = @import("root.zig");

// const print = root.printColored; // NOTE IDK

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

var stdin_buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
const stdin = &stdin_reader.interface;

const options: [5][]const u8 = .{ "Add Task", "See Tasks", "Back" };
const see_tasks: [3][]const u8 = .{ "Toggle Tasks", "Rename Tasks", "Back" };

pub const Task = struct {
    name: []u8,
    date: i32 = 0,
    toggled: bool = false,

    pub fn init(gpa: Allocator, name: []const u8) Allocator.Error!Task {
        return .{ .name = try gpa.dupe(u8, name) };
    }

    pub fn deinit(self: *const Task, gpa: Allocator) void {
        gpa.free(self.name);
    }
};

const Allocator = std.mem.Allocator;
pub fn runTodoApp() !void {
    try root.clear();
    try root.setRawMode(.on);
    var running: bool = true;
    while (running) {
        const key = try root.readKey();
        // TODO SHOW OPTIONS
        if (key == 'q') {
            running = false;
        } else if (key == 'o') {
            // try stdout.print("TRYING THE TASKS APP", .{});
            try root.printColored("TRY THE TASK APP\n", root.theme.accent, null);
            try stdout.flush();
        }
    }
}

// TODO Use it but not now
// var tasks: std.ArrayList(Task) = .empty;
// defer {
//   for(tasks.items) |task| {
//     task.deinit(gpa);
//   }
//   tasks.deinit(gpa);
// }

// try tasks.append(gpa, new_task);
