const std = @import("std");
const ArrayList = std.ArrayList;
const Error = std.fs.File.WriteError;

const Node = @import("../hst.zig").Node;

pub fn format(writer: anytype, node: Node, indent_level: usize) Error!void {
    switch (node.getType()) {
        .comment => try writer.print(";{s}", .{node.asComment()}),
        .file => {
            try formatList(writer, node.asFile(), node.line, indent_level);
            _ = try writer.write("\n");
        },
        .list => {
            _ = try writer.write("(");
            try formatList(writer, node.asList(), node.line, indent_level + 1);
            _ = try writer.write(")");
        },
        .string => try writer.print("\"{s}\"", .{node.asString()}),
        .value => _ = try writer.write(node.asValue()),
    }
}

fn formatList(writer: anytype, list: *ArrayList(Node), start_line: usize, indent_level: usize) Error!void {
    var prior_line = start_line;

    if (list.items.len > 0) {
        if (list.items[0].line > prior_line) {
            if (list.items[0].line == prior_line + 1) {
                _ = try writer.write("\n");
            } else {
                _ = try writer.write("\n\n");
            }
            try indent(writer, indent_level);
        }
        try format(writer, list.items[0], indent_level);
        prior_line = list.items[0].line;

        for (list.items[1..]) |node| {
            if (node.line > prior_line) {
                if (node.line == prior_line + 1) {
                    _ = try writer.write("\n");
                } else {
                    _ = try writer.write("\n\n");
                }
                try indent(writer, indent_level);
            } else {
                _ = try writer.write(" ");
            }
            try format(writer, node, indent_level);
            prior_line = node.line;
        }
    }
}

fn indent(writer: anytype, indent_level: usize) !void {
    for (0..indent_level) |_| {
        _ = try writer.write("\t");
    }
}
