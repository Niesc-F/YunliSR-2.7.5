const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Config = @import("config.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const TeleportList = Data.TeleportList;

const log = std.log.scoped(.scene_service);

pub fn onGetCurSceneInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var scene_info = protocol.SceneInfo.init(allocator);
    scene_info.leader_entity_id = 0;
    scene_info.game_mode_type = 1;
    scene_info.plane_id = 10401;
    scene_info.floor_id = 10401001;
    scene_info.entry_id = 1040101;

    { // Character
        var scene_group = protocol.SceneGroupInfo.init(allocator);
        scene_group.state = 1;

        try scene_group.entity_list.append(.{
            .entityCase_ = .{
                .Actor = .{
                    .base_avatar_id = 1402,
                    .avatar_type = .AVATAR_FORMAL_TYPE,
                    .uid = 666,
                    .map_layer = 0,
                },
            },
            .Motion = .{
                .pos = .{ .x = -281, .y = 26790, .z = -467500 },
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
            .group_id = 231,
            .inst_id = 300001,
            .entity_id = 1337,
            .entityCase_ = .{
                .Prop = prop
            },
            .Motion = .{ 
                .pos = .{ .x = -281, .y = 26790, .z = -467500 },
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
//EnterSceneCsReq
pub fn onEnterScene(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.EnterSceneCsReq, allocator);

    const config = try Config.configLoader(allocator, "config.json");

    var lineup = protocol.LineupInfo.init(allocator);
    lineup.mp = 5;
    lineup.max_mp = 5;
    lineup.name = .{ .Const = "YunliSR" };

    for (config.avatar_config.items, 0..) |avatarConf, idx| {
        var avatar = protocol.LineupAvatar.init(allocator);
        switch (avatarConf.id) {
            8001...8008 => {
                avatar.id = 8008; // remap MC for initial lineup
            },
            else => {
                avatar.id = avatarConf.id;
            },
        }
        avatar.slot = @intCast(idx);
        avatar.satiety = 0;
        avatar.hp = avatarConf.hp * 100;
        avatar.sp = .{ .sp_cur = avatarConf.sp * 100, .sp_max = 10000 };
        avatar.avatar_type = protocol.AvatarType.AVATAR_FORMAL_TYPE;
        try lineup.avatar_list.append(avatar);
    }

    var scene_info = protocol.SceneInfo.init(allocator);
    scene_info.game_mode_type = 1;
    scene_info.content_id = req.content_id;
    scene_info.entry_id = req.entry_id;
    if (req.entry_id > 100000000) {
        scene_info.plane_id = req.entry_id / 10000;
    } else {
        scene_info.plane_id = req.entry_id / 100;
    }
    scene_info.game_story_line_id = req.game_story_line_id;
    if (req.entry_id == 100000104) {
        scene_info.floor_id = 10000000;
    } else {
        scene_info.floor_id = scene_info.plane_id * 1000 + 1;
    }
    std.log.info("EntryID = {any}", .{scene_info.entry_id});
    std.log.info("PlaneID = {any}", .{scene_info.plane_id});
    std.log.info("FloorID = {any}", .{scene_info.floor_id});


    scene_info.leader_entity_id = 1;

    var tp = protocol.EnterSceneByServerScNotify.init(allocator);
    tp.reason = protocol.EnterSceneReason.ENTER_SCENE_REASON_NONE;
    tp.lineup = lineup;
    tp.scene = scene_info;

    try session.send(CmdID.CmdEnterSceneByServerScNotify, tp);

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
pub fn onGetUnlockTeleport(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetUnlockTeleportScRsp.init(allocator);

    try rsp.unlock_teleport_list.appendSlice(&TeleportList);
    rsp.retcode = 0;

    try session.send(CmdID.CmdGetUnlockTeleportScRsp, rsp);
}
pub fn onEnterSection(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.EnterSectionCsReq, allocator);
    var rsp = protocol.EnterSectionScRsp.init(allocator);

    rsp.retcode = 0;
    std.debug.print("Unlock Tutorial Guide Id: {}\n", .{req.section_id});

    try session.send(CmdID.CmdEnterSectionScRsp, rsp);
}
