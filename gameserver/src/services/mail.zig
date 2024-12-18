const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const B64Decoder = std.base64.standard.Decoder;

pub fn onGetMail(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetMailScRsp.init(allocator);
    var item_attachment = ArrayList(protocol.Item).init(allocator);
    try item_attachment.appendSlice(&[_]protocol.Item{
        .{
            .ItemId = 1,
            .num = 99999999,
        },
        .{
            .ItemId = 102,
            .num = 99999,
        },
        .{
            .ItemId = 300101,
            .num = 1,
        },
        .{
            .ItemId = 201,
            .num = 9999,
        },
        .{
            .ItemId = 1225,
            .num = 1,
        },
        .{
            .ItemId = 11225,
            .num = 6,
        },
        .{
            .ItemId = 23035,
            .num = 5,
        },
    });

    var mail = protocol.ClientMail.init(allocator);
    mail.Sender = .{ .Const = "Himeko" };
    mail.Title = .{ .Const = "Readme" };
    mail.IsRead = false;
    mail.Id = 1;
    mail.Content = .{ .Const = "If you paid money for this PS or beta client, then you have been scammed!\n你付了錢才拿到客戶端或私服端的話表示你已經被騙了！\nThis mail is only intended to use as a disclaimer, DO NOT CLICK CLAIM BUT JUST EXIT.\n本封郵件僅作為聲明，請勿點選領取以免發生轉圈情況。" };
    mail.Time = 1723334400;
    mail.ExpireTime = 17186330890;
    mail.MailType = protocol.MailType.MAIL_TYPE_STAR;
    mail.Attachment = .{ .ItemList_ = item_attachment };

    var mail_list = ArrayList(protocol.ClientMail).init(allocator);
    try mail_list.append(mail);

    rsp.total_num = 1;
    // try rsp.mail_list.append(mail);
    // try rsp.notice_mail_list.append(mail);
    rsp.is_end = true;
    rsp.start = 0;
    rsp.retcode = 0;
    std.debug.print("Received RSP for GetMailScRsp: {any}\n", .{rsp});
    std.debug.print("Received MAIL for GetMailScRsp: {any}\n", .{mail});
    rsp.mail_list = mail_list;

    try session.send(CmdID.CmdGetMailScRsp, rsp);
}
