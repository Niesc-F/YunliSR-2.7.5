const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Data = @import("../data.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const EventList = Data.EventList;

pub fn onGetActivity(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetActivityScheduleConfigScRsp.init(allocator);

    for (EventList) |id| {
        var activ_list = protocol.ActivityScheduleData.init(allocator);
        activ_list.begin_time = 0;
        activ_list.end_time = 1924992000;
        if (id >= 100000) {
            activ_list.activity_id = ((id % 100000) * 100) + 1;
        } else {
            activ_list.activity_id = id * 100 + 1;
        }
        activ_list.panel_id = id;
        try rsp.schedule_data.append(activ_list);
    }
    rsp.retcode = 0;

    try session.send(CmdID.CmdGetActivityScheduleConfigScRsp, rsp);
}
