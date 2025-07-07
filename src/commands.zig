//! Built-in shell commands

const std = @import("std");

pub const Command = enum { cd, exit, pwd, touch };

/// Creates a new file, if it alreadys exists then timestamps are updated
pub fn touch(stdout: anytype, args: []const []const u8) !void {
    if (args.len == 0) {
        try stdout.print("touch: missing path\n", .{});
        return;
    } else if (args.len > 1) {
        try stdout.print("touch: too many arguments\n", .{});
        return;
    }

    const path = args[0];

    var fileAlreadyExists = false;

    if (std.fs.cwd().createFile(path, .{ .exclusive = true })) |file| {
        file.close();
    } else |err| {
        switch (err) {
            error.PathAlreadyExists => fileAlreadyExists = true,
            else => return err,
        }
    }

    // Return if file didn't already exist and it has now been successfully created.
    // Otherwise we want to try to update the existing file's timestamps to the current time

    if (!fileAlreadyExists) return;

    const existingFile = std.fs.cwd().openFile(path, .{}) catch {
        try stdout.print("touch: failed to modify file: {s}\n", .{path});
        return;
    };
    defer existingFile.close();

    const currentTime = std.time.nanoTimestamp();
    existingFile.updateTimes(currentTime, currentTime) catch {
        try stdout.print("touch: failed to update file timestamp: {s}\n", .{path});
    };
}

/// Changes the working directory
pub fn cd(stdout: anytype, args: []const []const u8) !void {
    var path: []const u8 = undefined;

    if (args.len == 0) {
        path = "~";
    } else if (args.len == 1) {
        path = args[0];
    } else {
        try stdout.print("cd: too many arguments\n", .{});
        return;
    }

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
