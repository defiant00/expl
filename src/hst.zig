const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const layer_0_format = @import("layer-0/format.zig");
const out = @import("out.zig");

const NodeType = enum {
    comment,
    file,
    list,
    string,
    value,
};

pub const Node = struct {
    as: union(NodeType) {
        comment: []const u8,
        file: *ArrayList(Node),
        list: *ArrayList(Node),
        string: []const u8,
        value: []const u8,
    },
    line: usize,
    column: usize,

    pub fn getType(self: Node) NodeType {
        return self.as;
    }

    pub fn Comment(val: []const u8, pos_line: usize, pos_col: usize) Node {
        return .{ .as = .{ .comment = val }, .line = pos_line, .column = pos_col };
    }

    pub fn File(allocator: Allocator) Node {
        var new_file = allocator.create(ArrayList(Node)) catch {
            out.printExit("Could not allocate memory for file.", .{}, 1);
        };
        new_file.* = ArrayList(Node).init(allocator);
        return .{ .as = .{ .file = new_file }, .line = 0, .column = 0 };
    }

    pub fn List(allocator: Allocator, pos_line: usize, pos_col: usize) Node {
        var new_list = allocator.create(ArrayList(Node)) catch {
            out.printExit("Could not allocate memory for list.", .{}, 1);
        };
        new_list.* = ArrayList(Node).init(allocator);
        return .{ .as = .{ .list = new_list }, .line = pos_line, .column = pos_col };
    }

    pub fn String(val: []const u8, pos_line: usize, pos_col: usize) Node {
        return .{ .as = .{ .string = val }, .line = pos_line, .column = pos_col };
    }

    pub fn Value(val: []const u8, pos_line: usize, pos_col: usize) Node {
        return .{ .as = .{ .value = val }, .line = pos_line, .column = pos_col };
    }

    pub fn isComment(self: Node) bool {
        return self.as == .comment;
    }

    pub fn isFile(self: Node) bool {
        return self.as == .file;
    }

    pub fn isList(self: Node) bool {
        return self.as == .list;
    }

    pub fn isString(self: Node) bool {
        return self.as == .string;
    }

    pub fn isValue(self: Node) bool {
        return self.as == .value;
    }

    pub fn asComment(self: Node) []const u8 {
        return self.as.comment;
    }

    pub fn asFile(self: Node) *ArrayList(Node) {
        return self.as.file;
    }

    pub fn asList(self: Node) *ArrayList(Node) {
        return self.as.list;
    }

    pub fn asString(self: Node) []const u8 {
        return self.as.string;
    }

    pub fn asValue(self: Node) []const u8 {
        return self.as.value;
    }

    pub fn format(self: Node, writer: anytype, layer: u8) !void {
        switch (layer) {
            0 => try layer_0_format.format(writer, self, 0),
            else => out.printExit("Invalid layer {d}", .{layer}, 1),
        }
    }
};
