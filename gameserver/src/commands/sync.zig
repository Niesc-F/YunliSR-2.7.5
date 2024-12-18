const UidGenerator = @import("../services/item.zig").UidGenerator;
const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");
const protocol = @import("protocol");
const Packet = @import("../Packet.zig");
const Config = @import("../services/config.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;
const Error = commandhandler.Error;

const AllAvatars = Data.AllAvatars;
const skills = Data.skills;
const skills_old = Data.skills_old;
const Rem = Data.Rem;

// function to check the list if true
fn isInList(id: u32, list: []const u32) bool {
    for (list) |item| {
        if (item == id) {
            return true;
        }
    }
    return false;
}

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, "Sync config\n", allocator);
    var sync = protocol.PlayerSyncScNotify.init(allocator);
    var generator = UidGenerator().init();

    const config = try Config.configLoader(allocator, "config.json");

    var char = protocol.AvatarSync.init(allocator);

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
        try char.avatar_list.append(avatar);
    }

    // rewrite data of avatar in config
    for (config.avatar_config.items) |avatarConf| {
        var avatar = protocol.Avatar.init(allocator);

        // basic info
        avatar.base_avatar_id = switch (avatarConf.id) {
            8001...8008 => 8008,
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

        var talentLevel: u32 = 0;
        if (isInList(avatar.base_avatar_id, &Rem)) {
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

        try char.avatar_list.append(avatar);

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
    sync.avatar_sync = char;
    try session.send(CmdID.CmdPlayerSyncScNotify, sync);
}
fn relicCoder(allocator: Allocator, id: u32, level: u32, main_affix_id: u32, stat1: u32, cnt1: u32, stat2: u32, cnt2: u32, stat3: u32, cnt3: u32, stat4: u32, cnt4: u32) !protocol.BattleRelic {
    var relic = protocol.BattleRelic{
        .id = id,
        .main_affix_id = main_affix_id,
        .level = level,
        .sub_affix_list = ArrayList(protocol.RelicAffix).init(allocator),
    };
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat1, .cnt = cnt1, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat2, .cnt = cnt2, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat3, .cnt = cnt3, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat4, .cnt = cnt4, .step = 3 });

    return relic;
}
