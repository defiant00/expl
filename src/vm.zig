const std = @import("std");
const Allocator = std.mem.Allocator;

const GcAllocator = @import("memory.zig").GcAllocater;
const out = @import("out.zig");
const layer_0 = @import("layer-0/parser.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const InterpretResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub const Vm = struct {
    parent_allocator: Allocator,
    gc: GcAllocator,
    allocator: Allocator,

    strings: std.StringHashMap(void),

    pub fn init(self: *Vm, allocator: Allocator) void {
        self.parent_allocator = allocator;
        self.gc = GcAllocator.init(self);
        self.allocator = self.gc.allocator();

        self.strings = std.StringHashMap(void).init(self.allocator);
    }

    pub fn deinit(self: *Vm) void {
        var key_iter = self.strings.keyIterator();
        while (key_iter.next()) |key| self.allocator.free(key.*);
        self.strings.deinit();
    }

    pub fn collectGarbage(self: *Vm) void {
        _ = self;
    }

    pub fn copyString(self: *Vm, chars: []const u8) []const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| return i;

        const heap_chars = self.allocator.alloc(u8, chars.len) catch {
            out.printExit("Could not allocate memory for string.", .{}, 1);
        };
        std.mem.copy(u8, heap_chars, chars);
        self.strings.put(heap_chars, {}) catch {
            out.printExit("Could not allocate memory for string.", .{}, 1);
        };
        return heap_chars;
    }

    test "copy string" {
        var vm: Vm = undefined;
        vm.init(std.testing.allocator);
        defer vm.deinit();

        const s1 = vm.copyString("first");
        _ = vm.copyString("second");
        _ = vm.copyString("third");
        const s1_2 = vm.copyString("first");

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn takeString(self: *Vm, chars: []const u8) []const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| {
            self.allocator.free(chars);
            return i;
        }
        self.strings.put(chars, {}) catch {
            out.printExit("Could not allocate memory for string.", .{}, 1);
        };
        return chars;
    }

    test "take string" {
        var vm: Vm = undefined;
        vm.init(std.testing.allocator);
        defer vm.deinit();

        const heap_chars_1 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1, "first");
        const s1 = vm.takeString(heap_chars_1);

        const heap_chars_2 = try vm.allocator.alloc(u8, 6);
        std.mem.copy(u8, heap_chars_2, "second");
        _ = vm.takeString(heap_chars_2);

        const heap_chars_3 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_3, "third");
        _ = vm.takeString(heap_chars_3);

        const heap_chars_1_2 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1_2, "first");
        const s1_2 = vm.takeString(heap_chars_1_2);

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn interpret(self: *Vm, source: []const u8, layer: u8) InterpretResult {
        const root = switch (layer) {
            0 => layer_0.Parser.parse(self, source),
            1 => {
                out.println("Layer 1 is not supported yet.", .{});
                return .compile_error;
            },
            else => {
                out.println("Invalid layer {d}", .{layer});
                return .compile_error;
            },
        };
        _ = root;

        // var lexer = Lexer.init(source);
        // var indent: usize = 0;
        // while (!lexer.isAtEnd()) {
        //     const tok = lexer.lexToken();

        //     if (tok.type == .right_paren) indent -= 1;

        //     {
        //         var i = indent;
        //         while (i > 0) : (i -= 1) {
        //             out.print("  ", .{});
        //         }
        //     }
        //     switch (tok.type) {
        //         .left_paren, .right_paren => out.printlnColor("{s}", .{tok.value}, .yellow),
        //         .number => out.printlnColor("{s}", .{tok.value}, .blue),
        //         .string => out.printlnColor("\"{s}\"", .{tok.value}, .orange),
        //         else => out.println("{s}", .{tok.value}),
        //     }

        //     if (tok.type == .left_paren) indent += 1;
        // }

        return .ok;
    }
};
