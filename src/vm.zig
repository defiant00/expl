const std = @import("std");
const Allocator = std.mem.Allocator;

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
        _ = source;

        return .ok;
    }
};
