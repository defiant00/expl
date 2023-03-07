const std = @import("std");
const ArrayList = std.ArrayList;
const Error = std.fs.File.WriteError;

const Node = @import("../hst.zig").Node;

pub fn format(node: Node, writer: anytype) Error!void {
    switch (node.getType()) {
        .comment => try writer.print(";{s}", .{node.asComment()}),
        .file => {
            try formatList(node.asFile(), writer);
            _ = try writer.write("\n");
        },
        .list => {
            _ = try writer.write("(");
            try formatList(node.asList(), writer);
            _ = try writer.write(")");
        },
        .string => try writer.print("\"{s}\"", .{node.asString()}),
        .value => _ = try writer.write(node.asValue()),
    }
}

fn formatList(list: *ArrayList(Node), writer: anytype) Error!void {
    if (list.items.len > 0) {
        try format(list.items[0], writer);
        var prior_line = list.items[0].line;
        for (list.items[1..]) |node| {
            if (node.line > prior_line) {
                if (node.line == prior_line + 1) {
                    _ = try writer.write("\n");
                } else {
                    _ = try writer.write("\n\n");
                }
            } else {
                _ = try writer.write(" ");
            }
            try format(node, writer);
            prior_line = node.line;
        }
    }
}
