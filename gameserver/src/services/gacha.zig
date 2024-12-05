const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn onGetGachaInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var info = ArrayList(protocol.GachaCeilingAvatar).init(allocator);
    try info.appendSlice(&[_]protocol.GachaCeilingAvatar{
        .{ .RepeatedCnt = 300, .AvatarId = 1313 },
        .{ .RepeatedCnt = 300, .AvatarId = 1225 },
        .{ .RepeatedCnt = 300, .AvatarId = 1317 },
    });

    var gacha_info = protocol.GachaInfo.init(allocator);
    gacha_info.begin_time = 1000000;
    gacha_info.end_time = 1924992000;
    gacha_info.gacha_ceiling = .{
        .avatar_list = info,
        .is_claimed = true,
        .ceiling_num = 10,
    };
    gacha_info.hjjmaaffiko = 10;
    gacha_info.einkplbkapk = 10;
    gacha_info.gacha_id = 1001;

    var rsp = protocol.GetGachaInfoScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.ejoffjnomla = 0;
    rsp.ofdkdoidahb = 0;
    rsp.ndjagnbnbgi = 0;
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
        .Num = 100,
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
    rsp.Num = req.num;
    rsp.Retcode = 0;

    try session.send(CmdID.CmdExchangeHcoinScRsp, rsp);
}
pub fn onDoGacha(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.DoGachaCsReq, allocator);

    var back_item = ArrayList(protocol.Item).init(allocator);
    try back_item.appendSlice(&[_]protocol.Item{
        .{ .ItemId = 21051, .Num = 1 },
    });

    var gacha_item_list = protocol.GachaItem.init(allocator);
    gacha_item_list.is_new = true;
    gacha_item_list.gacha_item = .{ .ItemId = 1402 };
    gacha_item_list.transfer_item_list = .{ .ItemList_ = back_item };
    gacha_item_list.token_item = .{ .ItemList_ = back_item };

    var rsp = protocol.DoGachaScRsp.init(allocator);
    rsp.gacha_num = req.gacha_num;
    rsp.gacha_id = req.gacha_id;
    rsp.ceiling_num = 30;
    rsp.gacha_random = 0;
    rsp.hjjmaaffiko = 10;
    try rsp.gacha_item_list.append(gacha_item_list);

    rsp.retcode = 0;

    try session.send(CmdID.CmdDoGachaScRsp, rsp);
}
