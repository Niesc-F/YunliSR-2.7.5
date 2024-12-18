const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const log = std.log.scoped(.scene_service);

pub fn onGetCurSceneInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var scene_info = protocol.SceneInfo.init(allocator);
    scene_info.game_mode_type = 2;
    scene_info.plane_id = 20411;
    scene_info.floor_id = 20411001;
    scene_info.entry_id = 2041101;

    { // Character
        var scene_group = protocol.SceneGroupInfo.init(allocator);
        scene_group.state = 1;

        try scene_group.entity_list.append(.{
            .entityCase_ = .{
                .Actor = .{
                    .base_avatar_id = 8008,
                    .avatar_type = .AVATAR_FORMAL_TYPE,
                    .uid = 1337,
                    .map_layer = 0,
                },
            },
            .Motion = .{
                .pos = .{ .x = -399106, .y = -117696, .z = -538487 },
                .rot = .{},
            },
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    { // Calyx prop
        var scene_group = protocol.SceneGroupInfo.init(allocator);
        scene_group.state = 1;
        scene_group.group_id = 231;

        var prop = protocol.ScenePropInfo.init(allocator);
        //calyx prop 808 = yellow 801 = red 113 = boss 702 = stagnant shadow
        prop.prop_id = 801;
        prop.prop_state = 1;

        try scene_group.entity_list.append(.{
            .group_id = 243,
            .inst_id = 300001,
            .entity_id = 1337,
            //.prop = prop,
            .entityCase_ = .{ .Prop = prop },
            .Motion = .{ .pos = .{ .x = -396761, .y = -117738, .z = -540523 }, .rot = .{ .x = 0, .y = 0, .z = 0 } },
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
            log.debug("[POSITION] entity_id: {}, motion: {}", .{ entity_motion.entity_id, motion });
        }
    }

    try session.send(CmdID.CmdSceneEntityMoveScRsp, protocol.SceneEntityMoveScRsp{
        .retcode = 0,
        .entity_motion_list = req.entity_motion_list,
        .download_data = null,
    });
}
//EnterSceneCsReq
pub fn onEnterScene(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.EnterSceneCsReq, allocator);

    std.debug.print("Cntent ID: {}\n", .{req.content_id});

    try session.send(CmdID.CmdEnterSceneScRsp, protocol.EnterSceneScRsp{
        .retcode = 0,
        .game_story_line_id = req.game_story_line_id,
        .is_close_map = req.is_close_map,
        .content_id = req.content_id,
        .is_over_map = true,
    });
}

//GetSceneMapInfoCsReq TODO
pub fn onGetSceneMapInfo(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.GetSceneMapInfoCsReq, allocator);
    var scene_map_info = ArrayList(protocol.SceneMapInfo).init(allocator);
    var map_info = protocol.SceneMapInfo.init(allocator);

    var chest_list = ArrayList(protocol.ChestInfo).init(allocator);

    try chest_list.appendSlice(&[_]protocol.ChestInfo{
        .{ .chest_type = protocol.ChestType.MAP_INFO_CHEST_TYPE_NORMAL },
        .{ .chest_type = protocol.ChestType.MAP_INFO_CHEST_TYPE_CHALLENGE },
        .{ .chest_type = protocol.ChestType.MAP_INFO_CHEST_TYPE_PUZZLE },
    });

    for (req.entry_id_list.items) |entry_id| {
        map_info.entry_id = entry_id;
        map_info.retcode = 0;
        map_info.chest_list = chest_list;

        for (0..100) |i| {
            try map_info.lighten_section_list.append(@intCast(i));
        }
    }
    try scene_map_info.append(map_info);

    try session.send(CmdID.CmdGetSceneMapInfoScRsp, protocol.GetSceneMapInfoScRsp{
        .retcode = 0,
        .scene_map_info = scene_map_info,
    });
}
