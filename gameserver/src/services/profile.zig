const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Data = @import("../data.zig");

const UidGenerator = @import("item.zig").UidGenerator;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const OwnedChatBubbles = Data.OwnedChatBubbles;
const OwnedPhoneThemes = Data.OwnedPhoneThemes;
const OwnedHeadIcon = Data.OwnedHeadIcon;

// can change these id here for initial display
const SupportAvatar = [_]u32{
    1401, 1225, 1402,
};
const ListAvatar = [_]u32{
    1317, 1222, 1220, 1221, 1314,
};

pub fn onGetPhoneData(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPhoneDataScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_chat_bubble = 0;
    rsp.cur_phone_theme = 0;
    try rsp.owned_chat_bubbles.appendSlice(&OwnedChatBubbles);
    try rsp.owned_phone_themes.appendSlice(&OwnedPhoneThemes);

    try session.send(CmdID.CmdGetPhoneDataScRsp, rsp);
}
pub fn onSelectPhoneTheme(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SelectPhoneThemeCsReq, allocator);

    var rsp = protocol.SelectPhoneThemeScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_phone_theme = req.theme_id;

    try session.send(CmdID.CmdSelectPhoneThemeScRsp, rsp);
}
pub fn onSelectChatBubble(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SelectChatBubbleCsReq, allocator);

    var rsp = protocol.SelectChatBubbleScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_chat_bubble = req.bubble_id;

    try session.send(CmdID.CmdSelectChatBubbleScRsp, rsp);
}
pub fn onGetPlayerBoardData(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPlayerBoardDataScRsp.init(allocator);
    var generator = UidGenerator().init();

    var display_list = protocol.DisplayAvatarVec.init(allocator);
    display_list.is_display = true;

    rsp.retcode = 0;
    rsp.signature = .{ .Const = "" };
    try rsp.display_support_avatar_vec.appendSlice(&SupportAvatar);

    for (ListAvatar) |id| {
        var A_list = protocol.DisplayAvatarData.init(allocator);
        A_list.avatar_id = id;
        A_list.pos = generator.nextId();
        try display_list.display_avatar_list.append(A_list);
    }
    rsp.display_avatar_vec = display_list;

    for (OwnedHeadIcon) |head_id| {
        const head_icon = protocol.HeadIcon{
            .id = head_id,
        };
        try rsp.unlocked_head_icon_list.append(head_icon);
    }

    try session.send(CmdID.CmdGetPlayerBoardDataScRsp, rsp);
}

pub fn onSetAssistAvatar(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SetAssistAvatarCsReq, allocator);

    var rsp = protocol.SetAssistAvatarScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.avatar_id = req.avatar_id;
    rsp.avatar_id_list = req.avatar_id_list;

    try session.send(CmdID.CmdSetAssistAvatarScRsp, rsp);
}
pub fn onSetDisplayAvatar(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SetDisplayAvatarCsReq, allocator);

    var rsp = protocol.SetDisplayAvatarScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.display_avatar_list = req.display_avatar_list;

    try session.send(CmdID.CmdSetDisplayAvatarScRsp, rsp);
}

pub fn onSetSignature(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SetSignatureCsReq, allocator);

    var rsp = protocol.SetSignatureScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.signature = req.signature;

    try session.send(CmdID.CmdSetSignatureScRsp, rsp);
}
pub fn onSetGameplayBirthday(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SetGameplayBirthdayCsReq, allocator);

    var rsp = protocol.SetGameplayBirthdayScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.birthday = req.birthday;

    try session.send(CmdID.CmdSetGameplayBirthdayScRsp, rsp);
}
pub fn onSetHeadIcon(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SetHeadIconCsReq, allocator);

    var rsp = protocol.SetHeadIconScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_head_icon_id = req.id;

    try session.send(CmdID.CmdSetHeadIconScRsp, rsp);
}
