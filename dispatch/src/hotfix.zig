const std = @import("std");
const Allocator = std.mem.Allocator;

const HotfixConfig = struct {
    assetBundleUrl: []const u8,
    exResourceUrl: []const u8,
    luaUrl: []const u8,
};

pub fn hotfixParser(allocator: Allocator, filename: []const u8) !HotfixConfig {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(buffer);

    var json_tree = try std.json.parseFromSlice(std.json.Value, allocator, buffer, .{});
    defer json_tree.deinit();

    const root = json_tree.value;
    const config: HotfixConfig = try parseURL(root);

    return config;
}

fn parseURL(root: std.json.Value) !HotfixConfig {
    var assetBundleUrl: ?[]const u8 = null;
    var exResourceUrl: ?[]const u8 = null;
    var luaUrl: ?[]const u8 = null;

    if (root.object.get("assetBundleUrl")) |value| {
        switch (value) {
            .string => assetBundleUrl = value.string,
            else => return error.InvalidJsonType,
        }
    } else {
        return error.MissingField;
    }

    if (root.object.get("exResourceUrl")) |value| {
        switch (value) {
            .string => exResourceUrl = value.string,
            else => return error.InvalidJsonType,
        }
    } else {
        return error.MissingField;
    }

    if (root.object.get("luaUrl")) |value| {
        switch (value) {
            .string => luaUrl = value.string,
            else => return error.InvalidJsonType,
        }
    } else {
        return error.MissingField;
    }

    return HotfixConfig{
        .assetBundleUrl = assetBundleUrl.?,
        .exResourceUrl = exResourceUrl.?,
        .luaUrl = luaUrl.?,
    };
}
