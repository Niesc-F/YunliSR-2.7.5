const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.scene_service);

pub fn onGetCurSceneInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var scene_info = protocol.SceneInfo.init(allocator);
    
    scene_info.leader_entity_id = 1;
    scene_info.game_mode_type = 1;
    scene_info.plane_id = 20413;
    scene_info.floor_id = 20413001;
    scene_info.entry_id = 2041301;

    { // Character
        var scene_group = protocol.SceneGroupInfo.init(allocator);
        scene_group.state = 1;

        try scene_group.entity_list.append(.{
            .Actor = .{
                .base_avatar_id = 1402,
                .avatar_type = .AVATAR_FORMAL_TYPE,
                .uid = 666,
                .map_layer = 0,
            },
            .Motion = .{
                .pos = .{ .x = 26790, .y = -467500, .z = -281 },
                .rot = .{},
            },
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    { // Calyx prop
        var scene_group = protocol.SceneGroupInfo.init(allocator);
        scene_group.state = 1;
        scene_group.group_id = 6;

        var prop = protocol.ScenePropInfo.init(allocator);
        prop.prop_id = 901;
        prop.prop_state = 1;

        try scene_group.entity_list.append(.{
            .GroupId = 231,
            .InstId = 300001,
            .EntityId = 1337,
            .Prop = prop,
            .Motion = .{
                .pos = .{ .x = 26790, .y = -467500, .z = -281 },
                .rot = .{}
            },
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    try session.send(CmdID.CmdGetCurSceneInfoScRsp, protocol.GetCurSceneInfoScRsp{
        .scene = scene_info,
        .retcode = 0,
    });
}

pub fn onSceneEntityMove(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SceneEntityMoveCsReq, allocator);

    for (req.entity_motion_list.items) |entity_motion| {
        if (entity_motion.motion) |motion| {
            const colored_log = "\x1b[33;1m[POSITION] entity_id: {}, motion: {}\x1b[0m";
            log.debug(colored_log, .{ entity_motion.entity_id, motion });
        }
    }

    try session.send(CmdID.CmdSceneEntityMoveScRsp, protocol.SceneEntityMoveScRsp{
        .retcode = 0,
        .entity_motion_list = req.entity_motion_list,
        .download_data = null,
    });
}