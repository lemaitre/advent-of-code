const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();


const neighborhood = [_]Vec2D(i32){
    Vec2D(i32).init( 0,  1),
    Vec2D(i32).init( 0, -1),
    Vec2D(i32).init( 1,  0),
    Vec2D(i32).init(-1,  0),
};
fn explore(height_map: Grid(u8), distance_map: Grid(u16), pos: Vec2D(i32)) void {
    var h = height_map.at(pos).?.*;
    var d = distance_map.at(pos).?.*;
    for (neighborhood) |neighbor| {
        var npos = pos.add(neighbor);
        if (distance_map.at(npos)) |nd| {
            if (nd.* <= d + 1) {
                continue;
            }
            var nh = height_map.at(npos).?;
            if (nh.* > h+1) {
                continue;
            }

            nd.* = d + 1;
            explore(height_map, distance_map, npos);
        }
    }
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.tokenize(u8, input, "\n");
    var line_ = lines.next();

    var n = line_.?.len;

    var height_map = try Grid(u8).init(allocator, n);
    defer height_map.deinit(allocator);

    var distance_map = try Grid(u16).init(allocator, n);
    defer distance_map.deinit(allocator);

    height_map.fill(-%@as(u8, 1));
    distance_map.fill(-%@as(u16, 1));

    var start : Vec2D(i32) = undefined;
    var end : Vec2D(i32) = undefined;

    { var i : usize = 0;
        while (line_) |line| {
            try std.fmt.format(stdout, "line: {s}\n", .{line});
            line_ = lines.next();
            for (line) |c, j| {
                var pos = Vec2D(usize).init(i, j).cast(i32);
                var h : u8 = c;
                if (c == 'S') {
                    h = 'a';
                    start = pos;
                } else if (c == 'E') {
                    h = 'z';
                    end = pos;
                }
                height_map.at(pos).?.* = h;
            }
            i += 1;
        }
    }

    distance_map.at(start).?.* = 0;
    explore(height_map, distance_map, start);
    try std.fmt.format(stdout, "height\n", .{});
    try height_map.print(stdout);
    try std.fmt.format(stdout, "distance\n", .{});
    try distance_map.print(stdout);

    try std.fmt.format(stdout, "{}\n", .{distance_map.at(end).?.*});
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

        fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i + rhs.i, lhs.j + rhs.j);
        }
        fn sub(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i - rhs.i, lhs.j - rhs.j);
        }

        fn as(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @as(U, self.i), .j = @as(U, self.j) };
        }
        fn cast(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @intCast(U, self.i), .j = @intCast(U, self.j) };
        }
    };
}
fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        rows: []const[]T,

        fn init(allocator: std.mem.Allocator, n: usize) !Self {
            const data = try allocator.alloc(T, n*n);
            errdefer allocator.free(data);
            const grid = try allocator.alloc([]T, n);
            errdefer allocator.free(grid);

            for (grid) |*row, i| {
                row.* = data[(i*n)..(i*n+n)];
            }

            return Self{ .rows = grid };
        }

        fn deinit(self: Self, allocator: std.mem.Allocator) void {
            var n = self.rows.len;
            var data = @ptrCast([*]T, self.rows[0])[0..(n*n)];
            allocator.free(data);
            allocator.free(self.rows);
        }

        fn print(self: Self, out: anytype) !void {
            for (self.rows) |row| {
                try std.fmt.format(out, "{any}\n", .{row});
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
