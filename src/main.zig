const std = @import("std");

const Flags = @import("flags.zig").Flags;
const Vm = @import("vm.zig").Vm;

const version = std.SemanticVersion{ .major = 0, .minor = 2, .patch = 0 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len >= 3 and std.mem.eql(u8, args[1], "format")) {
        const flags = parseFlags(args[3..]);

        var vm: Vm = undefined;
        vm.init(alloc);
        defer vm.deinit();

        try formatFile(&vm, args[2], flags);
    } else if (args.len >= 2 and std.mem.eql(u8, args[1], "help")) {
        printUsage();
    } else if (args.len >= 3 and std.mem.eql(u8, args[1], "run")) {
        const flags = parseFlags(args[3..]);

        var vm: Vm = undefined;
        vm.init(alloc);
        defer vm.deinit();

        try runFile(&vm, args[2], flags);
    } else if (args.len >= 2 and std.mem.eql(u8, args[1], "version")) {
        std.debug.print("{}\n", .{version});
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn parseFlags(flags: []const []const u8) Flags {
    var result = Flags{ .layer = 1 };
    for (flags) |flag| {
        if (std.mem.eql(u8, flag, "-layer-0")) {
            result.layer = 0;
        }
    }
    return result;
}

fn formatFile(vm: *Vm, path: []const u8, flags: Flags) !void {
    var file = try std.fs.cwd().openFile(path, .{});

    const source = try file.readToEndAlloc(vm.parent_allocator, std.math.maxInt(usize));
    defer vm.parent_allocator.free(source);

    file.close();
    file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    var buffered_writer = std.io.bufferedWriter(file.writer());
    try vm.format(buffered_writer.writer(), source, flags.layer);
    try buffered_writer.flush();
}

fn runFile(vm: *Vm, path: []const u8, flags: Flags) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(vm.parent_allocator, std.math.maxInt(usize));
    defer vm.parent_allocator.free(source);

    try vm.interpret(source, flags.layer);
}

fn printUsage() void {
    std.debug.print(
        \\Usage: expl <command> [flags]
        \\
        \\Commands:
        \\  format <file>   Format specified file
        \\  run    <file>   Run specified file
        \\
        \\  help            Print this help and exit
        \\  version         Print version and exit
        \\
        \\Flags:
        \\  -layer-0        Use language layer 0
        \\
    , .{});
}
