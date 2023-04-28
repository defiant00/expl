const std = @import("std");
const Allocator = std.mem.Allocator;

const hst = @import("hst.zig");
const GcAllocator = @import("memory.zig").GcAllocater;
const layer_0_parser = @import("layer-0/parser.zig");

test {
    std.testing.refAllDecls(@This());
}

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

    pub fn copyString(self: *Vm, chars: []const u8) ![]const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| return i;

        const heap_chars = try self.allocator.alloc(u8, chars.len);
        std.mem.copy(u8, heap_chars, chars);
        try self.strings.put(heap_chars, {});
        return heap_chars;
    }

    test "copy string" {
        var vm: Vm = undefined;
        vm.init(std.testing.allocator);
        defer vm.deinit();

        const s1 = try vm.copyString("first");
        _ = try vm.copyString("second");
        _ = try vm.copyString("third");
        const s1_2 = try vm.copyString("first");

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn takeString(self: *Vm, chars: []const u8) ![]const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| {
            self.allocator.free(chars);
            return i;
        }
        try self.strings.put(chars, {});
        return chars;
    }

    test "take string" {
        var vm: Vm = undefined;
        vm.init(std.testing.allocator);
        defer vm.deinit();

        const heap_chars_1 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1, "first");
        const s1 = try vm.takeString(heap_chars_1);

        const heap_chars_2 = try vm.allocator.alloc(u8, 6);
        std.mem.copy(u8, heap_chars_2, "second");
        _ = try vm.takeString(heap_chars_2);

        const heap_chars_3 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_3, "third");
        _ = try vm.takeString(heap_chars_3);

        const heap_chars_1_2 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1_2, "first");
        const s1_2 = try vm.takeString(heap_chars_1_2);

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    fn getHst(self: *Vm, source: []const u8, layer: u8) !hst.Node {
        return switch (layer) {
            0 => layer_0_parser.parse(self, source),
            else => {
                std.debug.print("Invalid layer {d}\n", .{layer});
                return error.InvalidLayer;
            },
        };
    }

    pub fn format(self: *Vm, writer: anytype, source: []const u8, layer: u8) !void {
        const root = try getHst(self, source, layer);
        defer root.deinit(self.allocator);

        try root.format(writer, layer);
    }

    pub fn interpret(self: *Vm, source: []const u8, layer: u8) !void {
        const root = try getHst(self, source, layer);
        defer root.deinit(self.allocator);

        try root.format(std.io.getStdErr().writer(), layer);

        // todo - hst to ast
    }
};
