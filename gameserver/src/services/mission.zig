const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const FinishedMainMissionIdList = Data.FinishedMainMissionIdList;
const FinishedSubMissionIdList = Data.FinishedSubMissionIdList;
const FinishedTutorialIdList = Data.FinishedTutorialIdList;
const FinishedTutorialGuideIdList = Data.FinishedTutorialGuideIdList;
const TutorialGuideIdList = Data.TutorialGuideIdList;

pub fn onGetMissionStatus(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.GetMissionStatusCsReq, allocator);
    var rsp = protocol.GetMissionStatusScRsp.init(allocator);

    rsp.retcode = 0;
    for (req.sub_mission_id_list.items) |id| {
        try rsp.SubMissionStatusList.append(protocol.Mission{ .id = id, .status = protocol.MissionStatus.MISSION_FINISH, .progress = 1 });
    }

    for (req.main_mission_id_list.items) |id| {
        try rsp.MissionEventStatusList.append(protocol.Mission{ .id = id, .status = protocol.MissionStatus.MISSION_FINISH, .progress = 1 });
    }

    try rsp.FinishedMainMissionIdList.appendSlice(&FinishedMainMissionIdList);
    try rsp.CurversionFinishedMainMissionIdList.appendSlice(&FinishedMainMissionIdList);

    try session.send(CmdID.CmdGetMissionStatusScRsp, rsp);
}

pub fn onGetTutorialGuideStatus(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetTutorialGuideScRsp.init(allocator);

    rsp.Retcode = 0;
    for (TutorialGuideIdList) |id| {
        try rsp.TutorialGuideList.append(protocol.TutorialGuide{ .Id = id, .Status = protocol.TutorialStatus.TUTORIAL_FINISH });
    }

    try session.send(CmdID.CmdGetTutorialGuideScRsp, rsp);
}
pub fn onFinishTutorialGuideStatus(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.FinishTutorialGuideScRsp.init(allocator);

    rsp.Retcode = 0;
    for (TutorialGuideIdList) |id| {
        rsp.TutorialGuide = .{ .Id = id, .Status = protocol.TutorialStatus.TUTORIAL_FINISH };
    }

    try session.send(CmdID.CmdFinishTutorialScRsp, rsp);
}

pub fn onGetTutorialStatus(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetTutorialScRsp.init(allocator);
    rsp.Retcode = 0;
    for (FinishedTutorialIdList) |id| {
        try rsp.TutorialList.append(protocol.Tutorial{ .Id = id, .Status = protocol.TutorialStatus.TUTORIAL_FINISH });
    }

    try session.send(CmdID.CmdGetTutorialScRsp, rsp);
}

// added this to auto detect new tutorial guide id
pub fn onUnlockTutorialGuide(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.UnlockTutorialGuideCsReq, allocator);
    var rsp = protocol.UnlockTutorialGuideScRsp.init(allocator);

    rsp.Retcode = 0;
    std.debug.print("Unlock Tutorial Guide Id: {}\n", .{req.group_id});

    try session.send(CmdID.CmdUnlockTutorialGuideScRsp, rsp);
}
