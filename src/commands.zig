//! Built-in shell commands

const std = @import("std");

pub const Command = enum { cd, exit, pwd };

/// Changes the working directory
pub fn cd(stdout: anytype, args: []const []const u8) !void {
    if (args.len != 1) {
        try stdout.print("cd: too many arguments\n", .{});
        return;
    }

    var path = args[0];

    if (std.mem.eql(u8, path, "~")) {
        path = std.posix.getenv("HOME") orelse {
            try stdout.print("cd: couldn't find home directory\n", .{});
            return;
        };
    }

    std.process.changeCurDir(path) catch |err| {
        switch (err) {
            error.FileNotFound => try stdout.print("cd: no such file or directory: {s}\n", .{path}),
            else => return err,
        }
    };
}

/// Prints the pathname of the current working directory
pub fn pwd(stdout: anytype) !void {
    var buffer: [1024]u8 = undefined;
    const currentDir = try std.process.getCwd(&buffer);

    try stdout.print("{s}\n", .{currentDir});
}
