const std = @import("std");
const ArrayList = std.ArrayList;

const console = @import("../console.zig");
const Lexer = @import("lexer.zig").Lexer;
const Node = @import("../hst.zig").Node;
const Vm = @import("../vm.zig").Vm;

pub fn parse(vm: *Vm, source: []const u8) Node {
    var lexer = Lexer.init(source);
    var root = Node.File(vm.hst_allocator);

    parseHelper(vm, &lexer, &root, root.asFile()) catch {
        console.printExit("Could not allocate memory for HST.", .{}, 1);
    };

    return root;
}

fn parseHelper(vm: *Vm, lexer: *Lexer, parent_node: *Node, parent: *ArrayList(Node)) !void {
    while (true) {
        const tok = lexer.lexToken();
        switch (tok.type) {
            .left_paren => {
                var list = Node.List(vm.hst_allocator, tok.start_line, tok.start_column);
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
                const val = vm.copyString(tok.value);
                const node = Node.Comment(val, tok.start_line, tok.start_column);
                try parent.append(node);
            },
            .string => {
                const val = vm.copyString(tok.value);
                const node = Node.String(val, tok.start_line, tok.start_column, tok.end_line, tok.end_column);
                try parent.append(node);
            },
            .value => {
                const val = vm.copyString(tok.value);
                const node = Node.Value(val, tok.start_line, tok.start_column);
                try parent.append(node);
            },
            else => return,
        }
    }
}
