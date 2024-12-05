const std = @import("std");
const httpz = @import("httpz");
const protocol = @import("protocol");
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

    proto.retcode = 0;
    proto.port = 23301;
    proto.ip = .{ .Const = "127.0.0.1" };
    //proto.ifix_version = .{ .Const = "0" };
    //proto.lua_version = .{ .Const = "8731095" };

    proto.lua_url = .{ .Const = "https://autopatchcn.bhsr.com/lua/BetaLive/output_8731095_98d00821dbd1" };
    proto.asset_bundle_url = .{ .Const = "https://autopatchcn.bhsr.com/asb/BetaLive/output_8741764_7b9b37c5472a" };
    proto.ex_resource_url = .{ .Const = "https://autopatchcn.bhsr.com/design_data/BetaLive/output_8750523_aedf8b219ff5" };
    
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
