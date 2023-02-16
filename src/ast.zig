const std = @import("std");
const ArrayList = std.ArrayList;

pub const Node = union {
    list: *ArrayList(Node),
    number: f64,
    string: usize,
};
