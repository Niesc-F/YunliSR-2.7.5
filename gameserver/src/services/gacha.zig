const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const GachaBanner = Data.GachaBanner;

pub fn onGetGachaInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var info = ArrayList(protocol.GachaCeilingAvatar).init(allocator);
    try info.appendSlice(&[_]protocol.GachaCeilingAvatar{
        .{ .RepeatedCnt = 300, .AvatarId = 1003 },
        .{ .RepeatedCnt = 300, .AvatarId = 1004 },
        .{ .RepeatedCnt = 300, .AvatarId = 1101 },
        .{ .RepeatedCnt = 300, .AvatarId = 1104 },
        .{ .RepeatedCnt = 300, .AvatarId = 1209 },
        .{ .RepeatedCnt = 300, .AvatarId = 1211 },
    });

    var gacha_info = protocol.GachaInfo.init(allocator);
    //format is in Unix timestamp
    gacha_info.begin_time = 0; //1970-01-01 00:00
    gacha_info.end_time = 2524608000; //2050-01-01 00:00
    gacha_info.gacha_ceiling = .{
        .avatar_list = info,
        .is_claimed = false,
        .ceiling_num = 10,
    };
    gacha_info.hjjmaaffiko = 1; //
    gacha_info.einkplbkapk = 3; //pull cost
    gacha_info.gacha_id = 1001; //common pool

    var rsp = protocol.GetGachaInfoScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.ejoffjnomla = 90; //
    rsp.ofdkdoidahb = 20; //already pull x pulls daily
    rsp.ndjagnbnbgi = 900; //max daily gacha
    rsp.gacha_random = 0;
    try rsp.gacha_info_list.append(gacha_info);

    try session.send(CmdID.CmdGetGachaInfoScRsp, rsp);
}
pub fn onBuyGoods(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.BuyGoodsCsReq, allocator);

    var rsp = protocol.BuyGoodsScRsp.init(allocator);
    var item = ArrayList(protocol.Item).init(allocator);

    try item.appendSlice(&[_]protocol.Item{.{
        .ItemId = 101,
        .num = 100,
    }});

    rsp.retcode = 0;
    rsp.GoodsId = req.goods_id;
    rsp.GoodsBuyTimes = req.goods_num;
    rsp.ShopId = 0;
    rsp.ReturnItemList = .{ .ItemList_ = item };

    try session.send(CmdID.CmdBuyGoodsScRsp, rsp);
}
pub fn onGetShopList(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetShopListScRsp.init(allocator);
    var shop = ArrayList(protocol.Shop).init(allocator);
    var goods = ArrayList(protocol.Goods).init(allocator);

    try shop.appendSlice(&[_]protocol.Shop{.{
        .ShopId = 1000,
        .goods_list = goods,
    }});
    try goods.appendSlice(&[_]protocol.Goods{.{
        .GoodsId = 101001,
        .ItemId = 101,
        .BuyTimes = 0,
    }});

    rsp.retcode = 0;
    rsp.ShopType = 101;
    rsp.ShopList = shop;

    try session.send(CmdID.CmdGetShopListScRsp, rsp);
}
pub fn onExchangeHcoin(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.ExchangeHcoinCsReq, allocator);

    var rsp = protocol.ExchangeHcoinScRsp.init(allocator);
    rsp.num = req.num;
    rsp.retcode = 0;

    try session.send(CmdID.CmdExchangeHcoinScRsp, rsp);
}
pub fn onDoGacha(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.DoGachaCsReq, allocator);

    var rsp = protocol.DoGachaScRsp.init(allocator);

    for (GachaBanner) |id| {
        var gacha_item_list = protocol.GachaItem.init(allocator);
        gacha_item_list.gacha_item = .{ .ItemId = id };
        gacha_item_list.is_new = false;
        var back_item = ArrayList(protocol.Item).init(allocator);
        var transfer_item = ArrayList(protocol.Item).init(allocator);

        try transfer_item.appendSlice(&[_]protocol.Item{
            .{ .ItemId = 252, .num = 20 },
            .{ .ItemId = id + 10000, .num = 1 },
        });
        try back_item.appendSlice(&[_]protocol.Item{
            .{ .ItemId = 252, .num = 20 },
        });
        gacha_item_list.transfer_item_list = .{ .ItemList_ = transfer_item };
        gacha_item_list.token_item = .{ .ItemList_ = back_item };
        try rsp.gacha_item_list.append(gacha_item_list);
    }

    rsp.gacha_num = req.gacha_num;
    rsp.gacha_id = req.gacha_id;
    rsp.gacha_random = req.gacha_random;
    rsp.ceiling_num = 10;
    rsp.hjjmaaffiko = 1; //KLKAIDFHBAG
    rsp.ofdkdoidahb = 90;
    rsp.einkplbkapk = 3; //pull cost

    rsp.retcode = 0;

    try session.send(CmdID.CmdDoGachaScRsp, rsp);
}
