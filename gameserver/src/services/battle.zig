const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Config = @import("config.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const skills = Data.skills;
const skills_old = Data.skills_old;
const buffs_unlocked = Data.buffs_unlocked;
const Rem = Data.Rem;
const IgnoreToughness = Data.IgnoreToughness;

// function to check the list if true
fn isInList(id: u32, list: []const u32) bool {
    for (list) |item| {
        if (item == id) {
            return true;
        }
    }
    return false;
}

pub fn onStartBattle(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const config = try Config.configLoader(allocator, "config.json");

    const req = try packet.getProto(protocol.StartCocoonStageCsReq, allocator);
    const quick_req = try packet.getProto(protocol.QuickStartCocoonStageCsReq, allocator);
    const farm_req = try packet.getProto(protocol.QuickStartFarmElementCsReq, allocator);
    const coll_req = try packet.getProto(protocol.StartBattleCollegeCsReq, allocator);

    const BattleBuff = protocol.BattleBuff;

    var battle = protocol.SceneBattleInfo.init(allocator);

    // avatar handler
    for (config.avatar_config.items, 0..) |avatarConf, idx| {
        var avatar = protocol.BattleAvatar.init(allocator);
        avatar.id = avatarConf.id;
        avatar.hp = avatarConf.hp * 100;
        avatar.sp = .{ .sp_cur = avatarConf.sp * 100, .sp_max = 10000 };
        avatar.level = avatarConf.level;
        avatar.rank = avatarConf.rank;
        avatar.promotion = avatarConf.promotion;
        avatar.avatar_type = .AVATAR_FORMAL_TYPE;
        // relics
        for (avatarConf.relics.items) |relic| {
            const r = try relicCoder(allocator, relic.id, relic.level, relic.main_affix_id, relic.stat1, relic.cnt1, relic.stat2, relic.cnt2, relic.stat3, relic.cnt3, relic.stat4, relic.cnt4);
            try avatar.relic_list.append(r);
        }
        // lc
        const lc = protocol.BattleEquipment{
            .id = avatarConf.lightcone.id,
            .rank = avatarConf.lightcone.rank,
            .level = avatarConf.lightcone.level,
            .promotion = avatarConf.lightcone.promotion,
        };
        try avatar.equipment_list.append(lc);
        // max trace

        var talentLevel: u32 = 0;
        if (isInList(avatar.id, &Rem)) {
            for (skills) |elem| {
                if (elem == 1 or elem == 301 or elem == 302) {
                    talentLevel = 6;
                } else if (elem <= 4) {
                    talentLevel = 10;
                } else {
                    talentLevel = 1;
                }
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.id * 1000 + elem, .level = talentLevel };
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
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.id * 1000 + elem_old, .level = talentLevel };
                try avatar.skilltree_list.append(talent);
            }
        }
        // enable technique
        if (avatarConf.use_technique) {
            std.debug.print("{} is using tech\n", .{avatar.id});
            var targetIndexList = ArrayList(u32).init(allocator);
            try targetIndexList.append(0);
            //Add new ID when modifying for new patch

            var buffedAvatarId = avatar.id;
            if (avatar.id == 8004) {
                buffedAvatarId = 8003;
            } else if (avatar.id == 8006) {
                buffedAvatarId = 8005;
            } else if (avatar.id == 8007) {
                buffedAvatarId = 8008;
            }

            for (buffs_unlocked) |buffId| {
                const idPrefix = buffId / 100;
                if (idPrefix == buffedAvatarId) {
                    std.debug.print("Loading buffID {} for {}\n", .{ buffId, buffedAvatarId });
                    var buff = BattleBuff{
                        .id = buffId,
                        .level = 1,
                        .owner_id = @intCast(idx),
                        .wave_flag = 1,
                        .target_index_list = targetIndexList,
                        .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                    };

                    try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                    try battle.buff_list.append(buff);
                }
            }

            if (isInList(buffedAvatarId, &IgnoreToughness)) {
                std.debug.print("Loading buffID 1000119 for {}\n", .{buffedAvatarId});
                var buff_tough = BattleBuff{
                    .id = 1000119, //for is_ignore toughness
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };
                try buff_tough.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                try battle.buff_list.append(buff_tough);
            }

            if (buffedAvatarId == 1224) {
                std.debug.print("Loading hardcoded buffID 122401 for {}\n", .{buffedAvatarId});
                var buff_march = protocol.BattleBuff{
                    .id = 122401, //for hunt march 7th tech
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };

                try buff_march.dynamic_values.appendSlice(&[_]protocol.BattleBuff.DynamicValuesEntry{
                    .{ .key = .{ .Const = "#ADF_1" }, .value = 3 },
                    .{ .key = .{ .Const = "#ADF_2" }, .value = 3 },
                });
                try battle.buff_list.append(buff_march);
            }

            if (buffedAvatarId == 1310) {
                std.debug.print("Loading buffID 1000112 for {}\n", .{buffedAvatarId});
                var buff_firefly = BattleBuff{
                    .id = 1000112, //for firefly tech
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };
                try buff_firefly.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                try battle.buff_list.append(buff_firefly);
            }
        }
        try battle.pve_avatar_list.append(avatar);
    }

    // basic info
    battle.battle_id = config.battle_config.battle_id;
    battle.stage_id = config.battle_config.stage_id;
    battle.logic_random_seed = @intCast(@mod(std.time.timestamp(), 0xFFFFFFFF));
    battle.rounds_limit = config.battle_config.cycle_count; // cycle
    battle.monster_wave_length = @intCast(config.battle_config.monster_wave.items.len); // monster_wave_length

    // monster handler
    for (config.battle_config.monster_wave.items) |wave| {
        var monster_wave = protocol.SceneMonsterWave.init(allocator);
        monster_wave.wave_param = protocol.SceneMonsterWaveParam{ .level = config.battle_config.monster_level };
        for (wave.items) |mob_id| {
            try monster_wave.monster_list.append(.{ .monster_id = mob_id });
        }
        try battle.monster_wave_list.append(monster_wave);
    }

    // stage blessings
    for (config.battle_config.blessings.items) |blessing| {
        var targetIndexList = ArrayList(u32).init(allocator);
        try targetIndexList.append(0);
        var buff = protocol.BattleBuff{
            .id = blessing,
            .level = 1,
            .owner_id = 0xffffffff,
            .wave_flag = 0xffffffff,
            .target_index_list = targetIndexList,
            .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
        };
        try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
        try battle.buff_list.append(buff);
    }

    // PF/AS scoring
    const BattleTargetInfoEntry = protocol.SceneBattleInfo.BattleTargetInfoEntry;
    battle.battle_target_info = ArrayList(BattleTargetInfoEntry).init(allocator);

    // target hardcode
    var pfTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetHead.battle_target_list.append(.{ .id = 10002, .progress = 0, .total_progress = 0 });
    var pfTargetTail = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetTail.battle_target_list.append(.{ .id = 2001, .progress = 0, .total_progress = 0 });
    try pfTargetTail.battle_target_list.append(.{ .id = 2002, .progress = 0, .total_progress = 0 });
    var asTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try asTargetHead.battle_target_list.append(.{ .id = 90005, .progress = 0, .total_progress = 0 });

    switch (battle.stage_id) {
        // PF
        30019000...30019100, 30021000...30021100, 30301000...30319000 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = pfTargetHead });
            // fill blank target
            for (2..5) |i| {
                try battle.battle_target_info.append(.{ .key = @intCast(i) });
            }
            try battle.battle_target_info.append(.{ .key = 5, .value = pfTargetTail });
        },
        // AS
        420100...420200 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = asTargetHead });
        },
        else => {},
    }
    //debug info
    std.debug.print("Received RSP for CmdStartCocoonStageScRsp: {any}\n", .{battle});
    try session.send(CmdID.CmdStartCocoonStageScRsp, protocol.StartCocoonStageScRsp{
        .retcode = 0,
        .cocoon_id = req.cocoon_id,
        .prop_entity_id = req.prop_entity_id,
        .wave = req.wave,
        .battle_info = battle,
    });
    try session.send(CmdID.CmdQuickStartCocoonStageScRsp, protocol.QuickStartCocoonStageScRsp{
        .retcode = 0,
        .cocoon_id = quick_req.cocoon_id,
        .wave = quick_req.wave,
        .battle_info = battle,
    });
    try session.send(CmdID.CmdQuickStartFarmElementScRsp, protocol.QuickStartFarmElementScRsp{
        .retcode = 0,
        .world_level = farm_req.world_level,
        .kidmdefnaak = farm_req.kidmdefnaak,
        .battle_info = battle,
    });
    try session.send(CmdID.CmdStartBattleCollegeScRsp, protocol.StartBattleCollegeScRsp{
        .retcode = 0,
        .id = coll_req.id,
        .battle_info = battle,
    });
}
pub fn onSceneCastSkill(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const scsreq = try packet.getProto(protocol.SceneCastSkillCsReq, allocator);
    const config = try Config.configLoader(allocator, "config.json");

    var monster_battle_info_list = ArrayList(protocol.HitMonsterBattleInfo).init(allocator);
    try monster_battle_info_list.appendSlice(&[_]protocol.HitMonsterBattleInfo{
        .{
            .target_monster_entity_id = 0,
            .monster_battle_type = protocol.MonsterBattleType.MONSTER_BATTLE_TYPE_TRIGGER_BATTLE,
        },
    });

    const BattleBuff = protocol.BattleBuff;

    var battle = protocol.SceneBattleInfo.init(allocator);

    // avatar handler
    for (config.avatar_config.items, 0..) |avatarConf, idx| {
        var avatar = protocol.BattleAvatar.init(allocator);
        avatar.id = avatarConf.id;
        avatar.hp = avatarConf.hp * 100;
        avatar.sp = .{ .sp_cur = avatarConf.sp * 100, .sp_max = 10000 };
        avatar.level = avatarConf.level;
        avatar.rank = avatarConf.rank;
        avatar.promotion = avatarConf.promotion;
        avatar.avatar_type = .AVATAR_FORMAL_TYPE;
        // relics
        for (avatarConf.relics.items) |relic| {
            const r = try relicCoder(allocator, relic.id, relic.level, relic.main_affix_id, relic.stat1, relic.cnt1, relic.stat2, relic.cnt2, relic.stat3, relic.cnt3, relic.stat4, relic.cnt4);
            try avatar.relic_list.append(r);
        }
        // lc
        const lc = protocol.BattleEquipment{
            .id = avatarConf.lightcone.id,
            .rank = avatarConf.lightcone.rank,
            .level = avatarConf.lightcone.level,
            .promotion = avatarConf.lightcone.promotion,
        };
        try avatar.equipment_list.append(lc);
        // max trace

        var talentLevel: u32 = 0;
        if (isInList(avatar.id, &Rem)) {
            for (skills) |elem| {
                if (elem == 1 or elem == 301 or elem == 302) {
                    talentLevel = 6;
                } else if (elem <= 4) {
                    talentLevel = 10;
                } else {
                    talentLevel = 1;
                }
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.id * 1000 + elem, .level = talentLevel };
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
                const talent = protocol.AvatarSkillTree{ .point_id = avatar.id * 1000 + elem_old, .level = talentLevel };
                try avatar.skilltree_list.append(talent);
            }
        }
        // enable technique
        if (avatarConf.use_technique) {
            std.debug.print("{} is using tech\n", .{avatar.id});
            var targetIndexList = ArrayList(u32).init(allocator);
            try targetIndexList.append(0);
            //Add new ID when modifying for new patch

            var buffedAvatarId = avatar.id;
            if (avatar.id == 8004) {
                buffedAvatarId = 8003;
            } else if (avatar.id == 8006) {
                buffedAvatarId = 8005;
            } else if (avatar.id == 8007) {
                buffedAvatarId = 8008;
            }

            for (buffs_unlocked) |buffId| {
                const idPrefix = buffId / 100;
                if (idPrefix == buffedAvatarId) {
                    std.debug.print("Loading buffID {} for {}\n", .{ buffId, buffedAvatarId });
                    var buff = BattleBuff{
                        .id = buffId,
                        .level = 1,
                        .owner_id = @intCast(idx),
                        .wave_flag = 1,
                        .target_index_list = targetIndexList,
                        .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                    };

                    try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                    try battle.buff_list.append(buff);
                }
            }

            if (isInList(buffedAvatarId, &IgnoreToughness)) {
                std.debug.print("Loading buffID 1000119 for {}\n", .{buffedAvatarId});
                var buff_tough = BattleBuff{
                    .id = 1000119, //for is_ignore toughness
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };
                try buff_tough.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                try battle.buff_list.append(buff_tough);
            }

            if (buffedAvatarId == 1224) {
                std.debug.print("Loading hardcoded buffID 122401 for {}\n", .{buffedAvatarId});
                var buff_march = protocol.BattleBuff{
                    .id = 122401, //for hunt march 7th tech
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };

                try buff_march.dynamic_values.appendSlice(&[_]protocol.BattleBuff.DynamicValuesEntry{
                    .{ .key = .{ .Const = "#ADF_1" }, .value = 3 },
                    .{ .key = .{ .Const = "#ADF_2" }, .value = 3 },
                });
                try battle.buff_list.append(buff_march);
            }

            if (buffedAvatarId == 1310) {
                std.debug.print("Loading buffID 1000112 for {}\n", .{buffedAvatarId});
                var buff_firefly = BattleBuff{
                    .id = 1000112, //for firefly tech
                    .level = 1,
                    .owner_id = @intCast(idx),
                    .wave_flag = 1,
                    .target_index_list = targetIndexList,
                    .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
                };
                try buff_firefly.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
                try battle.buff_list.append(buff_firefly);
            }
        }
        try battle.pve_avatar_list.append(avatar);
    }

    // basic info
    battle.battle_id = config.battle_config.battle_id;
    battle.stage_id = config.battle_config.stage_id;
    battle.logic_random_seed = @intCast(@mod(std.time.timestamp(), 0xFFFFFFFF));
    battle.rounds_limit = config.battle_config.cycle_count; // cycle
    battle.monster_wave_length = @intCast(config.battle_config.monster_wave.items.len); // monster_wave_length

    // monster handler
    for (config.battle_config.monster_wave.items) |wave| {
        var monster_wave = protocol.SceneMonsterWave.init(allocator);
        monster_wave.wave_param = protocol.SceneMonsterWaveParam{ .level = config.battle_config.monster_level };
        for (wave.items) |mob_id| {
            try monster_wave.monster_list.append(.{ .monster_id = mob_id });
        }
        try battle.monster_wave_list.append(monster_wave);
    }

    // stage blessings
    for (config.battle_config.blessings.items) |blessing| {
        var targetIndexList = ArrayList(u32).init(allocator);
        try targetIndexList.append(0);
        var buff = protocol.BattleBuff{
            .id = blessing,
            .level = 1,
            .owner_id = 0xffffffff,
            .wave_flag = 0xffffffff,
            .target_index_list = targetIndexList,
            .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
        };
        try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
        try battle.buff_list.append(buff);
    }

    // PF/AS scoring
    const BattleTargetInfoEntry = protocol.SceneBattleInfo.BattleTargetInfoEntry;
    battle.battle_target_info = ArrayList(BattleTargetInfoEntry).init(allocator);

    // target hardcode
    var pfTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetHead.battle_target_list.append(.{ .id = 10002, .progress = 0, .total_progress = 0 });
    var pfTargetTail = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetTail.battle_target_list.append(.{ .id = 2001, .progress = 0, .total_progress = 0 });
    try pfTargetTail.battle_target_list.append(.{ .id = 2002, .progress = 0, .total_progress = 0 });
    var asTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try asTargetHead.battle_target_list.append(.{ .id = 90005, .progress = 0, .total_progress = 0 });

    switch (battle.stage_id) {
        // PF
        30019000...30019100, 30021000...30021100, 30301000...30319000 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = pfTargetHead });
            // fill blank target
            for (2..5) |i| {
                try battle.battle_target_info.append(.{ .key = @intCast(i) });
            }
            try battle.battle_target_info.append(.{ .key = 5, .value = pfTargetTail });
        },
        // AS
        420100...420200 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = asTargetHead });
        },
        else => {},
    }

    if (scsreq.hit_target_entity_id_list.items.len == 0) {
        std.debug.print("hit_target_entity_id_list B {}\n", .{scsreq.hit_target_entity_id_list.items.len});
        try session.send(CmdID.CmdSceneCastSkillScRsp, protocol.SceneCastSkillScRsp{
            .retcode = 0,
            .cast_entity_id = scsreq.cast_entity_id,
            .monster_battle_info = monster_battle_info_list,
        });
    } else {
        std.debug.print("hit_target_entity_id_list A {}\n", .{scsreq.hit_target_entity_id_list.items.len});
        try session.send(CmdID.CmdSceneCastSkillScRsp, protocol.SceneCastSkillScRsp{
            .retcode = 0,
            .cast_entity_id = scsreq.cast_entity_id,
            .monster_battle_info = monster_battle_info_list,
            .battle_info = battle,
        });
    }
}

pub fn onPVEBattleResult(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.PVEBattleResultCsReq, allocator);

    var rsp = protocol.PVEBattleResultScRsp.init(allocator);
    rsp.battle_id = req.battle_id;
    rsp.end_status = req.end_status;

    try session.send(CmdID.CmdPVEBattleResultScRsp, rsp);
}

pub fn relicCoder(allocator: Allocator, id: u32, level: u32, main_affix_id: u32, stat1: u32, cnt1: u32, stat2: u32, cnt2: u32, stat3: u32, cnt3: u32, stat4: u32, cnt4: u32) !protocol.BattleRelic {
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

pub fn onSceneCastSkillCostMp(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const scsmpreq = try packet.getProto(protocol.SceneCastSkillCostMpCsReq, allocator);
    std.debug.print("ENTITY CAST SKIL {}\n", .{scsmpreq.cast_entity_id});

    try session.send(CmdID.CmdSceneCastSkillCostMpScRsp, protocol.SceneCastSkillCostMpScRsp{
        .retcode = 0,
        .cast_entity_id = scsmpreq.cast_entity_id,
    });
}
