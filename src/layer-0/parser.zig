const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig").Lexer;
const Node = @import("../hst.zig").Node;
const out = @import("../out.zig");
const Vm = @import("../vm.zig").Vm;

pub fn parse(vm: *Vm, source: []const u8) Node {
    var lexer = Lexer.init(source);
    const root = Node.File(vm.hst_allocator);

    parseHelper(vm, &lexer, root.asFile(), false) catch {
        out.printExit("Could not allocate memory for HST.", .{}, 1);
    };

    return root;
}

fn parseHelper(vm: *Vm, lexer: *Lexer, parent: *ArrayList(Node), is_list: bool) !void {
    while (true) {
        const tok = lexer.lexToken();
        switch (tok.type) {
            .left_paren => {
                const list = Node.List(vm.hst_allocator, tok.line, tok.column);
                try parent.append(list);
                try parseHelper(vm, lexer, list.asList(), true);
            },
            .right_paren => {
                if (!is_list) {
                    // todo - error
                }
                return;
            },
            .comment => {
                const val = vm.copyString(tok.value);
                const node = Node.Comment(val, tok.line, tok.column);
                try parent.append(node);
            },
            .string => {
                const val = vm.copyString(tok.value);
                const node = Node.String(val, tok.line, tok.column);
                try parent.append(node);
            },
            .value => {
                const val = vm.copyString(tok.value);
                const node = Node.Value(val, tok.line, tok.column);
                try parent.append(node);
            },
            else => return,
        }
    }
}
