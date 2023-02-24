const std = @import("std");
const ArrayList = std.ArrayList;

pub const Node = union {
    identifier: []const u8,
    list: *ArrayList(Node),
    number: f64,
    string: []const u8,
};
