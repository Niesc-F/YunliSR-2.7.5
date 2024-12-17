const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const Config = @import("config.zig");
const ArrayList = std.ArrayList;
const UidGenerator = @import("item.zig").UidGenerator;

// Variables so you can check current Path in any other file.
pub var m7th: bool = true;
pub var mg: bool = false;
pub var mac: u32 = 1;

const AllAvatars = [_]u32{
    1001, 1002, 1003, 1004, 1005, 1006, 1008, 1009, 1013, 1101, 1102, 1103, 1104, 1105, 1106, 1107,
    1108, 1109, 1110, 1111, 1112, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211,
    1212, 1213, 1214, 1215, 1217, 1218, 1221, 1224, 1225, 1301, 1302, 1303, 1304, 1305, 1306, 1307,
    1308, 1309, 1310, 1312, 1313, 1314, 1315, 1317, 1224, 1401, 1402, 8002
};

pub fn onGetAvatarData(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const config = try Config.configLoader(allocator, "config.json");
    var generator = UidGenerator().init();

    const req = try packet.getProto(protocol.GetAvatarDataCsReq, allocator);
    var rsp = protocol.GetAvatarDataScRsp.init(allocator);

    rsp.is_get_all = req.if_is_get_all;

    for (AllAvatars) |id| {
        var avatar = protocol.Avatar.init(allocator);
        avatar.base_avatar_id = id;
        avatar.level = 80;
        avatar.promotion = 6;
        avatar.rank = 6;
        avatar.taken_rewards = ArrayList(u32).init(allocator);
        for (1..6) |i| {
            try avatar.taken_rewards.append(@intCast(i));
        }
        try rsp.avatar_list.append(avatar);
    }

    // rewrite data of avatar in config
    for (config.avatar_config.items) |avatarConf| {
        var avatar = protocol.Avatar.init(allocator);

        // basic info
        avatar.base_avatar_id = switch (avatarConf.id) {
            8001...8008 => 8001,
            1224 => 1001,
            else => avatarConf.id,
        };
        avatar.level = avatarConf.level;
        avatar.promotion = avatarConf.promotion;
        avatar.rank = avatarConf.rank;

        // equipments
        avatar.equipment_unique_id = generator.nextId();

        // relics
        avatar.equip_relic_list = ArrayList(protocol.EquipRelic).init(allocator);
        for (0..6) |i| {
            try avatar.equip_relic_list.append(.{
                .relic_unique_id = generator.nextId(), // uid
                .slot = @intCast(i), // slot
            });
            std.debug.print("equiping {}:{}:{}\n", .{ avatarConf.id, avatar.equip_relic_list.items[i].relic_unique_id, i });
        }

        // show max trace
        const skills = [_]u32{ 1, 2, 3, 4, 7, 101, 102, 103, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 301, 302 }; //memory path
        const skills_old = [_]u32{ 1, 2, 3, 4, 7, 101, 102, 103, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210 };

        var talentLevel: u32 = 0;
        if (avatar.base_avatar_id == 8007 or avatar.base_avatar_id == 8008 or avatar.base_avatar_id == 1402) {
            for (skills) |elem| {
                if (elem == 1 or elem == 301 or elem == 302) {
                    talentLevel = 6;
                } else if (elem <= 4) {
                    talentLevel = 10;
                } else {
                    talentLevel = 1;
                }
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.base_avatar_id * 1000 + elem, .level = talentLevel };
                try avatar.skilltree_list.append(talent);
            }
        } else {
            for (skills_old) |elem_old| {
                if (elem_old == 1) {
                    talentLevel = 6;
                } else if (elem_old <= 4) {
                    talentLevel = 10;
                } else {
                    talentLevel = 1;
                }
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.base_avatar_id * 1000 + elem_old, .level = talentLevel };
                try avatar.skilltree_list.append(talent);
            }
        }

        try rsp.avatar_list.append(avatar);

        // set path
        const avatarType: protocol.MultiPathAvatarType = @enumFromInt(avatarConf.id);

        if (@intFromEnum(avatarType) > 1) {
            std.debug.print("setting avatar type: {}\n", .{avatarConf.id});
            try session.send(CmdID.CmdSetAvatarPathScRsp, protocol.SetAvatarPathScRsp{
                .retcode = 0,
                .avatar_id = avatarType,
            });
        }
    }

    try session.send(CmdID.CmdGetAvatarDataScRsp, rsp);
}

