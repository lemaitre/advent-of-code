const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;

    var rotBuf : [14]u32 = undefined;
    rotBuf = .{@as(u32, 1) << @intCast(u5, input[0] - 'a')} ** rotBuf.len;
    var found : usize = undefined;

    for (input) |c, i| {
        var bits : u32 = 0;
        for (rotBuf) |x| {
            bits |= x;
        }
        if (@popCount(u32, bits) == rotBuf.len) {
            found = i;
            break;
        }

        rotBuf[i%rotBuf.len] = @as(u32, 1) << @intCast(u5, c - 'a');
    }
    try std.fmt.format(stdout, "{}\n", .{found});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var allocator = arena.allocator();
    var arg_it = try std.process.argsWithAllocator(allocator);
    defer arg_it.deinit();

    // skip my own exe name
    _ = arg_it.skip();

    var inputFilename = arg_it.next(allocator) orelse "-" catch "-";
    if (std.mem.eql(u8, inputFilename, "-")) {
        inputFilename = "/dev/stdin";
    }
    var input = try std.fs.cwd().readFileAlloc(allocator, inputFilename, std.math.maxInt(usize));
    try process(allocator, input);
    _ = input;
    defer allocator.free(input);
}
