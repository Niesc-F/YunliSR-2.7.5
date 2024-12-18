const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const OwnedPet = [_]u32{251001};

pub fn onGetPetData(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPetDataScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_pet_id = 1001;
    try rsp.unlocked_pet_id_list.appendSlice(&OwnedPet);

    try session.send(CmdID.CmdGetPetDataScRsp, rsp);
}
pub fn onRecallPet(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.RecallPetScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.cur_pet_id = 1001;
    try session.send(CmdID.CmdRecallPetScRsp, rsp);
}
pub fn onSummonPet(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.CurPetChangedScNotify.init(allocator);

    rsp.cur_pet_id = 1001;
    try session.send(CmdID.CmdCurPetChangedScNotify, rsp);
    try session.send(CmdID.CmdSummonPetScRsp, protocol.SummonPetScRsp{
        .retcode = 0,
        .cur_pet_id = 1001,
    });
}
