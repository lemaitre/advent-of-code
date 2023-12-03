const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

fn CRT(comptime h: comptime_int, comptime w: comptime_int) type {
    return struct {
        const Self = @This();

        data: [h][w]u8 = undefined,
        i: u16 = 0,
        j: u16 = 0,

        fn next(self: *Self, x: i32) void {
            var diff = x - self.j;
            var char : u8 = undefined;
            if (-1 <= diff and diff <= 1) {
                char = '#';
            } else {
                char = '.';
            }
            self.data[self.i][self.j] = char;

            if (self.j == w-1) {
                self.i += 1;
                self.j = 0;
            } else {
                self.j += 1;
            }
        }

        fn print(self: Self, out: anytype) !void {
            for (self.data) |row| {
                try std.fmt.format(out, "{s}\n", .{row});
            }
        }
    };
}
pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;
    var crt = CRT(6, 40){};

    var x: i32 = 1;

    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var tokens = [1][]const u8{undefined}**3;
        var read = iterInto(&std.mem.tokenize(u8, line, " "), &tokens);
        assert(read > 0);
        var ins = tokens[0];

        crt.next(x);
        if (std.mem.eql(u8, ins, "noop")) {
            assert(read == 1);
        } else if (std.mem.eql(u8, ins, "addx")) {
            assert(read == 2);
            crt.next(x);
            x += try std.fmt.parseInt(i32, tokens[1], 10);
        } else {
            assert(false);
        }
    }

    try crt.print(stdout);
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
