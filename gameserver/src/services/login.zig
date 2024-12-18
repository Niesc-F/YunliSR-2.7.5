const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub fn onPlayerGetToken(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.PlayerGetTokenScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.uid = 666;

    try session.send(CmdID.CmdPlayerGetTokenScRsp, rsp);
}

pub fn onPlayerLogin(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.PlayerLoginCsReq, allocator);

    var basic_info = protocol.PlayerBasicInfo.init(allocator);
    basic_info.stamina = 300;
    basic_info.level = 70;
    basic_info.nickname = .{ .Const = "Niesc-F" };
    basic_info.world_level = 6;
    basic_info.mcoin = 99999990;
    basic_info.hcoin = 99999990; //Jade
    basic_info.scoin = 99999990; //Money

    var rsp = protocol.PlayerLoginScRsp.init(allocator);
    rsp.retcode = 0;
    rsp.login_random = req.login_random;
    rsp.stamina = 300;
    rsp.basic_info = basic_info;

    try session.send(CmdID.CmdPlayerLoginScRsp, rsp);
}
