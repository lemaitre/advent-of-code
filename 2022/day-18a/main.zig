const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

//const N = 20;
//const Int = i6;
//
//fn at(shape: [N][N][N]bool, x: anytype, y: anytype, z: anytype) ?bool {
//    if (x < 0 or y < 0 or z < 0 or x >= N or y >= N or z >= N) {
//        return null;
//    }
//    return shape[@intCast(usize, x)][@intCast(usize, y)][@intCast(usize, z)];
//}
//
//
//pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
//    var shape = [1][N][N]bool{[1][N]bool{[1]bool{false} ** N} ** N} ** N;
//
//    var lines = std.mem.tokenize(u8, input, "\n");
//    while (lines.next()) |line| {
//        var tokens = std.mem.tokenize(u8, line, ",");
//        var x = try std.fmt.parseInt(u5, tokens.next().?, 10);
//        var y = try std.fmt.parseInt(u5, tokens.next().?, 10);
//        var z = try std.fmt.parseInt(u5, tokens.next().?, 10);
//        assert(tokens.next() == null);
//
//        shape[x][y][z] = true;
//    }
//
//    var surface: u32 = 0;
//
//    for (range(N)) |_, X| {
//        for (range(N)) |_, Y| {
//            for (range(N)) |_, Z| {
//                if (!at(shape, X, Y, Z).?) {
//                    continue;
//                }
//
//                var s: u32 = 6;
//
//                for (@as([2]i2, .{ -1, 1 })) |dx| {
//                    for (@as([2]i2, .{ -1, 1 })) |dy| {
//                        for (@as([2]i2, .{ -1, 1 })) |dz| {
//                            var x = @intCast(Int, X) + dx;
//                            var y = @intCast(Int, Y) + dy;
//                            var z = @intCast(Int, Z) + dz;
//                            if (at(shape, x, y, z)) |cell| {
//                                s -= @boolToInt(cell);
//                            }
//                        }
//                    }
//                }
//
//                surface += s;
//            }
//        }
//    }
//
//    try std.fmt.format(stdout, "surface: {}\n", .{surface});
//    _ = allocator;
//}

const Neighborhood = [_][3]i2{
    .{ -1, 0, 0 },
    .{ 1, 0, 0 },
    .{ 0, -1, 0 },
    .{ 0, 1, 0 },
    .{ 0, 0, -1 },
    .{ 0, 0, 1 },
};

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    const Vec3 = [3]i8;
    var shape = std.AutoHashMap(Vec3, void).init(allocator);
    defer shape.deinit();

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        var tokens = std.mem.tokenize(u8, line, ",");
        var x = try std.fmt.parseInt(i8, tokens.next().?, 10);
        var y = try std.fmt.parseInt(i8, tokens.next().?, 10);
        var z = try std.fmt.parseInt(i8, tokens.next().?, 10);

        assert(tokens.next() == null);
        try shape.put(.{ x, y, z }, .{});
    }

    var surface: u32 = 0;

    var it = shape.keyIterator();
    while (it.next()) |cell| {
        var s: u32 = 6;
        for (Neighborhood) |neighbor| {
            if (shape.get(.{ cell[0] + neighbor[0], cell[1] + neighbor[1], cell[2] + neighbor[2] })) |_| {
                s -= 1;
            }
        }

        surface += s;
    }

    try std.fmt.format(stdout, "surface: {}\n", .{surface});
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
