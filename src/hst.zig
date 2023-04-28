const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const layer_0_format = @import("layer-0/format.zig");

const NodeType = enum {
    comment,
    file,
    list,
    literal,
    string,
};

pub const Node = struct {
    as: union(NodeType) {
        comment: []const u8,
        file: *ArrayList(Node),
        list: *ArrayList(Node),
        literal: []const u8,
        string: []const u8,
    },
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,

    pub fn getType(self: Node) NodeType {
        return self.as;
    }

    pub fn deinit(self: *const Node, alloc: Allocator) void {
        switch (self.getType()) {
            .file => {
                const file = self.asFile();
                for (file.items) |node| {
                    node.deinit(alloc);
                }
                file.deinit();
                alloc.destroy(file);
            },
            .list => {
                const list = self.asList();
                for (list.items) |node| {
                    node.deinit(alloc);
                }
                list.deinit();
                alloc.destroy(list);
            },
            else => {},
        }
    }

    pub fn Comment(val: []const u8, line: usize, col: usize) Node {
        return .{
            .as = .{ .comment = val },
            .start_line = line,
            .start_column = col,
            .end_line = line,
            .end_column = col + val.len,
        };
    }

    pub fn File(alloc: Allocator) !Node {
        var new_file = try alloc.create(ArrayList(Node));
        new_file.* = ArrayList(Node).init(alloc);
        return .{
            .as = .{ .file = new_file },
            .start_line = 0,
            .start_column = 0,
            .end_line = 0,
            .end_column = 0,
        };
    }

    pub fn List(alloc: Allocator, line: usize, col: usize) !Node {
        var new_list = try alloc.create(ArrayList(Node));
        new_list.* = ArrayList(Node).init(alloc);
        return .{
            .as = .{ .list = new_list },
            .start_line = line,
            .start_column = col,
            .end_line = line,
            .end_column = col,
        };
    }

    pub fn Literal(val: []const u8, line: usize, col: usize) Node {
        return .{
            .as = .{ .literal = val },
            .start_line = line,
            .start_column = col,
            .end_line = line,
            .end_column = col + val.len,
        };
    }

    pub fn String(val: []const u8, s_line: usize, s_col: usize, e_line: usize, e_col: usize) Node {
        return .{
            .as = .{ .string = val },
            .start_line = s_line,
            .start_column = s_col,
            .end_line = e_line,
            .end_column = e_col,
        };
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

    pub fn isLiteral(self: Node) bool {
        return self.as == .literal;
    }

    pub fn isString(self: Node) bool {
        return self.as == .string;
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

    pub fn asLiteral(self: Node) []const u8 {
        return self.as.literal;
    }

    pub fn asString(self: Node) []const u8 {
        return self.as.string;
    }

    pub fn format(self: Node, writer: anytype, layer: u8) !void {
        switch (layer) {
            0 => try layer_0_format.format(writer, self, 0),
            else => {
                std.debug.print("Invalid layer {d}\n", .{layer});
                return error.InvalidLayer;
            },
        }
    }
};
