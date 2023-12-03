const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

fn printGrid(out: anytype, grid: []const[]const u8) !void {
    for (grid) |row| {
        try std.fmt.format(out, "{s}\n", .{row});
    }
}

fn addSand(rows: []const[]u8, orig: Vec2D(i32)) bool {
    var sand = orig;
    loop: while (0 <= sand.i and sand.i < rows.len-1 and 0 < sand.j and sand.j < rows[0].len-1) {
        for ([_]Vec2D(i32){Vec2D(i32).init(1, 0), Vec2D(i32).init(1, -1), Vec2D(i32).init(1, 1)}) |neighbor| {
            var candidate = sand.add(neighbor);
            var cell = rows[candidate.cast(u32).i][candidate.cast(u32).j];
            if (cell == '.' or cell == ' ') {
                sand = candidate;
                continue :loop;
            }
        }
        var cell = &rows[sand.cast(u32).i][sand.cast(u32).j];

        if (cell.* == '.' or cell.* == ' ' or cell.* == '+') {
            cell.* = 'o';
            return true;
        } else {
            return false;
        }
    }
    return false;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    const RockLine = std.ArrayList(Vec2D(i32));
    var rockLines = std.ArrayList(RockLine).init(allocator);
    defer {
        for (rockLines.items) |*line| {
            line.deinit();
        }
        rockLines.deinit();
    }

    var inputLines = std.mem.tokenize(u8, input, "\n");

    var max = Vec2D(i32).init(0, 0);
    var min = Vec2D(i32).init(10000, 10000);

    while (inputLines.next()) |inputLine| {
        var rockLine = RockLine.init(allocator);
        errdefer rockLine.deinit();

        var points = std.mem.tokenize(u8, inputLine, " -> ");
        while (points.next()) |point| {
            var coords : [2][]const u8 = undefined;
            try iterIntoExact(&std.mem.split(u8, point, ","), &coords);
            var x = try std.fmt.parseInt(i32, coords[0], 10);
            var y = try std.fmt.parseInt(i32, coords[1], 10);
            var vec = Vec2D(i32).init(y, x);
            max = max.max(vec);
            min = min.min(vec);
            try rockLine.append(vec);
        }

        try rockLines.append(rockLine);
    }

    max = max.add(Vec2D(i32).init(2, 200));
    min = min.sub(Vec2D(i32).init(1, 200));
    min.i = @minimum(min.i, 0);

    var width  = @intCast(u32, 1 + max.j - min.j);
    var height = @intCast(u32, 1 + max.i - min.i);
    var orig = Vec2D(i32).init(0, 500).sub(min);

    for (rockLines.items) |rockLine| {
        for (rockLine.items) |*vec| {
            vec.* = vec.sub(min);
        }
    }

    var rows = try allocator.alloc([]u8, height);
    defer allocator.free(rows);
    var data = try allocator.alloc(u8, width * height);
    defer allocator.free(data);
    for (rows) |*row, i| {
        row.* = data[(i * width)..(i*width+width)];
        for (row.*) |*cell| {
            cell.* = '.';
        }
    }

    for (rows[rows.len-1]) |*cell| {
        cell.* = '#';
    }

    try std.fmt.format(stdout, "{}:{} -> {}:{}\n", .{min.i, min.j, max.i, max.j});
    try std.fmt.format(stdout, "{}x{}\n", .{height, width});

    for (rockLines.items) |rockLine| {
        var last = rockLine.items[0];
        for (rockLine.items[1..rockLine.items.len]) |coords| {
            try std.fmt.format(stdout, "line: {}:{} -> {}:{}\n", .{last.i, last.j, coords.i, coords.j});
            var dir = coords.sub(last).min(Vec2D(i32).set(1)).max(Vec2D(i32).set(-1));
            var cur = last;
            while (!cur.eq(coords)) : (cur = cur.add(dir)) {
                rows[cur.cast(u32).i][cur.cast(u32).j] = '#';
            }
            last = coords;
        }
        rows[last.cast(u32).i][last.cast(u32).j] = '#';
    }

    try std.fmt.format(stdout, "orig: {}:{}\n", .{orig.i, orig.j});
    rows[orig.cast(u32).i][orig.cast(u32).j] = '+';

    try printGrid(stdout, rows);

    var count : u32 = 0;
    while (addSand(rows, orig)) {
        count += 1;
        try std.fmt.format(stdout, "\nsand #{}\n", .{count});
    }
    try printGrid(stdout, rows);
    try std.fmt.format(stdout, "\nsand #{}\n", .{count});
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
            , .{input, prefix}) catch void{};
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
    };
}
