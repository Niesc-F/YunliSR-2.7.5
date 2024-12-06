const std = @import("std");
const httpz = @import("httpz");
const protocol = @import("protocol");
const HotfixConfig = @import("hotfix.zig");
const Base64Encoder = @import("std").base64.standard.Encoder;

pub fn onQueryDispatch(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("onQueryDispatch", .{});

    var proto = protocol.Dispatch.init(res.arena);

    proto.retcode = 0;
    try proto.region_list.append(.{
        .name = .{ .Const = "YunliSR-2.6.5" },
        .display_name = .{ .Const = "YunliSR-2.6.5" },
        .env_type = .{ .Const = "2" },
        .title = .{ .Const = "YunliSR-2.6.5" },
        .dispatch_url = .{ .Const = "http://127.0.0.1:21000/query_gateway" },
    });

    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}

pub fn onQueryGateway(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("onQueryGateway", .{});

    var proto = protocol.Gateserver.init(res.arena);
    const hotfix =  try HotfixConfig.hotfixParser(res.arena, "hotfix.json");

    std.log.info("Get assetBundleUrl >> {s}", .{hotfix.assetBundleUrl});
    std.log.info("Get exResourceUrl >> {s}", .{hotfix.exResourceUrl});
    std.log.info("Get luaUrl >> {s}", .{hotfix.luaUrl});

    proto.retcode = 0;
    proto.port = 23301;
    proto.ip = .{ .Const = "127.0.0.1" };

    proto.lua_url = .{ .Const = hotfix.luaUrl };
    proto.asset_bundle_url = .{ .Const = hotfix.assetBundleUrl };
    proto.ex_resource_url = .{ .Const = hotfix.exResourceUrl };
    
    proto.bonnpkimhlc = true;
    proto.emmbijjilkb = true;
    proto.lpmkfiiibcj = true;
    proto.lofiibcljgg = true;
    proto.pceiilkjlin = true;
    proto.cngbmfihcea = true;
    proto.kcbjfbmocml = true;
    proto.hpjlchiglng = true;
    proto.hmaohigcmoc = true;
    proto.phmamhidomc = true;
    proto.iefemijolbb = true;
    proto.pnmobljecnk = true;
    proto.clbpflldkfn = true;
    proto.mhpnibpfnhf = true;
    proto.pdjlpphmden = true;


    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}
