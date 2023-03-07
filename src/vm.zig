const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const hst = @import("hst.zig");
const GcAllocator = @import("memory.zig").GcAllocater;
const out = @import("out.zig");
const layer_0_parser = @import("layer-0/parser.zig");

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

    hst_arena: ArenaAllocator,
    hst_allocator: Allocator,

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

    fn initHst(self: *Vm) void {
        self.hst_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        self.hst_allocator = self.hst_arena.allocator();
    }

    fn deinitHst(self: *Vm) void {
        self.hst_arena.deinit();
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

    fn getHst(self: *Vm, source: []const u8, layer: u8) hst.Node {
        return switch (layer) {
            0 => layer_0_parser.parse(self, source),
            else => out.printExit("Invalid layer {d}", .{layer}, 1),
        };
    }

    pub fn format(self: *Vm, writer: anytype, source: []const u8, layer: u8) !void {
        self.initHst();

        const root = getHst(self, source, layer);
        try root.format(writer, layer);

        self.deinitHst();
    }

    pub fn interpret(self: *Vm, source: []const u8, layer: u8) InterpretResult {
        self.initHst();

        const root = getHst(self, source, layer);
        root.format(out.stdout, layer) catch {
            return .compile_error;
        };

        // todo - hst to ast

        self.deinitHst();

        return .ok;
    }
};
