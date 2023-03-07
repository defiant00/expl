const std = @import("std");
const ArrayList = std.ArrayList;
const Error = std.fs.File.WriteError;

const Node = @import("../hst.zig").Node;

pub fn format(writer: anytype, node: Node, indent_level: usize) Error!void {
    switch (node.getType()) {
        .comment => try writer.print(";{s}", .{node.asComment()}),
        .file => try formatFile(writer, node, indent_level),
        .list => try formatList(writer, node, indent_level),
        .string => try writer.print("\"{s}\"", .{node.asString()}),
        .value => _ = try writer.write(node.asValue()),
    }
}

fn formatFile(writer: anytype, file: Node, indent_level: usize) Error!void {
    const items = file.asFile().items;
    if (items.len > 0) {
        try format(writer, items[0], indent_level);
        var prior_line = items[0].end_line;

        for (items[1..]) |node| {
            if (node.start_line == prior_line and node.getType() == .comment) {
                _ = try writer.write(" ");
            } else {
                if (node.start_line > prior_line + 1) {
                    _ = try writer.write("\n\n");
                } else {
                    _ = try writer.write("\n");
                }
                try indent(writer, indent_level);
            }
            try format(writer, node, indent_level);
            prior_line = node.end_line;
        }

        _ = try writer.write("\n");
    }
}

fn formatList(writer: anytype, list: Node, indent_level: usize) Error!void {
    const items = list.asList().items;
    var prior_line = list.start_line;
    var cur_indent = indent_level;

    _ = try writer.write("(");

    if (items.len > 0) {
        if (items[0].start_line > prior_line) {
            cur_indent = indent_level + 1;
            _ = try writer.write("\n");
            try indent(writer, cur_indent);
        }
        try format(writer, items[0], cur_indent);
        prior_line = items[0].end_line;

        for (items[1..]) |node| {
            if (node.start_line > prior_line) {
                cur_indent = indent_level + 1;
                if (node.start_line == prior_line + 1) {
                    _ = try writer.write("\n");
                } else {
                    _ = try writer.write("\n\n");
                }
                try indent(writer, cur_indent);
            } else {
                _ = try writer.write(" ");
            }
            try format(writer, node, cur_indent);
            prior_line = node.end_line;
        }
    }

    if (cur_indent > indent_level) {
        _ = try writer.write("\n");
        try indent(writer, indent_level);
    }
    _ = try writer.write(")");
}

fn indent(writer: anytype, indent_level: usize) !void {
    for (0..indent_level) |_| {
        _ = try writer.write("\t");
    }
}
