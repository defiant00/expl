const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = @import("debug.zig");
const Vm = @import("vm.zig").Vm;

pub const GcAllocater = struct {
    pub const heap_grow_factor = 2;

    vm: *Vm,
    bytes_allocated: usize,
    next_gc: usize,

    pub fn init(vm: *Vm) GcAllocater {
        return .{
            .vm = vm,
            .bytes_allocated = 0,
            .next_gc = 1024 * 1024,
        };
    }

    pub fn deinit(self: *GcAllocater) void {
        _ = self;
    }

    pub fn allocator(self: *GcAllocater) Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .free = free,
            },
        };
    }

    fn alloc(ctx: *anyopaque, len: usize, log2_ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self = @ptrCast(*GcAllocater, @alignCast(@alignOf(GcAllocater), ctx));

        if ((self.bytes_allocated + len > self.next_gc) or debug.stress_gc) {
            self.vm.collectGarbage();
        }
        const result = self.vm.parent_allocator.rawAlloc(len, log2_ptr_align, ret_addr);
        if (result != null) {
            const before = self.bytes_allocated;
            self.bytes_allocated += len;
            if (debug.log_gc) {
                std.debug.print("  {d} -> {d}\n", .{ before, self.bytes_allocated });
            }
        }
        return result;
    }

    fn resize(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, new_len: usize, ret_addr: usize) bool {
        const self = @ptrCast(*GcAllocater, @alignCast(@alignOf(GcAllocater), ctx));

        if (new_len > buf.len) {
            if ((self.bytes_allocated + (new_len - buf.len) > self.next_gc) or debug.stress_gc) {
                self.vm.collectGarbage();
            }
        }

        if (self.vm.parent_allocator.rawResize(buf, log2_buf_align, new_len, ret_addr)) {
            const before = self.bytes_allocated;
            if (new_len > buf.len) {
                self.bytes_allocated += new_len - buf.len;
            } else {
                self.bytes_allocated -= buf.len - new_len;
            }
            if (debug.log_gc) {
                std.debug.print("  {d} -> {d}\n", .{ before, self.bytes_allocated });
            }
            return true;
        }

        return false;
    }

    fn free(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, ret_addr: usize) void {
        const self = @ptrCast(*GcAllocater, @alignCast(@alignOf(GcAllocater), ctx));

        self.vm.parent_allocator.rawFree(buf, log2_buf_align, ret_addr);
        const before = self.bytes_allocated;
        self.bytes_allocated -= buf.len;
        if (debug.log_gc) {
            std.debug.print("  {d} -> {d}\n", .{ before, self.bytes_allocated });
        }
    }
};
