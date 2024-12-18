const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");
const protocol = @import("protocol");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;
const Error = commandhandler.Error;

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    const avatar = protocol.LineupAvatar{
        .id = 1402,
        .slot = 0,
        .satiety = 0,
        .hp = 10000,
        //.avatar_type = protocol.AvatarType.AVATAR_TRIAL_TYPE,
        .avatar_type = protocol.AvatarType.AVATAR_FORMAL_TYPE,
        .sp = .{ .sp_cur = 10000, .sp_max = 10000 },
    };
    var lineup = protocol.LineupInfo.init(allocator);
    lineup.mp = 5;
    lineup.max_mp = 5;
    lineup.name = .{ .Const = "YunliSR" };
    lineup.index = 0;
    try lineup.avatar_list.append(avatar);

    var scene_info = protocol.SceneInfo.init(allocator);
    scene_info.game_mode_type = 1;
    scene_info.entry_id = 2010101;
    scene_info.plane_id = 20101;
    scene_info.floor_id = 20101001;
    scene_info.leader_entity_id = 1;

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
//     NJFMKHPAMDL: bool = false,
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
