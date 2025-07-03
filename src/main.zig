const std = @import("std");

const commands = @import("commands.zig");

const MAX_INPUT_SIZE = 4096;

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

    var inputBuffer: [MAX_INPUT_SIZE]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        try bw.flush();

        const input = try stdin.readUntilDelimiterOrEof(&inputBuffer, '\n') orelse "";

        var iter = std.mem.splitScalar(u8, input, ' ');

        const commandStr = iter.next() orelse continue;

        const command = std.meta.stringToEnum(commands.Command, commandStr) orelse {
            try stdout.print("msh: command not found: {s}\n", .{commandStr});
            continue;
        };

        switch (command) {
            .exit => {
                std.process.exit(0);
            },
            .pwd => {
                try commands.pwd(&stdout);
            },
        }

        try bw.flush();
    }
}
