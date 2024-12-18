const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");
const protocol = @import("protocol");
const Config = @import("../services/config.zig");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;
const Error = commandhandler.Error;

pub fn handle(session: *Session, args: []const u8, allocator: Allocator) Error!void {
    var arg_iter = std.mem.split(u8, args, " ");
    const entry_id_str = arg_iter.next() orelse {
        try commandhandler.sendMessage(session, "Error: Missing arguments.\nUsage: /tp <entry_id> [plane_id] [floor_id]", allocator);
        return;
    };
    const entry_id = std.fmt.parseInt(u32, entry_id_str, 10) catch {
        try commandhandler.sendMessage(session, "Error: Invalid entry ID. Please provide a valid unsigned 32-bit integer.", allocator);
        return;
    };
    var plane_id: ?u32 = null;
    if (arg_iter.next()) |plane_id_str| {
        plane_id = std.fmt.parseInt(u32, plane_id_str, 10) catch {
            try commandhandler.sendMessage(session, "Error: Invalid plane ID. Please provide a valid unsigned 32-bit integer.", allocator);
            return;
        };
    }
    var floor_id: ?u32 = null;
    if (arg_iter.next()) |floor_id_str| {
        floor_id = std.fmt.parseInt(u32, floor_id_str, 10) catch {
            try commandhandler.sendMessage(session, "Error: Invalid floor ID. Please provide a valid unsigned 32-bit integer.", allocator);
            return;
        };
    }
    var tp_msg = try std.fmt.allocPrint(allocator, "Teleporting to entry ID: {d}", .{entry_id});
    if (plane_id) |pid| {
        tp_msg = try std.fmt.allocPrint(allocator, "{s}, plane ID: {d}", .{ tp_msg, pid });
    }
    if (floor_id) |fid| {
        tp_msg = try std.fmt.allocPrint(allocator, "{s}, floor ID: {d}", .{ tp_msg, fid });
    }

    try commandhandler.sendMessage(session, std.fmt.allocPrint(allocator, "Teleporting to entry ID: {d} {any} {any}\n", .{ entry_id, plane_id, floor_id }) catch "Error formatting message", allocator);

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
    scene_info.entry_id = entry_id;
    if (plane_id) |pid| scene_info.plane_id = pid;
    if (floor_id) |fid| scene_info.floor_id = fid;
    scene_info.leader_entity_id = 1;

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
                .pos = .{},
                .rot = .{},
            },
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    var tp = protocol.EnterSceneByServerScNotify.init(allocator);
    tp.reason = protocol.EnterSceneReason.ENTER_SCENE_REASON_DIMENSION_MERGE; // reason
    tp.lineup = lineup;
    tp.scene = scene_info;

    try session.send(CmdID.CmdEnterSceneByServerScNotify, tp);
}
