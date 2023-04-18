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
        .value => try writer.writeAll(node.asValue()),
    }
}

fn formatFile(writer: anytype, file: Node, indent_level: usize) Error!void {
    const items = file.asFile().items;
    if (items.len > 0) {
        try format(writer, items[0], indent_level);
        var prior_line = items[0].end_line;

        for (items[1..]) |node| {
            if (node.start_line == prior_line and node.getType() == .comment) {
                try writer.writeAll(" ");
            } else {
                if (node.start_line > prior_line + 1) {
                    try writer.writeAll("\n\n");
                } else {
                    try writer.writeAll("\n");
                }
                try indent(writer, indent_level);
            }
            try format(writer, node, indent_level);
            prior_line = node.end_line;
        }

        try writer.writeAll("\n");
    }
}

fn formatList(writer: anytype, list: Node, indent_level: usize) Error!void {
    const items = list.asList().items;
    var prior_line = list.start_line;
    var cur_indent = indent_level;

    try writer.writeAll("(");

    if (items.len > 0) {
        if (items[0].start_line > prior_line) {
            cur_indent = indent_level + 1;
            try writer.writeAll("\n");
            try indent(writer, cur_indent);
        }
        try format(writer, items[0], cur_indent);
        prior_line = items[0].end_line;

        for (items[1..]) |node| {
            if (node.start_line > prior_line) {
                cur_indent = indent_level + 1;
                if (node.start_line == prior_line + 1) {
                    try writer.writeAll("\n");
                } else {
                    try writer.writeAll("\n\n");
                }
                try indent(writer, cur_indent);
            } else {
                try writer.writeAll(" ");
            }
            try format(writer, node, cur_indent);
            prior_line = node.end_line;
        }
    }

    if (cur_indent > indent_level) {
        try writer.writeAll("\n");
        try indent(writer, indent_level);
    }
    try writer.writeAll(")");
}

fn indent(writer: anytype, indent_level: usize) !void {
    for (0..indent_level) |_| {
        try writer.writeAll("\t");
    }
}
