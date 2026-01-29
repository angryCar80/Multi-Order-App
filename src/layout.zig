const std = @import("std");
const root = @import("root.zig");

const Screen = struct {
    cols: usize,
    rows: usize,
};

// Get terminal dimensions with fallback
pub fn getTerminalSize() Screen {
    var screen = Screen{ .cols = 80, .rows = 24 };

    // Try to get size from environment variables
    if (std.process.getEnvVarOwned(std.heap.page_allocator, "COLUMNS")) |cols_str| {
        screen.cols = std.fmt.parseInt(usize, cols_str, 10) catch screen.cols;
        std.heap.page_allocator.free(cols_str);
    } else |_| {}

    if (std.process.getEnvVarOwned(std.heap.page_allocator, "LINES")) |lines_str| {
        screen.rows = std.fmt.parseInt(usize, lines_str, 10) catch screen.rows;
        std.heap.page_allocator.free(lines_str);
    } else |_| {}

    return screen;
}

// Calculate center position for horizontal centering
pub fn getCenterX(content_width: usize) usize {
    const screen = getTerminalSize();
    return if (screen.cols > content_width) (screen.cols - content_width) / 2 else 0;
}

// Calculate center position for vertical centering
pub fn getCenterY(content_height: usize) usize {
    const screen = getTerminalSize();
    return if (screen.rows > content_height) (screen.rows - content_height) / 2 else 0;
}

// Move cursor to specific position
pub fn moveTo(x: usize, y: usize) !void {
    try root.stdout.print("\x1b[{};{}H", .{ y, x + 1 });
}

// Move to center position for a block of content
pub fn moveToCenter(content_width: usize, content_height: usize) !void {
    const center_x = getCenterX(content_width);
    const center_y = getCenterY(content_height);
    try moveTo(center_x, center_y);
}

// Print text at specific position
pub fn printAt(text: []const u8, x: usize, y: usize) !void {
    try moveTo(x, y);
    try root.stdout.print("{s}", .{text});
}

// Print colored text at specific position
pub fn printColoredAt(text: []const u8, x: usize, y: usize, fg: root.Color, bg: ?root.Color) !void {
    try moveTo(x, y);
    try root.printColored(text, fg, bg);
}

// Print text at specific horizontal position (current line)
pub fn printAtX(text: []const u8, x: usize) !void {
    try root.stdout.print("\x1b[{}G", .{x + 1});
    try root.stdout.print("{s}", .{text});
}

// Print colored text at specific horizontal position (current line)
pub fn printColoredAtX(text: []const u8, x: usize, fg: root.Color, bg: ?root.Color) !void {
    try root.stdout.print("\x1b[{}G", .{x + 1});
    try root.printColored(text, fg, bg);
}

// Print text centered horizontally (current line)
pub fn printCentered(text: []const u8) !void {
    const center_x = getCenterX(text.len);
    try printAtX(text, center_x);
}

// Print colored text centered horizontally (current line)
pub fn printColoredCentered(text: []const u8, fg: root.Color, bg: ?root.Color) !void {
    const center_x = getCenterX(text.len);
    try printColoredAtX(text, center_x, fg, bg);
}

// Print a centered message
pub fn printCenteredMessage(text: []const u8, y: usize) !void {
    try printColoredAt(text, getCenterX(text.len), y, root.theme.text, null);
}

// Print a centered message with color
pub fn printCenteredMessageColored(text: []const u8, y: usize, fg: root.Color, bg: ?root.Color) !void {
    try printColoredAt(text, getCenterX(text.len), y, fg, bg);
}

// Print centered message relative to another element
pub fn printCenteredMessageRelative(text: []const u8, base_y: usize, offset: usize, fg: root.Color, bg: ?root.Color) !void {
    try printCenteredMessageColored(text, base_y + offset, fg, bg);
}

// Center a box and return its position
pub fn getBoxPosition(box_width: usize, box_height: usize) struct { x: usize, y: usize } {
    return .{
        .x = getCenterX(box_width),
        .y = getCenterY(box_height),
    };
}

// Get safe Y position ensuring it stays within terminal
pub fn getSafeY(base_y: usize, offset: usize) usize {
    const screen = getTerminalSize();
    const result_y = base_y + offset;
    return if (result_y >= screen.rows - 2) screen.rows - 3 else result_y;
}

// Calculate Y position for messages below a menu
pub fn getMessageY(menu_height: usize, menu_y: usize) usize {
    return getSafeY(menu_y + menu_height, 2);
}

// Calculate Y position for input prompts
pub fn getInputY(menu_height: usize, menu_y: usize) usize {
    return getSafeY(menu_y + menu_height, 3);
}
