const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Element = struct {
    val: i64,
    order: u64,
};

fn move(data: []Element, i: usize, n: isize) void {
    var j: usize = @intCast(usize, @mod(@intCast(isize, i) + n, @intCast(isize, data.len - 1)));
    if (j == 0 and i != j) {
        j = data.len - 1;
    }
    var val = data[i];
    if (i < j) {
        std.mem.copy(Element, data[i..j], data[(i + 1)..(j + 1)]);
    } else if (j < i) {
        std.mem.copyBackwards(Element, data[(j + 1)..(i + 1)], data[j..i]);
    }
    data[j] = val;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var data = std.ArrayList(Element).init(allocator);
    defer data.deinit();

    const key = 811589153;

    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        try data.append(.{
            .val = key * try std.fmt.parseInt(i64, line, 10),
            .order = data.items.len,
        });
    }

    for (range(10)) |_| {
        for (data.items) |_, i| {
            for (data.items) |el, j| {
                if (el.order != i) {
                    continue;
                }
                move(data.items, j, el.val);
                break;
            }
        }
    }

    var i: usize = 0;
    while (i < data.items.len) : (i += 1) {
        if (data.items[i].val == 0) {
            break;
        }
    }

    var a = data.items[(i + 1000) % data.items.len].val;
    var b = data.items[(i + 2000) % data.items.len].val;
    var c = data.items[(i + 3000) % data.items.len].val;

    try std.fmt.format(stdout, "a: {}  b: {}  c: {}  sum: {}\n", .{ a, b, c, a + b + c });
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
