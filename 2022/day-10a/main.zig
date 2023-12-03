const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var values = std.ArrayList(i32).init(allocator);
    defer values.deinit();

    var x: i32 = 1;
    try values.append(x);

    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var tokens = [1][]const u8{undefined}**3;
        var read = iterInto(&std.mem.tokenize(u8, line, " "), &tokens);
        assert(read > 0);
        var ins = tokens[0];

        try values.append(x);
        if (std.mem.eql(u8, ins, "noop")) {
            assert(read == 1);
        } else if (std.mem.eql(u8, ins, "addx")) {
            assert(read == 2);
            try values.append(x);
            x += try std.fmt.parseInt(i32, tokens[1], 10);
        } else {
            assert(false);
        }
    }

    var i : u32 = 20;
    var sum : i64 = 0;
    while (i < values.items.len) : (i += 40) {
        sum += values.items[i] * @as(i64, i);
    }

    try std.fmt.format(stdout, "sum: {}\n", .{sum});
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

fn iterInto(iter: anytype, output: anytype) usize {
    var n: usize = 0;
    for (output) |*out| {
        if (iter.next()) |element| {
            out.* = element;
        } else {
            return n;
        }
        n += 1;
    }

    return n;
}

fn iterEat(iter: anytype) usize {
    var n: usize = 0;

    while (iter.next()) |_| {
        n += 1;
    }

    return n;
}

fn iterIntoExact(iter: anytype, output: anytype) !void {
    var n = iterInto(iter, output);
    if (n < output.len) {
        return error.tooFewElements;
    }
    if (iter.next()) |_| {
        return error.tooManyElements;
    }
}

fn range(n: usize) []const void {
    return @as([*]const void, undefined)[0..n];
}
