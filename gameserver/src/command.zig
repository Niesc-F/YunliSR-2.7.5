const std = @import("std");
const protocol = @import("protocol");
const Session = @import("Session.zig");
const Packet = @import("Packet.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const CmdID = protocol.CmdID;

const test_command = @import("./commands/test.zig");
const tp_command = @import("./commands/tp.zig");
const unstuck_command = @import("./commands/unstuck.zig");
const sync_command = @import("./commands/sync.zig");

// Add other errors if needed
pub const Error = error{
    CommandError,
    SystemResources,
    Unexpected,
    AccessDenied,
    WouldBlock,
    ConnectionResetByPeer,
    OutOfMemory,
    DiskQuota,
    FileTooBig,
    InputOutput,
    NoSpaceLeft,
    DeviceBusy,
    InvalidArgument,
    BrokenPipe,
    OperationAborted,
    NotOpenForWriting,
    LockViolation,
    Overflow,
    InvalidCharacter,
    ProcessFdQuotaExceeded,
    SystemFdQuotaExceeded,
    SymLinkLoop,
    NameTooLong,
    FileNotFound,
    NotDir,
    NoDevice,
    SharingViolation,
    PathAlreadyExists,
    PipeBusy,
    InvalidUtf8,
    InvalidWtf8,
    BadPathName,
    NetworkNotFound,
    AntivirusInterference,
    IsDir,
    FileLocksNotSupported,
    FileBusy,
    ConnectionTimedOut,
    NotOpenForReading,
    SocketNotConnected,
    Unseekable,
    UnexpectedToken,
    InvalidNumber,
    InvalidEnumTag,
    DuplicateField,
    UnknownField,
    MissingField,
    LengthMismatch,
    SyntaxError,
    UnexpectedEndOfInput,
    BufferUnderrun,
    ValueTooLong,
    InsufficientTokens,
    InvalidFormat,
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
    Command{ .name = "sync", .action = "", .func = sync_command.handle },

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
    chat.message_type = protocol.MsgType.MSG_TYPE_CUSTOM_TEXT;
    chat.chat_type = protocol.ChatType.CHAT_TYPE_PRIVATE;
    chat.source_uid = 2000;
    chat.message_text = .{ .Const = msg };
    chat.target_uid = 26702000; // receiver_id
    try session.send(CmdID.CmdRevcMsgScNotify, chat);
}
