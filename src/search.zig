const std = @import("std");

const root = @import("root.zig");
const layout = @import("layout.zig");
const main = @import("main.zig");
const stdout = root.stdout;
const stdin = root.stdin;
const readKey = root.readKey;
const setRawMode = root.setRawMode;
const theme = root.theme;
const clear = root.clear;
const printColored = root.printColored;

pub const SearchResult = struct {
    query: []const u8,
    matches: std.ArrayList(Match),

    pub const Match = struct {
        title: []const u8,
        content: []const u8,
        match_type: MatchType,
    };

    pub const MatchType = enum {
        Note,
        Task,
        Date,
    };
};

pub fn runSearch() !?SearchResult {
    const gpa = std.heap.page_allocator;

    // Initialize search buffer
    var search_buffer: [256]u8 = undefined;
    var search_len: usize = 0;

    // Search box dimensions
    const box_width = 50;
    const box_height = 3;
    const pos = layout.getBoxPosition(box_width, box_height + 8);

    try clear();

    // Main search loop
    while (true) {
        // Clear and redraw search interface
        try clear();

        // Draw search box border
        try layout.printColoredAt("╭────────────────────────────────────────────────╮", pos.x, pos.y, theme.primary, null);
        try layout.printColoredAt("│                                                │", pos.x, pos.y + 1, theme.primary, null);
        try layout.printColoredAt("╰────────────────────────────────────────────────╯", pos.x, pos.y + 2, theme.primary, null);

        // Draw search icon and prompt
        try layout.printColoredAt("🔍", pos.x + 2, pos.y + 1, theme.accent, null);
        try layout.printColoredAt("> ", pos.x + 5, pos.y + 1, theme.secondary, null);

        // Display current search text
        if (search_len > 0) {
            try layout.printColoredAt(search_buffer[0..search_len], pos.x + 7, pos.y + 1, theme.text, null);
        }

        // Draw blinking cursor
        try layout.printColoredAt("█", pos.x + 7 + search_len, pos.y + 1, theme.accent, null);

        // Draw title
        try layout.printCenteredMessageColored("SEARCH", pos.y - 1, theme.accent, null);

        // Draw instructions
        const instructions_y = pos.y + 4;
        try layout.printCenteredMessageColored("Type to search | Enter to submit | ESC to cancel", instructions_y, theme.text_dim, null);

        // Draw search stats if there's text
        if (search_len > 0) {
            try layout.printCenteredMessageColored("Searching across notes, tasks, and dates...", instructions_y + 2, theme.text_dim, null);
        }

        try stdout.flush();

        // Read key input
        const key = try readKey();

        // Handle special keys
        if (key == '\x1B') {
            // Escape sequence - check if it's ESC or arrow keys
            const second_byte = try readKey();
            if (second_byte == '[') {
                // Arrow key sequence - skip the third byte
                _ = try readKey();
                continue;
            } else {
                // ESC key pressed - cancel search
                try clear();
                try layout.printCenteredMessageColored("✗ Search cancelled", layout.getCenterY(1), theme.error_color, null);
                try stdout.flush();
                std.Thread.sleep(500 * std.time.ns_per_ms);
                return null;
            }
        } else if (key == '\r' or key == '\n') {
            // Enter key - submit search
            if (search_len > 0) {
                try clear();
                try layout.printCenteredMessageColored("✓ Searching for: ", layout.getCenterY(1), theme.success, null);
                try stdout.print("{s}", .{search_buffer[0..search_len]});
                try stdout.flush();
                std.Thread.sleep(800 * std.time.ns_per_ms);

                // Create and return search result
                const query = try gpa.dupe(u8, search_buffer[0..search_len]);
                return SearchResult{
                    .query = query,
                    .matches = try std.ArrayList(SearchResult.Match).initCapacity(gpa, 9000),
                };
            }
        } else if (key == 127 or key == '\x08') {
            // Backspace - delete last character
            if (search_len > 0) {
                search_len -= 1;
            }
        } else if (key == 3) {
            // Ctrl+C - cancel
            try clear();
            try layout.printCenteredMessageColored("✗ Search cancelled", layout.getCenterY(1), theme.error_color, null);
            try stdout.flush();
            std.Thread.sleep(500 * std.time.ns_per_ms);
            return null;
        } else if (key >= 32 and key <= 126) {
            // Printable ASCII character - add to buffer
            if (search_len < search_buffer.len) {
                search_buffer[search_len] = key;
                search_len += 1;
            }
        }
    }
}

pub fn displaySearchResults(result: SearchResult) !void {
    try clear();

    const pos = layout.getBoxPosition(60, 15);

    // Draw results box
    try layout.printColoredAt("╭────────────────────────────────────────────────────────────╮", pos.x, pos.y, theme.primary, null);
    try layout.printColoredAt("│                    SEARCH RESULTS                          │", pos.x, pos.y + 1, theme.primary, null);
    try layout.printColoredAt("├────────────────────────────────────────────────────────────┤", pos.x, pos.y + 2, theme.primary, null);

    // Display query
    try layout.printColoredAt("Query: ", pos.x + 2, pos.y + 3, theme.accent, null);
    try layout.printColoredAt(result.query, pos.x + 9, pos.y + 3, theme.text, null);

    try layout.printColoredAt("├────────────────────────────────────────────────────────────┤", pos.x, pos.y + 4, theme.primary, null);

    // Display matches or "no results"
    if (result.matches.items.len == 0) {
        try layout.printColoredAt("│          No results found                                  │", pos.x, pos.y + 6, theme.text_dim, null);
    } else {
        // Show first few matches
        const max_display = @min(result.matches.items.len, 5);
        for (result.matches.items[0..max_display], 0..) |match, i| {
            const row = pos.y + 6 + i;
            const type_icon = switch (match.match_type) {
                .Note => "📝",
                .Task => "✓",
                .Date => "📅",
            };
            try layout.printColoredAt(type_icon, pos.x + 2, row, theme.accent, null);
            try layout.printColoredAt(match.title, pos.x + 5, row, theme.text, null);
        }
    }

    // Close box
    try layout.printColoredAt("╰────────────────────────────────────────────────────────────╯", pos.x, pos.y + 12, theme.primary, null);

    // Instructions
    try layout.printCenteredMessageColored("Press any key to continue...", pos.y + 14, theme.text_dim, null);

    try stdout.flush();

    // Wait for any key
    _ = try readKey();
}

pub fn deinitSearchResult(result: *SearchResult, allocator: std.mem.Allocator) void {
    allocator.free(result.query);
    for (result.matches.items) |match| {
        allocator.free(match.title);
        allocator.free(match.content);
    }
    result.matches.deinit();
}
