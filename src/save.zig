const std = @import("std");

const root = @import("root.zig");
const stdin = root.stdin;
const stdout = root.stdout;
const task = @import("tasks.zig");
const Task = task.Task;

const cwd = std.fs.cwd();

const TASKS_PATH = "./tasks.json";
const NOTE_PATH = "./notes.json";

pub fn getTaskName(new_task: Task) !Task {
    return .{ .date = new_task.date, .name = new_task.name, .toggled = new_task.toggled };
}

pub fn saveTasks(new_task: Task) !void {
    _ = new_task;
    // const tasks = getTaskName(new_task);
    // _ = tasks;
    var file = try cwd.createFile(TASKS_PATH, .{});
    defer file.close();

    var file_append = try cwd.openFile(TASKS_PATH, .{ .mode = .write_only });
    defer file_append.close();
    _ = try file_append.write("HHLSJADLj");
}

//TODO Something for later
pub fn saveNotes() !void {}
