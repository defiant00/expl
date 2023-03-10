const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const console = @import("console.zig");
const layer_0_format = @import("layer-0/format.zig");

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
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,

    pub fn getType(self: Node) NodeType {
        return self.as;
    }

    pub fn Comment(val: []const u8, line: usize, col: usize) Node {
        return .{ .as = .{ .comment = val }, .start_line = line, .start_column = col, .end_line = line, .end_column = col + val.len };
    }

    pub fn File(allocator: Allocator) Node {
        var new_file = allocator.create(ArrayList(Node)) catch {
            console.printExit("Could not allocate memory for file.", .{}, 1);
        };
        new_file.* = ArrayList(Node).init(allocator);
        return .{ .as = .{ .file = new_file }, .start_line = 0, .start_column = 0, .end_line = 0, .end_column = 0 };
    }

    pub fn List(allocator: Allocator, line: usize, col: usize) Node {
        var new_list = allocator.create(ArrayList(Node)) catch {
            console.printExit("Could not allocate memory for list.", .{}, 1);
        };
        new_list.* = ArrayList(Node).init(allocator);
        return .{ .as = .{ .list = new_list }, .start_line = line, .start_column = col, .end_line = line, .end_column = col };
    }

    pub fn String(val: []const u8, s_line: usize, s_col: usize, e_line: usize, e_col: usize) Node {
        return .{ .as = .{ .string = val }, .start_line = s_line, .start_column = s_col, .end_line = e_line, .end_column = e_col };
    }

    pub fn Value(val: []const u8, line: usize, col: usize) Node {
        return .{ .as = .{ .value = val }, .start_line = line, .start_column = col, .end_line = line, .end_column = col + val.len };
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
            else => console.printExit("Invalid layer {d}", .{layer}, 1),
        }
    }
};
