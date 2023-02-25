const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const out = @import("out.zig");

pub const Node = union {
    identifier: []const u8,
    list: *ArrayList(Node),
    number: f64,
    string: []const u8,

    pub fn Identifier(val: []const u8) Node {
        return .{ .identifier = val };
    }

    pub fn List(allocator: Allocator) Node {
        var new_list = allocator.create(ArrayList(Node)) catch {
            out.printExit("Could not allocate memory for list.", .{}, 1);
        };
        new_list.* = ArrayList(Node).init(allocator);
        return .{ .list = new_list };
    }

    pub fn Number(val: f64) Node {
        return .{ .number = val };
    }

    pub fn String(val: []const u8) Node {
        return .{ .string = val };
    }
};
