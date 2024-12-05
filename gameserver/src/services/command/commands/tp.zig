const commandhandler = @import("../handler.zig");
const std = @import("std");
const Session = @import("../../../Session.zig");
const Allocator = std.mem.Allocator;
const Error = commandhandler.Error;
const protocol = @import("protocol");
const CmdID = protocol.CmdID;

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
    const avatar = protocol.LineupAvatar{
        .id = 1220,
        .slot_type = 0,
        .satiety = 0,
        .hp = 10000,
        //.avatar_type = protocol.AvatarType.AVATAR_TRIAL_TYPE,
        .avatar_type = protocol.AvatarType.AVATAR_FORMAL_TYPE,
        .sp_bar = .{ .cur_sp = 10000, .max_sp = 10000 },
    };
    var lineup = protocol.LineupInfo.init(allocator);
    lineup.name = .{ .Const = "Teleported" };
    lineup.index = 0;
    lineup.is_virtual = true;
    try lineup.avatar_list.append(avatar);

    var scene_info = protocol.SceneInfo.init(allocator);
    scene_info.game_mode_type = 1;
    scene_info.entry_id = entry_id;
    if (plane_id) |pid| scene_info.plane_id = pid;
    if (floor_id) |fid| scene_info.floor_id = fid;
    scene_info.KBBLJPLPLBC = 1;

    var tp = protocol.EnterSceneByServerScNotify.init(allocator);
    tp.reason = protocol.EnterSceneReason.ENTER_SCENE_REASON_DIMENSION_MERGE; // reason
    tp.lineup = lineup;
    tp.scene = scene_info;

    try session.send(CmdID.CmdEnterSceneByServerScNotify, tp);
}

// Parlor Car 2021302,1000001,2021401
// Crane 202210103 Broken
// Penacony grand theater 2033201, 3012301
// Path Space 20100001
// Boss Areas start 3000101
// Default 201010102
// Master Control Zone 1000101
// Administrative District 1010101
// Golden Hour 1030101
// Dreamflux Reef 1030401
// Danheng mission 2021301

// pub const SceneInfo = struct {
//     JDEFJHMIGII: u32 = 0,
//     plane_id: u32 = 0,
//     MDKMDBIBNAE: u32 = 0,
//     game_mode_type: u32 = 0,
//     entity_list: ArrayList(SceneEntityInfo), //
//     entry_id: u32 = 0,
//     NFCOJIGIFBB: u32 = 0,
//     leader_entity_id: u32 = 0,
//     interact_id: u32 = 0,
//     JMCAMDJOLNJ: ArrayList(DPLJIEJBAFM),
//     ADBAKKBJAGB: ArrayList(u32), //
//     env_buff_list: ArrayList(BuffInfo),
//     AHEHCCKJAMG: ArrayList(NLLCOJPPKLJ),
//     lighten_section_list: ArrayList(u32), //
//     floor_id: u32 = 0,
//     CBPHPHOPOFK: ArrayList(CBPHPHOPOFKEntry), //
//     IJNPCCNDCGI: u32 = 0,
//     scene_group_list: ArrayList(SceneGroupInfo), //
//     CNJCEGMEAAP: ?JIPKADFNHNH = null,
//     entity_buff_list: ArrayList(EntityBuffInfo), //
//     KDKOOGFCCBB: ArrayList(KDKOOGFCCBBEntry), //
//     pub const CBPHPHOPOFKEntry = struct {
//         key: ManagedString = .Empty,
//         value: i32 = 0,
//
//         pub const _desc_table = .{
//             .key = fd(1, .String),
//             .value = fd(2, .{ .Varint = .Simple }),
//         };
// }

// pub const LineupInfo = struct {
//     is_virtual: bool = false,
//     avatar_list: ArrayList(LineupAvatar),
//     LOFEKGFCMLC: ArrayList(u32), //
//     IJNPCCNDCGI: u32 = 0,
//     index: u32 = 0,
//     CNFILHBJEKE: bool = false,
//     HCOEMHCFOMN: u32 = 0,
//     name: ManagedString = .Empty,
//     extra_lineup_type: ExtraLineupType = @enumFromInt(0),
//     plane_id: u32 = 0,
//     NLKMJKFHEBM: ArrayList(u32), //fd
//     KCLNAIMOFDL: u32 = 0,
//     DFKPGCKCHAH: ArrayList(u32), //
//     OPPIENKNMFB: u32 = 0, //
// };

// pub const EnterSceneByServerScNotify = struct {
//     lineup: ?LineupInfo = null,
//     MGDNAINPAHE: EnterSceneReason = @enumFromInt(0),
//     scene: ?SceneInfo = null,
//
//     pub const _desc_table = .{
//         .lineup = fd(14, .{ .SubMessage = {} }),
//         .MGDNAINPAHE = fd(11, .{ .Varint = .Simple }),
//         .scene = fd(7, .{ .SubMessage = {} }),
//     };
//
//     pub usingnamespace protobuf.MessageMixins(@This());
// };
