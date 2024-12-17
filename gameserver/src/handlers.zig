const std = @import("std");
const protocol = @import("protocol");
const Session = @import("Session.zig");
const Packet = @import("Packet.zig");
const avatar = @import("services/avatar.zig");
//const chat = @import("services/chat.zig");
const gacha = @import("services/gacha.zig");
const item = @import("services/item.zig");
const battle = @import("services/battle.zig");
const login = @import("services/login.zig");
const lineup = @import("services/lineup.zig");
//const mail = @import("services/mail.zig");
const misc = @import("services/misc.zig");
const mission = @import("services/mission.zig");
//const pet = @import("services/pet.zig");
//const profile = @import("services/profile.zig");
const scene = @import("services/scene.zig");
//const npc = @import("services/test.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const CmdID = protocol.CmdID;

const log = std.log.scoped(.handlers);

const Action = *const fn (*Session, *const Packet, Allocator) anyerror!void;
const HandlerList = [_]struct { CmdID, Action }{
	.{ CmdID.CmdPlayerGetTokenCsReq, login.onPlayerGetToken },
	.{ CmdID.CmdPlayerLoginCsReq, login.onPlayerLogin },
	.{ CmdID.CmdPlayerHeartBeatCsReq, misc.onPlayerHeartBeat },
	.{ CmdID.CmdGetAvatarDataCsReq, avatar.onGetAvatarData },
	.{ CmdID.CmdGetMultiPathAvatarInfoCsReq, avatar.onGetMultiPathAvatarInfo },
	.{ CmdID.CmdGetBagCsReq, item.onGetBag },
	.{ CmdID.CmdUseItemCsReq, item.onUseItem },
	.{ CmdID.CmdChangeLineupLeaderCsReq, lineup.onChangeLineupLeader },
	.{ CmdID.CmdReplaceLineupCsReq, lineup.onReplaceLineup },
	.{ CmdID.CmdGetCurLineupDataCsReq, lineup.onGetCurLineupData },
	.{ CmdID.CmdGetCurSceneInfoCsReq, scene.onGetCurSceneInfo },
	.{ CmdID.CmdSceneEntityMoveCsReq, scene.onSceneEntityMove },
	.{ CmdID.CmdStartCocoonStageCsReq, battle.onStartCocoonStage },
	.{ CmdID.CmdPVEBattleResultCsReq, battle.onPVEBattleResult },
    .{ CmdID.CmdRelicRecommendCsReq, avatar.onSetRelicRecommend },
	//friendlist
	//.{ CmdID.CmdGetFriendListInfoCsReq, chat.onGetFriendListInfo },
	//gacha
	.{ CmdID.CmdGetGachaInfoCsReq, gacha.onGetGachaInfo },
	.{ CmdID.CmdBuyGoodsCsReq, gacha.onBuyGoods },
	.{ CmdID.CmdGetShopListCsReq, gacha.onGetShopList },
	.{ CmdID.CmdExchangeHcoinCsReq, gacha.onExchangeHcoin },
	.{ CmdID.CmdDoGachaCsReq, gacha.onDoGacha },
	//mail
	//.{ CmdID.CmdGetMailCsReq, mail.onGetMail },
	//pet
	//.{ CmdID.CmdGetPetDataCsReq, pet.onGetPetData },
	//.{ CmdID.CmdRecallPetCsReq, pet.onRecallPet },
	//.{ CmdID.CmdSummonPetCsReq, pet.onSummonPet },
	//profile
	//.{ CmdID.CmdGetPhoneDataCsReq, profile.onGetPhoneData },
	//.{ CmdID.CmdSelectPhoneThemeCsReq, profile.onSelectPhoneTheme },
	//.{ CmdID.CmdSelectChatBubbleCsReq, profile.onSelectChatBubble },
	//.{ CmdID.CmdGetPlayerBoardDataCsReq, profile.onGetPlayerBoardData },
	//.{ CmdID.CmdSetDisplayAvatarCsReq, profile.onGetPlayerBoardData },
	//.{ CmdID.CmdSetAssistAvatarCsReq, profile.onGetPlayerBoardData },
	//.{ CmdID.CmdSetSignatureCsReq, profile.onSetSignature },
	//.{ CmdID.CmdSetGameplayBirthdayCsReq, profile.onSetGameplayBirthday },
	//.{ CmdID.CmdSetHeadIconCsReq, profile.onSetHeadIcon },
	//mission
	.{ CmdID.CmdGetMissionStatusCsReq, mission.onGetMissionStatus },
	//.{ CmdID.CmdGetTutorialGuideCsReq, mission.onGetTutorialGuideStatus },
	//.{ CmdID.CmdGetTutorialCsReq, mission.onGetTutorialStatus },
    //npc
    //.{ CmdID.CmdGetFirstTalkByPerformanceNpcCsReq, npc.onGetFirstTalkByPerformanceNpc },
    //.{ CmdID.CmdGetNpcTakenRewardCsReq, npc.onGetNpcTakenReward },
};

