const std = @import("std");
const Allocator = std.mem.Allocator;

const console = @import("console.zig");
const Flags = @import("flags.zig").Flags;
const Vm = @import("vm.zig").Vm;

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0, .pre = "dev.10" };

pub fn main() !void {
    console.init();
    defer console.flush();

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
        _ = parseFlags(args[2..]);
        printUsage();
    } else if (args.len >= 3 and std.mem.eql(u8, args[1], "run")) {
        const flags = parseFlags(args[3..]);

        var vm: Vm = undefined;
        vm.init(alloc);
        defer vm.deinit();

        try runFile(&vm, args[2], flags);
    } else if (args.len >= 2 and std.mem.eql(u8, args[1], "version")) {
        _ = parseFlags(args[2..]);
        try version.format("", .{}, console.stdout);
        console.println("", .{});
    } else {
        printUsage();
        console.printExit("", .{}, 64);
    }
}

fn parseFlags(flags: []const []const u8) Flags {
    var result = Flags{ .layer = 1, .no_style = false };
    for (flags) |flag| {
        if (std.mem.eql(u8, flag, "-layer-0")) {
            result.layer = 0;
        } else if (std.mem.eql(u8, flag, "-no-style")) {
            result.no_style = true;
            console.no_style = true;
        }
    }
    return result;
}

fn printUsage() void {
    console.println(
        \\Usage: expl <command> [flags]
        \\
        \\Commands:
        \\  format <file>   Format specified file
        \\  run <file>      Run specified file
        \\
        \\  help            Print this help and exit
        \\  version         Print version and exit
        \\
        \\Flags:
        \\  -layer-0        Use language layer 0
        \\  -no-style       Output as plain text
        \\
    , .{});
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

    const result = vm.interpret(source, flags.layer);

    if (result == .compile_error) console.printExit("", .{}, 65);
    if (result == .runtime_error) console.printExit("", .{}, 70);
}
