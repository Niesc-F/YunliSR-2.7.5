const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const commandhandler = @import("../command.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const B64Decoder = std.base64.standard.Decoder;

const EmojiList = [_]u32{};

pub fn onGetFriendListInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetFriendListInfoScRsp.init(allocator);
    rsp.retcode = 0;

    var assist_list = ArrayList(protocol.AssistSimpleInfo).init(allocator);
    try assist_list.appendSlice(&[_]protocol.AssistSimpleInfo{
        .{ .Pos = 0, .Level = 80, .AvatarId = 1225, .DressedSkinId = 0 },
        .{ .Pos = 1, .Level = 80, .AvatarId = 1313, .DressedSkinId = 0 },
        .{ .Pos = 2, .Level = 80, .AvatarId = 1212, .DressedSkinId = 0 },
    });

    var friend = protocol.FriendListInfo.init(allocator);
    friend.playing_state = .PLAYING_CHALLENGE_BOSS;
    friend.time_stamp = 0;
    friend.friend_custom_nickname = .{ .Const = "HuLiNaP" };
    friend.is_marked = true;
    friend.player_simple_info = protocol.PlayerSimpleInfo{
        .signature = .{ .Const = ":Đ expert" },
        .nickname = .{ .Const = "Năng Pờ Rào" },
        .level = 70,
        .uid = 2000,
        .head_icon = 201220,
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
    try rsp.chat_emoji_list.appendSlice(&EmojiList);

    try session.send(CmdID.CmdGetChatEmojiListScRsp, rsp);
}
pub fn onPrivateChatHistory(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPrivateChatHistoryScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.target_side = 26702000; //2000
    rsp.contact_side = 2000;
    try rsp.chat_message_list.appendSlice(&[_]protocol.ChatMessageData{
        .{
            .content = .{ .Const = "example: /tp 2024201 20242 20242001" },
            .message_type = .MSG_TYPE_CUSTOM_TEXT,
            .create_time = 0,
            .sender_id = 2000,
        },
        .{
            .content = .{ .Const = "use /tp cmd to change scene" },
            .message_type = .MSG_TYPE_CUSTOM_TEXT,
            .create_time = 0,
            .sender_id = 2000,
        },
        .{
            .extra_id = 119010,
            .message_type = .MSG_TYPE_EMOJI,
            .create_time = 0,
            .sender_id = 2000,
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
    if (packet.body.len > 9 and packet.body[8] == 47) { //10 both
        msg_text2 = packet.body[8 .. packet.body.len - 2];
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