const DummyCmdList = [_]struct { CmdID, CmdID }{
    .{ CmdID.CmdGetBasicInfoCsReq, CmdID.CmdGetBasicInfoScRsp },
    .{ CmdID.CmdGetMultiPathAvatarInfoCsReq, CmdID.CmdGetMultiPathAvatarInfoScRsp },
    .{ CmdID.CmdGetBagCsReq, CmdID.CmdGetBagScRsp },
    .{ CmdID.CmdGetMarkItemListCsReq, CmdID.CmdGetMarkItemListScRsp },
    .{ CmdID.CmdGetPlayerBoardDataCsReq, CmdID.CmdGetPlayerBoardDataScRsp },
    .{ CmdID.CmdGetCurAssistCsReq, CmdID.CmdGetCurAssistScRsp },
    .{ CmdID.CmdGetAllLineupDataCsReq, CmdID.CmdGetAllLineupDataScRsp },
    .{ CmdID.CmdGetAllServerPrefsDataCsReq, CmdID.CmdGetAllServerPrefsDataScRsp },
    .{ CmdID.CmdGetActivityScheduleConfigCsReq, CmdID.CmdGetActivityScheduleConfigScRsp },
    .{ CmdID.CmdGetMissionDataCsReq, CmdID.CmdGetMissionDataScRsp },
    .{ CmdID.CmdGetMissionEventDataCsReq, CmdID.CmdGetMissionEventDataScRsp },
    .{ CmdID.CmdGetQuestDataCsReq, CmdID.CmdGetQuestDataScRsp },
    .{ CmdID.CmdGetCurChallengeCsReq, CmdID.CmdGetCurChallengeScRsp },
    .{ CmdID.CmdGetRogueCommonDialogueDataCsReq, CmdID.CmdGetRogueCommonDialogueDataScRsp },
    .{ CmdID.CmdGetRogueInfoCsReq, CmdID.CmdGetRogueInfoScRsp },
    .{ CmdID.CmdGetRogueHandbookDataCsReq, CmdID.CmdGetRogueHandbookDataScRsp },
    .{ CmdID.CmdGetRogueEndlessActivityDataCsReq, CmdID.CmdGetRogueEndlessActivityDataScRsp },
    .{ CmdID.CmdChessRogueQueryCsReq, CmdID.CmdChessRogueQueryScRsp },
    .{ CmdID.CmdRogueTournQueryCsReq, CmdID.CmdRogueTournQueryScRsp },
    .{ CmdID.CmdSyncClientResVersionCsReq, CmdID.CmdSyncClientResVersionScRsp },
    .{ CmdID.CmdDailyFirstMeetPamCsReq, CmdID.CmdDailyFirstMeetPamScRsp },
    .{ CmdID.CmdGetBattleCollegeDataCsReq, CmdID.CmdGetBattleCollegeDataScRsp },
    .{ CmdID.CmdGetNpcStatusCsReq, CmdID.CmdGetNpcStatusScRsp },
    .{ CmdID.CmdSceneCastSkillCsReq, CmdID.CmdSceneCastSkillScRsp },
    .{ CmdID.CmdGetSecretKeyInfoCsReq, CmdID.CmdGetSecretKeyInfoScRsp },
    .{ CmdID.CmdGetHeartDialInfoCsReq, CmdID.CmdGetHeartDialInfoScRsp },
    .{ CmdID.CmdGetVideoVersionKeyCsReq, CmdID.CmdGetVideoVersionKeyScRsp },
    .{ CmdID.CmdGetCurBattleInfoCsReq, CmdID.CmdGetCurBattleInfoScRsp },
    .{ CmdID.CmdHeliobusActivityDataCsReq, CmdID.CmdHeliobusActivityDataScRsp },
    .{ CmdID.CmdGetAetherDivideInfoCsReq, CmdID.CmdGetAetherDivideInfoScRsp },
    .{ CmdID.CmdGetMapRotationDataCsReq, CmdID.CmdGetMapRotationDataScRsp },
    .{ CmdID.CmdGetRogueCollectionCsReq, CmdID.CmdGetRogueCollectionScRsp },
    .{ CmdID.CmdGetRogueExhibitionCsReq, CmdID.CmdGetRogueExhibitionScRsp },
    .{ CmdID.CmdPlayerReturnInfoQueryCsReq, CmdID.CmdPlayerReturnInfoQueryScRsp },
    .{ CmdID.CmdPlayerLoginFinishCsReq, CmdID.CmdPlayerLoginFinishScRsp },
    .{ CmdID.CmdGetLevelRewardTakenListCsReq, CmdID.CmdGetLevelRewardTakenListScRsp },
    .{ CmdID.CmdGetMainMissionCustomValueCsReq, CmdID.CmdGetMainMissionCustomValueScRsp },
    .{ CmdID.CmdGetSceneMapInfoCsReq, CmdID.CmdGetSceneMapInfoScRsp },
    .{ CmdID.CmdGetFirstTalkNpcCsReq, CmdID.CmdGetFirstTalkNpcScRsp },
    .{ CmdID.CmdGetMaterialSubmitActivityDataCsReq, CmdID.CmdGetMaterialSubmitActivityDataScRsp },
    .{ CmdID.CmdRogueTournGetCurRogueCocoonInfoCsReq, CmdID.CmdRogueTournGetCurRogueCocoonInfoScRsp },
    .{ CmdID.CmdRogueMagicQueryCsReq, CmdID.CmdRogueMagicQueryScRsp },
    .{ CmdID.CmdMusicRhythmDataCsReq, CmdID.CmdMusicRhythmDataScRsp },
	//friendlist
	.{ CmdID.CmdGetFriendListInfoCsReq, CmdID.CmdGetFriendListInfoScRsp },
    .{ CmdID.CmdGetFriendApplyListInfoCsReq, CmdID.CmdGetFriendApplyListInfoScRsp },
	.{ CmdID.CmdGetChatFriendHistoryCsReq, CmdID.CmdGetChatFriendHistoryScRsp },
    .{ CmdID.CmdGetFriendLoginInfoCsReq, CmdID.CmdGetFriendLoginInfoScRsp },
    .{ CmdID.CmdGetFriendBattleRecordDetailCsReq, CmdID.CmdGetFriendBattleRecordDetailScRsp },
    .{ CmdID.CmdGetFriendDevelopmentInfoCsReq, CmdID.CmdGetFriendDevelopmentInfoScRsp },
    .{ CmdID.CmdGetFriendRecommendListInfoCsReq, CmdID.CmdGetFriendRecommendListInfoScRsp },
	//added in 3.0
	.{ CmdID.CmdRogueArcadeGetInfoCsReq, CmdID.CmdRogueArcadeGetInfoScRsp },
    .{ CmdID.CmdGetMissionMessageInfoCsReq, CmdID.CmdGetMissionMessageInfoScRsp },
    .{ CmdID.CmdTrainPartyGetDataCsReq, CmdID.CmdTrainPartyGetDataScRsp },
    .{ CmdID.CmdSwitchHandDataCsReq, CmdID.CmdSwitchHandDataScRsp },
    .{ CmdID.CmdGetEnteredSceneCsReq, CmdID.CmdGetEnteredSceneScRsp },
    .{ CmdID.CmdQueryProductInfoCsReq, CmdID.CmdQueryProductInfoScRsp },
    .{ CmdID.CmdGetPamSkinDataCsReq, CmdID.CmdGetPamSkinDataScRsp },
    .{ CmdID.CmdGetRogueScoreRewardInfoCsReq, CmdID.CmdGetRogueScoreRewardInfoScRsp },
    .{ CmdID.CmdGetQuestRecordCsReq, CmdID.CmdGetQuestRecordScRsp },
    .{ CmdID.CmdGetDailyActiveInfoCsReq, CmdID.CmdGetDailyActiveInfoScRsp },
    .{ CmdID.CmdGetChessRogueNousStoryInfoCsReq, CmdID.CmdGetChessRogueNousStoryInfoScRsp },
    .{ CmdID.CmdCommonRogueQueryCsReq, CmdID.CmdCommonRogueQueryScRsp },
    .{ CmdID.CmdGetFightActivityDataCsReq, CmdID.CmdGetFightActivityDataScRsp },
    .{ CmdID.CmdGetStarFightDataCsReq, CmdID.CmdGetStarFightDataScRsp },
    .{ CmdID.CmdGetMultipleDropInfoCsReq, CmdID.CmdGetMultipleDropInfoScRsp },
    .{ CmdID.CmdGetPlayerReturnMultiDropInfoCsReq, CmdID.CmdGetPlayerReturnMultiDropInfoScRsp },
    .{ CmdID.CmdGetShareDataCsReq, CmdID.CmdGetShareDataScRsp },
    .{ CmdID.CmdGetTreasureDungeonActivityDataCsReq, CmdID.CmdGetTreasureDungeonActivityDataScRsp },
    .{ CmdID.CmdEvolveBuildQueryInfoCsReq, CmdID.CmdEvolveBuildQueryInfoScRsp },
    .{ CmdID.CmdGetAlleyInfoCsReq, CmdID.CmdGetAlleyInfoScRsp },
    .{ CmdID.CmdGetAetherDivideChallengeInfoCsReq, CmdID.CmdGetAetherDivideChallengeInfoScRsp },
    .{ CmdID.CmdGetStrongChallengeActivityDataCsReq, CmdID.CmdGetStrongChallengeActivityDataScRsp },
    .{ CmdID.CmdGetOfferingInfoCsReq, CmdID.CmdGetOfferingInfoScRsp },
    .{ CmdID.CmdClockParkGetInfoCsReq, CmdID.CmdClockParkGetInfoScRsp },
    .{ CmdID.CmdGetGunPlayDataCsReq, CmdID.CmdGetGunPlayDataScRsp },
    .{ CmdID.CmdGetTrackPhotoActivityDataCsReq, CmdID.CmdGetTrackPhotoActivityDataScRsp },
    .{ CmdID.CmdGetSwordTrainingDataCsReq, CmdID.CmdGetSwordTrainingDataScRsp },
    .{ CmdID.CmdGetFightFestDataCsReq, CmdID.CmdGetFightFestDataScRsp },
    .{ CmdID.CmdDifficultyAdjustmentGetDataCsReq, CmdID.CmdDifficultyAdjustmentGetDataScRsp },
    .{ CmdID.CmdGetPamSkinDataCsReq, CmdID.CmdGetPamSkinDataScRsp },
    .{ CmdID.CmdSpaceZooDataCsReq, CmdID.CmdSpaceZooDataScRsp },
    .{ CmdID.CmdGetExpeditionDataCsReq, CmdID.CmdGetExpeditionDataScRsp },
    .{ CmdID.CmdTravelBrochureGetDataCsReq, CmdID.CmdTravelBrochureGetDataScRsp },
    .{ CmdID.CmdRaidCollectionDataCsReq, CmdID.CmdRaidCollectionDataScRsp },
    .{ CmdID.CmdGetChatEmojiListCsReq, CmdID.CmdGetChatEmojiListScRsp },
    .{ CmdID.CmdGetChallengeCsReq, CmdID.CmdGetChallengeScRsp },
    .{ CmdID.CmdGetRaidInfoCsReq, CmdID.CmdGetRaidInfoScRsp },
    .{ CmdID.CmdGetLoginActivityCsReq, CmdID.CmdGetLoginActivityScRsp },
    .{ CmdID.CmdGetTrialActivityDataCsReq, CmdID.CmdGetTrialActivityDataScRsp },
    .{ CmdID.CmdGetJukeboxDataCsReq, CmdID.CmdGetJukeboxDataScRsp },
    .{ CmdID.CmdGetMuseumInfoCsReq, CmdID.CmdGetMuseumInfoScRsp },
    .{ CmdID.CmdGetTelevisionActivityDataCsReq, CmdID.CmdGetTelevisionActivityDataScRsp },
    .{ CmdID.CmdGetTrainVisitorRegisterCsReq, CmdID.CmdGetTrainVisitorRegisterScRsp },
    .{ CmdID.CmdGetBoxingClubInfoCsReq, CmdID.CmdGetBoxingClubInfoScRsp },
    .{ CmdID.CmdTextJoinQueryCsReq, CmdID.CmdTextJoinQueryScRsp },
    .{ CmdID.CmdGetLoginChatInfoCsReq, CmdID.CmdGetLoginChatInfoScRsp },
    .{ CmdID.CmdGetFeverTimeActivityDataCsReq, CmdID.CmdGetFeverTimeActivityDataScRsp },
    .{ CmdID.CmdGetSummonActivityDataCsReq, CmdID.CmdGetSummonActivityDataScRsp },
    .{ CmdID.CmdTarotBookGetDataCsReq, CmdID.CmdTarotBookGetDataScRsp },
    .{ CmdID.CmdGetMarkChestCsReq, CmdID.CmdGetMarkChestScRsp },
    .{ CmdID.CmdMatchThreeGetDataCsReq, CmdID.CmdMatchThreeGetDataScRsp },
    .{ CmdID.CmdUpdateServerPrefsDataCsReq, CmdID.CmdUpdateServerPrefsDataScRsp },
    .{ CmdID.CmdUpdateTrackMainMissionIdCsReq, CmdID.CmdUpdateTrackMainMissionIdScRsp },
    .{ CmdID.CmdGetNpcMessageGroupCsReq, CmdID.CmdGetNpcMessageGroupScRsp },
    .{ CmdID.CmdGetAllSaveRaidCsReq, CmdID.CmdGetAllSaveRaidScRsp },

};

const SuppressLogList = [_]CmdID{CmdID.CmdSceneEntityMoveCsReq};

pub fn handle(session: *Session, packet: *const Packet) !void {
    var arena = ArenaAllocator.init(session.allocator);
    defer arena.deinit();

    const cmd_id: CmdID = @enumFromInt(packet.cmd_id);

    inline for (HandlerList) |handler| {
        if (handler[0] == cmd_id) {
            try handler[1](session, packet, arena.allocator());
            if (!std.mem.containsAtLeast(CmdID, &SuppressLogList, 1, &[_]CmdID{cmd_id})) {
                log.debug("packet {} was handled", .{cmd_id});
            }
            return;
        }
    }

    inline for (DummyCmdList) |pair| {
        if (pair[0] == cmd_id) {
            try session.send_empty(pair[1]);
            return;
        }
    }

    log.warn("packet {} was ignored", .{cmd_id});
}