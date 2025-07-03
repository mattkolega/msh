//! Built-in shell commands

const std = @import("std");

pub const Command = enum { exit, pwd };

/// Prints the pathname of the current working directory
pub fn pwd(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;
    const currentDir = try std.process.getCwd(&buffer);

    try stdout.print("{s}\n", .{currentDir});
}
