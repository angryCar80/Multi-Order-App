const std = @import("std");

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
pub fn runTodoApp() !void {}

// TODO Use it but not now
// var tasks: std.ArrayList(Task) = .empty;
// defer {
//   for(tasks.items) |task| {
//     task.deinit(gpa);
//   }
//   tasks.deinit(gpa);
// }

// try tasks.append(gpa, new_task);