// OLD CODE, CAN BE DELETED
// pub fn onGetMultiPathAvatarInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
//     var rsp = protocol.GetMultiPathAvatarInfoScRsp.init(allocator);
//     try rsp.cur_multi_path_avatar_type_map.append(.{ .key = 1001, .value = .Mar_7thRogueType });
//     try rsp.cur_multi_path_avatar_type_map.append(.{ .key = 8007, .value = .BoyMemoryType });
//
//     try session.send(CmdID.CmdGetMultiPathAvatarInfoScRsp, rsp);
// }

pub fn onGetMultiPathAvatarInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetMultiPathAvatarInfoScRsp.init(allocator);

    // Unlocked MultiPathAvatar
    var multi0 = protocol.MultiPathAvatarInfo.init(allocator);
    multi0.avatar_id = protocol.MultiPathAvatarType.GirlWarriorType;

    var multi1 = protocol.MultiPathAvatarInfo.init(allocator);
    multi1.avatar_id = protocol.MultiPathAvatarType.GirlKnightType;

    var multi2 = protocol.MultiPathAvatarInfo.init(allocator);
    multi2.avatar_id = protocol.MultiPathAvatarType.GirlShamanType;

    var multi3 = protocol.MultiPathAvatarInfo.init(allocator);
    multi3.avatar_id = protocol.MultiPathAvatarType.GirlMemoryType;

    var multi4 = protocol.MultiPathAvatarInfo.init(allocator);
    multi4.avatar_id = protocol.MultiPathAvatarType.Mar_7thKnightType;

    var multi5 = protocol.MultiPathAvatarInfo.init(allocator);
    multi5.avatar_id = protocol.MultiPathAvatarType.Mar_7thRogueType;

    try rsp.multi_path_avatar_info_list.append(multi0);
    try rsp.multi_path_avatar_info_list.append(multi1);
    try rsp.multi_path_avatar_info_list.append(multi2);
    try rsp.multi_path_avatar_info_list.append(multi3);
    try rsp.multi_path_avatar_info_list.append(multi4);
    try rsp.multi_path_avatar_info_list.append(multi5);

    // Current MultiPathAvatar
    try rsp.cur_multi_path_avatar_type_map.append(.{ .key = 1001, .value = .Mar_7thRogueType });
    try rsp.cur_multi_path_avatar_type_map.append(.{ .key = 8008, .value = .GirlMemoryType });

    try session.send(CmdID.CmdGetMultiPathAvatarInfoScRsp, rsp);
}

pub fn onSetAvatarPath(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.SetAvatarPathScRsp.init(allocator);
    const req = try packet.getProto(protocol.SetAvatarPathCsReq, allocator);

    rsp.avatar_id = req.avatar_id;
    if (rsp.avatar_id == protocol.MultiPathAvatarType.Mar_7thKnightType) {
        m7th = false;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.Mar_7thRogueType) {
        m7th = true;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.BoyWarriorType) {
        mac = 1;
        mg = false;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.BoyKnightType) {
        mac = 2;
        mg = false;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.BoyShamanType) {
        mac = 3;
        mg = false;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.BoyMemoryType) {
        mac = 4;
        mg = false;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.GirlWarriorType) {
        mac = 1;
        mg = true;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.GirlKnightType) {
        mac = 2;
        mg = true;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.GirlShamanType) {
        mac = 3;
        mg = true;
    } else if (rsp.avatar_id == protocol.MultiPathAvatarType.GirlMemoryType) {
        mac = 4;
        mg = true;
    }

    try session.send(CmdID.CmdSetAvatarPathScRsp, rsp);
}

pub fn onSetRelicRecommend(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.RelicRecommendCsReq, allocator);
    var rsp = protocol.RelicRecommendScRsp.init(allocator);
    rsp.retcode = 0;
    rsp.avatar_id = req.avatar_id;
    try session.send(CmdID.CmdRelicRecommendScRsp, rsp);
}