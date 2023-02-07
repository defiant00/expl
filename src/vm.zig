const std = @import("std");
const Allocator = std.mem.Allocator;
const Lexer = @import("lexer.zig").Lexer;
const out = @import("out.zig");

pub const InterpretResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub const Vm = struct {
    parent_allocator: Allocator,

    pub fn init(self: *Vm, allocator: Allocator) void {
        self.parent_allocator = allocator;
    }

    pub fn deinit(self: *Vm) void {
        _ = self;
    }

    pub fn interpret(self: *Vm, source: []const u8) InterpretResult {
        _ = self;

        var lexer = Lexer.init(source);
        var indent: usize = 0;
        while (!lexer.isAtEnd()) {
            const tok = lexer.lexToken();

            if (tok.type == .right_paren) indent -= 1;

            {
                var i = indent;
                while (i > 0) : (i -= 1) {
                    out.print("  ", .{});
                }
            }
            out.println("{s}", .{tok.value});

            if (tok.type == .left_paren) indent += 1;
        }

        return .ok;
    }
};
