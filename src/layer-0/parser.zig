const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig").Lexer;
const Node = @import("../hst.zig").Node;
const Vm = @import("../vm.zig").Vm;

pub fn parse(vm: *Vm, source: []const u8) !Node {
    var lexer = Lexer.init(source);
    var root = try Node.File(vm.allocator);

    try parseHelper(vm, &lexer, &root, root.asFile());

    return root;
}

fn parseHelper(vm: *Vm, lexer: *Lexer, parent_node: *Node, parent: *ArrayList(Node)) !void {
    while (true) {
        const tok = lexer.lexToken();
        switch (tok.type) {
            .left_paren => {
                var list = try Node.List(vm.allocator, tok.start_line, tok.start_column);
                try parseHelper(vm, lexer, &list, list.asList());
                try parent.append(list);
            },
            .right_paren => {
                if (!parent_node.isList()) {
                    // todo - error
                }
                parent_node.end_line = tok.end_line;
                parent_node.end_column = tok.end_column;
                return;
            },
            .comment => {
                const val = try vm.copyString(tok.value);
                const node = Node.Comment(val, tok.start_line, tok.start_column);
                try parent.append(node);
            },
            .literal => {
                const val = try vm.copyString(tok.value);
                const node = Node.Literal(val, tok.start_line, tok.start_column);
                try parent.append(node);
            },
            .string => {
                const val = try vm.copyString(tok.value);
                const node = Node.String(val, tok.start_line, tok.start_column, tok.end_line, tok.end_column);
                try parent.append(node);
            },
            else => return,
        }
    }
}
