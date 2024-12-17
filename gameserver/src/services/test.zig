const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const TalkEventList = [_]u32{};

//ArrayList(Proto)
pub fn onGetFirstTalkByPerformanceNpc(session: *Session, _: *const Packet, allocator: Allocator) !void {

    var npc_talk_info = protocol.NpcTalkInfo.init(allocator);
    npc_talk_info.is_meet = true;
    npc_talk_info.npc_talk_id = 0;

    var rsp = protocol.GetFirstTalkByPerformanceNpcScRsp.init(allocator);
    rsp.retcode = 0;
    try rsp.npc_meet_status_list.append(npc_talk_info);

    try session.send(CmdID.CmdGetFirstTalkByPerformanceNpcScRsp, rsp);
}

//ArrayList(u32)
pub fn onGetNpcTakenReward(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetNpcTakenRewardScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.npc_id = 0;
    try rsp.talk_event_list.appendSlice(&TalkEventList);

    try session.send(CmdID.CmdGetNpcTakenRewardScRsp, rsp);
}