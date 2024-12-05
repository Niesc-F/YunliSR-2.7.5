const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const B64Decoder = std.base64.standard.Decoder;
const ArrayList = std.ArrayList;
const commandhandler = @import("../services/command/handler.zig");

const EmojiList = [_]u32{};

pub fn onGetFriendListInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetFriendListInfoScRsp.init(allocator);
    rsp.retcode = 0;

    var assist_list = ArrayList(protocol.AssistSimpleInfo).init(allocator);
    try assist_list.appendSlice(&[_]protocol.AssistSimpleInfo{
        .{ .Pos = 0, .Level = 80, .AvatarId = 1308, .DressedSkinId = 0 },
        .{ .Pos = 1, .Level = 80, .AvatarId = 1314, .DressedSkinId = 0 },
        .{ .Pos = 2, .Level = 80, .AvatarId = 1102, .DressedSkinId = 0 },
    });

    var friend = protocol.FriendListInfo.init(allocator);
    friend.playing_state = .PLAYING_ROGUE_MAGIC;
    friend.sent_time = 0;
    //friend.friend_custom_nickname = .{ .Const = "Terminal" };
    friend.is_marked = true;
    friend.player_simple_info = protocol.SimpleInfo{
        .signature = .{ .Const = "Star Rail" },
        .nickname = .{ .Const = "Terminal" },
        .level = 70,
        .uid = 2000,
        .head_icon = 201225,
        .chat_bubble_id = 220006,
        .assist_simple_info = assist_list,
        .platform_type = protocol.PlatformType.ANDROID,
        .online_status = protocol.FriendOnlineStatus.FRIEND_ONLINE_STATUS_ONLINE,
    };
    try rsp.friend_list.append(friend);
    try session.send(CmdID.CmdGetFriendListInfoScRsp, rsp);
}
pub fn onChatEmojiList(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetChatEmojiListScRsp.init(allocator);

    rsp.retcode = 0;
    try rsp.IBAEGIFMMKD.appendSlice(&EmojiList);

    try session.send(CmdID.CmdGetChatEmojiListScRsp, rsp);
}
pub fn onPrivateChatHistory(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPrivateChatHistoryScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.sender_uid = 666; //2000 Player
    rsp.target_uid = 2000;
    try rsp.chat_list.appendSlice(&[_]protocol.Chat{
        .{
            .msg_log = .{ .Const = "example: /tp 2024201 20242 20242001" },
            .msg_type = .MSG_TYPE_CUSTOM_TEXT,
            .sent_time = 0,
            .sender_chat_uid = 2000,
        },
        .{
            .msg_log = .{ .Const = "use /tp cmd to change scene" },
            .msg_type = .MSG_TYPE_CUSTOM_TEXT,
            .sent_time = 0,
            .sender_chat_uid = 2000,
        },
        .{
            .emoji_id = 116007,
            .msg_type = .MSG_TYPE_EMOJI,
            .sent_time = 0,
            .sender_chat_uid = 2000,
        },
    });

    try session.send(CmdID.CmdGetPrivateChatHistoryScRsp, rsp);
}
pub fn onSendMsg(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    std.debug.print("Received packet: {any}\n", .{packet});
    const req = protocol.SendMsgCsReq.init(allocator);
    std.debug.print("Decoded request: {any}\n", .{req});
    std.debug.print("Raw packet body: {any}\n", .{packet.body});
    const msg_text = switch (req.message_text) {
        .Empty => "",
        .Owned => |owned| owned.str,
        .Const => |const_str| const_str,
    };
    var msg_text2: []const u8 = "";
    if (packet.body.len > 5 and packet.body[4] == 50) {
        const len = packet.body[5];
        if (packet.body.len >= 6 + len) {
            msg_text2 = packet.body[6 .. 6 + len];
        }
    }
    std.debug.print("Manually extracted message text: '{s}'\n", .{msg_text2});

    std.debug.print("Message Text 1: {any}\n", .{msg_text});

    if (msg_text2.len > 0) {
        if (std.mem.indexOf(u8, msg_text2, "/") != null) {
            std.debug.print("Message contains a '/'\n", .{});
            try commandhandler.handleCommand(session, msg_text2, allocator);
        } else {
            std.debug.print("Message does not contain a '/'\n", .{});
            try commandhandler.sendMessage(session, msg_text2, allocator);
        }
    } else {
        std.debug.print("Empty message received\n", .{});
        // Handle empty message case if needed
    }

    var rsp = protocol.SendMsgScRsp.init(allocator);
    rsp.retcode = 0;
    try session.send(CmdID.CmdSendMsgScRsp, rsp);
}
