const std = @import("std");
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

fn prio(item: u8) u6 {
    if (item >= 'a') {
        return @intCast(u6, 1 + item - 'a');
    } else {
        return @intCast(u6, 27 + item - 'A');
    }
}

test "prio" {
    try expect(prio('a') == 1);
    try expect(prio('z') == 26);
    try expect(prio('A') == 27);
    try expect(prio('Z') == 52);
}

pub fn process(allocator: std.mem.Allocator, input: []u8) !void {
    _ = allocator;

    var readInput = input;

    var sum: u32 = 0;
    var elfIndex: u32 = 0;

    var elfGroup: [3]u64 = .{undefined} ** 3;

    _ = elfIndex;
    _ = elfGroup;

    while (std.mem.indexOfScalar(u8, readInput, '\n')) |linePos| {
        var line = readInput[0..linePos];
        readInput = readInput[(linePos + 1)..readInput.len];

        { // set of all items
            var items: u64 = 0;
            for (line) |c| {
                items |= @as(u64, 1) << prio(c);
            }
            elfGroup[elfIndex] = items;
            elfIndex += 1;
        }

        if (elfIndex < elfGroup.len) {
            continue;
        }

        elfIndex = 0;

        var commonItems = -%@as(u64, 1);
        for (elfGroup) |items| {
            commonItems &= items;
        }

        var badge = @ctz(u64, commonItems);
        sum += badge;
    }
    _ = try std.fmt.format(stdout, "{}\n", .{sum});
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
