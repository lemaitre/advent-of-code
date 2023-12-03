const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

const Vec2D = struct {
    x: i32 = 0,
    y: i32 = 0,
    
    fn init(x: i32, y: i32) Vec2D {
        return .{ .x = x, .y = y };
    }
    fn add(lhs: Vec2D, rhs: Vec2D) Vec2D {
        return .{ .x = lhs.x + rhs.x, .y = lhs.y + rhs.y };
    }
    fn sub(lhs: Vec2D, rhs: Vec2D) Vec2D {
        return .{ .x = lhs.x - rhs.x, .y = lhs.y - rhs.y };
    }
    fn max(lhs: Vec2D, rhs: Vec2D) Vec2D {
        return .{ .x = @maximum(lhs.x, rhs.x), .y = @maximum(lhs.y, rhs.y) };
    }
    fn min(lhs: Vec2D, rhs: Vec2D) Vec2D {
        return .{ .x = @minimum(lhs.x, rhs.x), .y = @minimum(lhs.y, rhs.y) };
    }
    fn eql(lhs: Vec2D, rhs: Vec2D) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }
};

const moves = blk: {
    var LUT = [1]Vec2D{undefined} ** 256;
    LUT['L'] = Vec2D.init( 0, -1);
    LUT['R'] = Vec2D.init( 0,  1);
    LUT['U'] = Vec2D.init(-1,  0);
    LUT['D'] = Vec2D.init( 1,  0);
    break :blk LUT;
};

fn Rope(comptime n: comptime_int) type {
    return struct {
        const Self = @This();

        knots: [n]Vec2D = [1]Vec2D{.{}} ** n,

        fn tail(self: Self) Vec2D {
            return self.knots[n-1];
        }

        fn moveHead(self: *Self, move: Vec2D) void {
            var prev = &self.knots[0];
            prev.* = prev.add(move);
            for (self.knots[1..n]) |*knot| {
                var diff = prev.sub(knot.*);
                var tailMove = diff.max(Vec2D.init(-1, -1)).min(Vec2D.init(1, 1));
                if (diff.eql(tailMove)) {
                    return;
                }
                knot.* = knot.add(tailMove);
                prev = knot;
            }
        }
    };
}

fn gridAlloc(allocator: std.mem.Allocator, n: usize) ![]const[]u8 {
    const data = try allocator.alloc(u8, n*n);
    errdefer allocator.free(data);
    const grid = try allocator.alloc([]u8, n);
    errdefer allocator.free(grid);

    for (grid) |*row, i| {
        row.* = data[(i*n)..(i*n+n)];
    }

    return grid;
}
fn gridFree(allocator: std.mem.Allocator, grid: []const[]u8) void {
    var n = grid.len;
    var data = @ptrCast([*]u8, grid[0])[0..(n*n)];
    allocator.free(data);
    allocator.free(grid);
}

fn gridPrint(out: anytype, grid: []const[]const u8) !void {
    for (grid) |row| {
        try std.fmt.format(out, "{s}\n", .{row});
    }
}


pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    const N = 300;
    var grid = try gridAlloc(allocator, 2*N);
    defer gridFree(allocator, grid);

    for (grid) |row| {
        for (row) |*cell| {
            cell.* = '0';
        }
    }

    var lines = std.mem.tokenize(u8, input, "\n");

    var rope = Rope(10){};

    while (lines.next()) |line| {
        var tokens = [1][]const u8{undefined} ** 2;
        try iterIntoExact(&std.mem.tokenize(u8, line, " "), &tokens);
        assert(tokens[0].len == 1);
        var dir = moves[tokens[0][0]];
        var n = try std.fmt.parseInt(u32, tokens[1], 0);

        for (range(n)) |_| {
            rope.moveHead(dir);
            var tail = rope.tail();
            grid[@intCast(u32, tail.x + N)][@intCast(u32, tail.y + N)] += 1;
        }
    }

    try gridPrint(stdout, grid);

    var count : u32 = 0;
    for (grid) |row| {
        for (row) |cell| {
            if (cell > '0') {
                count += 1;
            }
        }
    }

    try std.fmt.format(stdout, "count: {}\n", .{count});
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
