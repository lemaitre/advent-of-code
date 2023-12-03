const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

fn snafuToInt(input: []const u8) u64 {
    var sum: u64 = 0;
    for (input) |c| {
        sum *= 5;
        sum = switch (c) {
            '=' => sum - 2,
            '-' => sum - 1,
            '0' => sum,
            '1' => sum + 1,
            '2' => sum + 2,
            else => unreachable,
        };
    }
    return sum;
}

test "snafuToInt" {
    try expect(snafuToInt("1") == 1);
    try expect(snafuToInt("2") == 2);
    try expect(snafuToInt("1=") == 3);
    try expect(snafuToInt("1-") == 4);
    try expect(snafuToInt("10") == 5);
    try expect(snafuToInt("11") == 6);
    try expect(snafuToInt("12") == 7);
    try expect(snafuToInt("2=") == 8);
    try expect(snafuToInt("2-") == 9);
    try expect(snafuToInt("20") == 10);
    try expect(snafuToInt("21") == 11);
    try expect(snafuToInt("111") == 31);
    try expect(snafuToInt("112") == 32);
    try expect(snafuToInt("122") == 37);
    try expect(snafuToInt("1-12") == 107);
    try expect(snafuToInt("2=0=") == 198);
    try expect(snafuToInt("2=01") == 201);
    try expect(snafuToInt("1=-1=") == 353);
    try expect(snafuToInt("12111") == 906);
    try expect(snafuToInt("20012") == 1257);
    try expect(snafuToInt("1=-0-2") == 1747);
    try expect(snafuToInt("1=11-2") == 2022);
    try expect(snafuToInt("1-0---0") == 12345);
    try expect(snafuToInt("1121-1110-1=0") == 314159265);
}

fn intToSnafu(a: u64) [64]u8 {
    var x : [64]u8 = undefined;
    std.mem.set(u8, &x, '0');

    var b = a;
    var i : u5 = 0;
    var carry: u1 = 0;
    while (b > 0 or carry > 0) {
        const d = (b % 5) + carry;
        x[i] = ([_]u8{'0', '1', '2', '=', '-', '0'})[d];
        carry = ([_]u1{0, 0, 0, 1, 1, 1})[d];

        b /= 5;
        i += 1;
    }

    std.mem.reverse(u8, &x);
    return x;
}

test "intToSnafu" {
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(1), "0"), "1"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(2), "0"), "2"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(3), "0"), "1="));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(4), "0"), "1-"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(5), "0"), "10"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(6), "0"), "11"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(7), "0"), "12"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(8), "0"), "2="));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(9), "0"), "2-"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(10), "0"), "20"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(11), "0"), "21"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(31), "0"), "111"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(32), "0"), "112"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(37), "0"), "122"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(107), "0"), "1-12"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(198), "0"), "2=0="));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(201), "0"), "2=01"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(353), "0"), "1=-1="));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(906), "0"), "12111"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(1257), "0"), "20012"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(1747), "0"), "1=-0-2"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(2022), "0"), "1=11-2"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(12345), "0"), "1-0---0"));
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, &intToSnafu(314159265), "0"), "1121-1110-1=0"));
}


pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var sum : u64 = 0;
    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        sum += snafuToInt(line);
    }

    try std.fmt.format(stdout, "sum: {s}\n", .{std.mem.trimLeft(u8, &intToSnafu(sum), "0")});
    _ = allocator;
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

    var timer = try std.time.Timer.start();
    try process(allocator, input);
    var duration = timer.read();
    try std.fmt.format(stdout, "elapsed time: {}\n", .{std.fmt.fmtDuration(duration)});

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

fn gcd(comptime T: type, x: T, y: T) T {
    if (x == 0) {
        return y;
    }

    return gcd(T, @mod(y, x), x);
}

fn lcm(comptime T: type, x: T, y: T) T {
    return x * y / gcd(T, x, y);
}

fn removePrefix(input: []const u8, comptime prefix: []const u8) []const u8 {
    if (input.len < prefix.len or !std.mem.eql(u8, input[0..prefix.len], prefix)) {
        std.fmt.format(stderr,
            \\ Error: input does not start with prefix:
            \\    input: "{s}"
            \\   prefix: "{s}"
        , .{ input, prefix }) catch void{};
        unreachable;
    }
    return input[prefix.len..input.len];
}

fn Vec2D(comptime T: type) type {
    return struct {
        const Self = @This();
        i: T,
        j: T,

        fn init(i: T, j: T) Self {
            return .{ .i = i, .j = j };
        }
        fn set(v: T) Self {
            return .{ .i = v, .j = v };
        }

        fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i + rhs.i, lhs.j + rhs.j);
        }
        fn sub(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i - rhs.i, lhs.j - rhs.j);
        }
        fn min(lhs: Self, rhs: Self) Self {
            return Self.init(@minimum(lhs.i, rhs.i), @minimum(lhs.j, rhs.j));
        }
        fn max(lhs: Self, rhs: Self) Self {
            return Self.init(@maximum(lhs.i, rhs.i), @maximum(lhs.j, rhs.j));
        }
        fn eq(lhs: Self, rhs: Self) bool {
            return lhs.i == rhs.i and lhs.j == rhs.j;
        }

        fn as(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @as(U, self.i), .j = @as(U, self.j) };
        }
        fn cast(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @intCast(U, self.i), .j = @intCast(U, self.j) };
        }

        fn l1(self: Self) T {
            var i = std.math.absInt(self.i) catch unreachable;
            var j = std.math.absInt(self.j) catch unreachable;
            return i + j;
        }
    };
}
fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        rows: []const []T,

        fn init(allocator: std.mem.Allocator, n: usize) !Self {
            const data = try allocator.alloc(T, n * n);
            errdefer allocator.free(data);
            const grid = try allocator.alloc([]T, n);
            errdefer allocator.free(grid);

            for (grid) |*row, i| {
                row.* = data[(i * n)..(i * n + n)];
            }

            return Self{ .rows = grid };
        }

        fn deinit(self: Self, allocator: std.mem.Allocator) void {
            var n = self.rows.len;
            var data = @ptrCast([*]T, self.rows[0])[0..(n * n)];
            allocator.free(data);
            allocator.free(self.rows);
        }

        fn print(self: Self, out: anytype) !void {
            for (self.rows) |row| {
                try std.fmt.format(out, "{s}\n", .{row});
            }
        }

        fn at(self: Self, pos: anytype) ?*T {
            if (pos.i < 0 or pos.i >= self.rows.len) {
                return null;
            }
            var row = self.rows[@intCast(usize, pos.i)];
            if (pos.j < 0 or pos.j >= row.len) {
                return null;
            }
            return &row[@intCast(usize, pos.j)];
        }

        fn fill(self: Self, val: T) void {
            for (self.rows) |row| {
                for (row) |*cell| {
                    cell.* = val;
                }
            }
        }
    };
}
