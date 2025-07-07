const std = @import("std");

const commands = @import("commands.zig");

const MAX_BUFFER_SIZE = 4096;

/// Converts an iterator to an array of items
fn convertIteratorToArr(allocator: std.mem.Allocator, iter: *std.mem.SplitIterator(u8, .scalar)) ![]const []const u8 {
    var itemList = std.ArrayList([]const u8).init(allocator);
    defer itemList.deinit();

    while (iter.next()) |item| {
        if (std.mem.eql(u8, item, "\r") or std.mem.eql(u8, item, "\n") or std.mem.eql(u8, item, "\t") or std.mem.eql(u8, item, "")) { // Ignore control chars
            continue;
        }
        try itemList.append(item);
    }

    return try itemList.toOwnedSlice();
}

pub fn main() !void {
    const stdoutFile = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdoutFile);
    const stdout = bw.writer();

    try stdout.print("Welcome to msh, matt's interactive shell environment.\n", .{});
    try stdout.print("Type 'help' to see a list of available commands.\n", .{});
    try bw.flush();

    const stdinFile = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdinFile);
    const stdin = br.reader();

    var inputBuffer: [MAX_BUFFER_SIZE]u8 = undefined;

    var allocBuffer: [MAX_BUFFER_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&allocBuffer);
    const allocator = fba.allocator();

    while (true) {
        try stdout.print("$ ", .{});
        try bw.flush();

        const input = try stdin.readUntilDelimiterOrEof(&inputBuffer, '\n') orelse "";

        var iter = std.mem.splitScalar(u8, input, ' ');

        const commandToken = iter.next() orelse continue;
        if (commandToken.len == 0) continue;

        const command = std.meta.stringToEnum(commands.Command, commandToken) orelse {
            try stdout.print("msh: command not found: {s}\n", .{commandToken});
            continue;
        };

        const args = try convertIteratorToArr(allocator, &iter);

        switch (command) {
            .cd => {
                try commands.cd(&stdout, args);
            },
            .exit => {
                std.process.exit(0);
            },
            .pwd => {
                try commands.pwd(&stdout);
            },
            .touch => {
                try commands.touch(&stdout, args);
            },
        }

        try bw.flush();
    }
}
