const Lexer = @import("lexer.zig").Lexer;
const Node = @import("../hst.zig").Node;
const Vm = @import("../vm.zig").Vm;

pub const Parser = struct {
    pub fn parse(vm: *Vm, source: []const u8) Node {
        var lexer = Lexer.init(source);
        const root = Node.File(vm.allocator);

        _ = lexer;

        // self.parse(&lexer, root, true) catch {
        //     out.printExit("Could not allocate memory for AST.", .{}, 1);
        // };

        return root;
    }

    // fn parse(self: *Vm, lexer: *layer_0.Lexer, parent: Node, root: bool) !void {
    //     _ = root;
    //     while (!lexer.isAtEnd()) {
    //         const tok = lexer.lexToken();
    //         switch (tok.type) {
    //             .left_paren => {
    //                 const list = Node.List(self.allocator);
    //                 try parent.list.append(list);
    //                 try self.parse(lexer, list, false);
    //             },
    //             .right_paren => return, // todo - error if this is the root
    //             .identifier => {
    //                 const ident = Node.Identifier(self.copyString(tok.value));
    //                 try parent.list.append(ident);
    //             },
    //             .number => {
    //                 // todo - number
    //             },
    //             .string => {
    //                 const str = Node.String(self.copyString(tok.value));
    //                 try parent.list.append(str);
    //             },
    //             else => return,
    //         }
    //     }
    // }
};
