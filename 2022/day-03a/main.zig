const std = @import("std");
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

fn prio(item: u8) u8 {
    if (item >= 'a') {
        return 1 + item - 'a';
    } else {
        return 27 + item - 'A';
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

    while (std.mem.indexOfScalar(u8, readInput, '\n')) |linePos| {
        var line = readInput[0..linePos];
        readInput = readInput[(linePos + 1)..readInput.len];

        var n = line.len / 2;
        var L = line[0..n];
        var R = line[n..line.len];

        std.sort.sort(u8, L, {}, comptime std.sort.asc(u8));
        std.sort.sort(u8, R, {}, comptime std.sort.asc(u8));

        var i: usize = 0;
        var j: usize = 0;

        while (true) {
            switch (std.math.order(L[i], R[j])) {
                .lt => i += 1,
                .gt => j += 1,
                .eq => break,
            }
        }

        sum += prio(L[i]);
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
