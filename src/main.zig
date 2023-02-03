const std = @import("std");
const Allocator = std.mem.Allocator;

const out = @import("out.zig");
const version = @import("version.zig").version;
const Vm = @import("vm.zig").Vm;

pub fn main() !void {
    out.init();
    defer out.flush();

    out.println("expl {d}.{d}.{d}", .{ version.major, version.minor, version.patch });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(allocator);
    defer arg_list.deinit();

    while (args.next()) |arg| try arg_list.append(arg);

    var valid = false;
    if (arg_list.items.len >= 3 and std.mem.eql(u8, arg_list.items[1], "run")) {
        valid = true;
        parseFlags(arg_list.items[3..]);

        var vm: Vm = undefined;
        vm.init(allocator);
        defer vm.deinit();

        try runFile(allocator, &vm, arg_list.items[2]);
    }

    if (!valid) {
        out.printExit("Usage: expl [command] [flags]\n  Commands:\n    run [file]\n  Flags:\n    -no-style", .{}, 64);
    }
}

fn parseFlags(flags: []const []const u8) void {
    for (flags) |flag| {
        if (std.mem.eql(u8, flag, "-no-style")) {
            out.no_style = true;
        }
    }
}

fn runFile(allocator: Allocator, vm: *Vm, path: []const u8) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    const result = vm.interpret(source);

    if (result == .compile_error) out.printExit("", .{}, 65);
    if (result == .runtime_error) out.printExit("", .{}, 70);
}
