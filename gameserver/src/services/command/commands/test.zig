const commandhandler = @import("../handler.zig");
const std = @import("std");
const Session = @import("../../../Session.zig");
const Allocator = std.mem.Allocator;
const Error = commandhandler.Error;

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    //std.debug.print("Handling test command\n", .{args});

    // Since sendMessage may throw an error, handle it with try
    try commandhandler.sendMessage(session, "Test Command for Chat\n", allocator);
}