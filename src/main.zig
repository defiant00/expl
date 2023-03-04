const std = @import("std");
const Allocator = std.mem.Allocator;

const Flags = @import("flags.zig").Flags;
const out = @import("out.zig");
const Vm = @import("vm.zig").Vm;

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0, .pre = "dev.0.7" };

pub fn main() !void {
    out.init();
    defer out.flush();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(allocator);
    defer arg_list.deinit();

    while (args.next()) |arg| try arg_list.append(arg);

    var valid = false;
    if (arg_list.items.len >= 2 and std.mem.eql(u8, arg_list.items[1], "help")) {
        valid = true;
        _ = parseFlags(arg_list.items[2..]);
        printUsage();
    } else if (arg_list.items.len >= 3 and std.mem.eql(u8, arg_list.items[1], "run")) {
        valid = true;
        const flags = parseFlags(arg_list.items[3..]);

        var vm: Vm = undefined;
        vm.init(allocator);
        defer vm.deinit();

        try runFile(allocator, &vm, arg_list.items[2], flags);
    } else if (arg_list.items.len >= 2 and std.mem.eql(u8, arg_list.items[1], "version")) {
        valid = true;
        _ = parseFlags(arg_list.items[2..]);
        try version.format("", .{}, out.stdout);
        out.println("", .{});
    }

    if (!valid) {
        printUsage();
        out.printExit("", .{}, 64);
    }
}

fn parseFlags(flags: []const []const u8) Flags {
    var result = Flags{ .layer = 1, .no_style = false };
    for (flags) |flag| {
        if (std.mem.eql(u8, flag, "-layer-0")) {
            result.layer = 0;
        } else if (std.mem.eql(u8, flag, "-no-style")) {
            result.no_style = true;
            out.no_style = true;
        }
    }
    return result;
}

fn printUsage() void {
    out.println(
        \\Usage: expl <command> [flags]
        \\
        \\Commands:
        \\  help            Print this help and exit
        \\  run <file>      Run specified file
        \\  version         Print version and exit
        \\
        \\Flags:
        \\  -layer-0        Use language layer 0
        \\  -no-style       Output as plain text
    , .{});
}

fn runFile(allocator: Allocator, vm: *Vm, path: []const u8, flags: Flags) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    const result = vm.interpret(source, flags.layer);

    if (result == .compile_error) out.printExit("", .{}, 65);
    if (result == .runtime_error) out.printExit("", .{}, 70);
}
