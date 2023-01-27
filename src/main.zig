const std = @import("std");

const out = @import("out.zig");
const version = @import("version.zig").version;

pub fn main() !void {
    out.init();
    defer out.flush();

    out.println("expl {d}.{d}.{d}", .{ version.major, version.minor, version.patch });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(allocator);
    defer arg_list.deinit();

    while (args.next()) |arg| try arg_list.append(arg);
}
