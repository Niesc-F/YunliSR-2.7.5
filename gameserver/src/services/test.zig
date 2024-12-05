const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn onFnName(session: *Session, _: *const Packet, allocator: Allocator) !void {

}