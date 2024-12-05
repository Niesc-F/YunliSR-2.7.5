const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../../Session.zig");
const Allocator = std.mem.Allocator;

const test_command = @import("./commands/test.zig");
const tp_command = @import("./commands/tp.zig");
const unstuck_command = @import("./commands/unstuck.zig");

pub const Error = error{ CommandError, SystemResources, Unexpected, AccessDenied, WouldBlock, ConnectionResetByPeer, OutOfMemory, DiskQuota, FileTooBig, InputOutput, NoSpaceLeft, DeviceBusy, InvalidArgument, BrokenPipe, OperationAborted, NotOpenForWriting, LockViolation, Overflow, InvalidCharacter
// Add other errors if needed
};

const CommandFn = *const fn (session: *Session, args: []const u8, allocator: Allocator) Error!void;

const Command = struct {
    name: []const u8,
    action: []const u8,
    func: CommandFn,
};

const commandList = [_]Command{
    Command{ .name = "test", .action = "", .func = test_command.handle },
    Command{ .name = "tp", .action = "", .func = tp_command.handle },
    Command{ .name = "unstuck", .action = "", .func = unstuck_command.handle },

    //Command{ .name = "mlvl", .action = "", .func = mlevel_command.handle },
    //Command{ .name = "set", .action = "", .func = set_command.handle },
    //Command{ .name = "give", .action = "", .func = give_command.handle },
};

pub fn handleCommand(session: *Session, msg: []const u8, allocator: Allocator) Error!void {
    if (msg.len < 1 or msg[0] != '/') {
        std.debug.print("Message Text 2: {any}\n", .{msg});
        return sendMessage(session, "Commands must start with a '/'", allocator);
    }

    const input = msg[1..]; // Remove the leading '/'
    var tokenizer = std.mem.tokenize(u8, input, " ");
    const command = tokenizer.next().?;
    const args = tokenizer.rest();

    for (commandList) |cmd| {
        if (std.mem.eql(u8, cmd.name, command)) {
            return try cmd.func(session, args, allocator);
        }
    }
    try sendMessage(session, "Invalid command", allocator);
}

pub fn sendMessage(session: *Session, msg: []const u8, allocator: Allocator) Error!void {
    var chat = protocol.RevcMsgScNotify.init(allocator);
    chat.msg_type = protocol.MsgType.MSG_TYPE_CUSTOM_TEXT;
    chat.chat_type = protocol.ChatType.CHAT_TYPE_PRIVATE;
    chat.sender_id = 2000;
    chat.message_text = .{ .Const = msg };
    chat.receiver_id = 200267; // receiver_id
    try session.send(CmdID.CmdRevcMsgScNotify, chat);
}

// NLHLNACAPLK: u32 = 0,
// JLDDMEKLEOP: u32 = 0,
