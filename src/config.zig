const std = @import("std");

const root = @import("root.zig");
const stdout = root.stdout;
const stdin = root.stdin; // I Dont Know If am going to use ts

// Doing This Later
const Config = struct {
    file: std.fs.File,
    ui_theme: []const u8,
    ui_status_bar: bool,
    shell_history: bool,
    todo_autosave: bool,

    pub fn openFile() !void {}
    pub fn implementConf() !void {}
};
