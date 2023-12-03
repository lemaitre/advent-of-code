const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Rock = struct {
    const Int = u3;
    const N: Int = 4;
    shape: [N][N]bool,
    width: Int,
    height: Int,

    fn init(shape: [N][N]bool) Rock {
        var height: Int = N;
        for (crange(N)) |_, y| {
            var empty = true;
            for (crange(N)) |_, x| {
                empty = empty and !shape[N - y - 1][x];
            }
            if (empty) {
                height -= 1;
            } else {
                break;
            }
        }
        var width: Int = N;
        for (crange(N)) |_, x| {
            var empty = true;
            for (crange(N)) |_, y| {
                empty = empty and !shape[y][N - x - 1];
            }
            if (empty) {
                width -= 1;
            } else {
                break;
            }
        }

        var reversed: @TypeOf(shape) = [1][N]bool{[1]bool{false} ** N} ** N;
        for (range(height)) |_, y| {
            reversed[y] = shape[height - y - 1];
        }

        return .{
            .shape = reversed,
            .width = width,
            .height = height,
        };
    }

    fn print(self: Rock, out: anytype) !void {
        try std.fmt.format(out, "width: {}, height: {}\n", .{ self.width, self.height });
        for (self.shape) |row| {
            try std.fmt.format(out, "  ", .{});
            for (row) |cell| {
                if (cell) {
                    try std.fmt.format(out, "#", .{});
                } else {
                    try std.fmt.format(out, ".", .{});
                }
            }
            try std.fmt.format(out, "\n", .{});
        }
    }
};

const Chamber = struct {
    const Width = 7;
    const Row = [Width]u8;
    const Xoffset = 2;
    const Yoffset = 3;

    rows: std.ArrayList(Row),
    height: u32 = 0,
    char: u8 = '0',

    fn init(allocator: std.mem.Allocator) Chamber {
        return .{ .rows = std.ArrayList(Row).init(allocator) };
    }
    fn deinit(self: *Chamber) void {
        return self.rows.deinit();
    }

    fn print(self: Chamber, out: anytype) !void {
        for (range(self.height + Yoffset)) |_, y| {
            var h = self.height + Yoffset - y;
            try std.fmt.format(out, "{:5} |{s}|\n", .{ h, self.rows.items[h - 1] });
        }
        try std.fmt.format(out, "{:5} +{s}+\n", .{ 0, [1]u8{'-'} ** Width });
    }

    fn rockSettle(self: *Chamber, rock: Rock, X: i32, Y: i32) void {
        for (rock.shape) |row, y| {
            for (row) |cell, x| {
                if (cell) {
                    self.rows.items[@intCast(usize, Y) + y][@intCast(usize, X) + x] = self.char;
                }
            }
        }
    }
    fn rockTest(self: *Chamber, rock: Rock, X: i32, Y: i32) bool {
        if (X < 0 or X + rock.width > Width or Y < 0) {
            return false;
        }
        for (rock.shape) |row, y| {
            for (row) |cell, x| {
                if (cell) {
                    if (self.rows.items[@intCast(usize, Y) + y][@intCast(usize, X) + x] != '.') {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    fn printStep(self: Chamber, out: anytype, rock: Rock, X: i32, Y: i32) !void {
        var rows = std.ArrayList(Row).init(self.rows.allocator);
        defer rows.deinit();
        for (self.rows.items) |row| {
            try rows.append(row);
        }
        var copy = Chamber{
            .rows = rows,
            .height = self.height + rock.height,
            .char = '#',
        };

        copy.rockSettle(rock, X, Y);
        try copy.print(out);
    }

    fn fall(self: *Chamber, rock: Rock, stream: []const u8, idx: *u16) !void {
        var x: i32 = Xoffset;
        var y: i32 = @intCast(i32, self.height) + Yoffset;

        var old_height = self.rows.items.len;
        try self.rows.resize(@intCast(usize, y + Rock.N));
        for (self.rows.items[old_height..self.rows.items.len]) |*row| {
            std.mem.set(u8, row, '.');
        }

        while (true) {
            if (stream[idx.*] == '<') {
                if (self.rockTest(rock, x - 1, y)) {
                    x -= 1;
                }
            } else { // '>'
                if (self.rockTest(rock, x + 1, y)) {
                    x += 1;
                }
            }

            idx.* += 1;
            if (idx.* == stream.len) {
                idx.* = 0;
            }

            if (self.rockTest(rock, x, y - 1)) {
                y -= 1;
            } else {
                break;
            }
        }
        self.rockSettle(rock, x, y);
        self.height = @maximum(self.height, @intCast(u32, y) + rock.height);
        if (self.char == '9') {
            self.char = 'a';
        } else if (self.char == 'z') {
            self.char = '0';
        } else {
            self.char += 1;
        }
    }

    fn profile(self: Chamber) [Width]u32 {
        var depth = [1]u32{0} ** Width;
        for (depth) |*d, x| {
            var y: u31 = 0;
            while (y < self.height and self.rows.items[self.height - 1 - y][x] == '.') {
                y += 1;
            }
            d.* = y;
        }
        return depth;
    }

    const LoopDescriptor = struct {
        heights: std.ArrayList(u32),
        start: u32,
        end: u32,
    };

    fn findLoop(self: *Chamber, rocks: []Rock, streams: []const u8) !LoopDescriptor {
        const Key = struct {
            profile: [Width]u32,
            stream_idx: u16,
            rock_idx: u16,
        };
        var allocator = self.rows.allocator;
        var seen = std.AutoHashMap(Key, u32).init(allocator);
        defer seen.deinit();
        var heights = std.ArrayList(u32).init(allocator);
        errdefer heights.deinit();

        var idx: u32 = 0;
        var rock_idx: u16 = 0;
        var stream_idx: u16 = 0;

        while (true) {
            assert(heights.items.len == idx);
            { // try detect loop
                try heights.append(self.height);
                var entry = try seen.getOrPut(.{
                    .profile = self.profile(),
                    .stream_idx = stream_idx,
                    .rock_idx = rock_idx,
                });

                if (entry.found_existing) {
                    // Loop Detected: exit
                    return LoopDescriptor{
                        .heights = heights,
                        .start = entry.value_ptr.*,
                        .end = idx,
                    };
                } else {
                    entry.value_ptr.* = idx;
                }
            }
            idx += 1;

            try self.fall(rocks[rock_idx], streams, &stream_idx);
            rock_idx += 1;
            if (rock_idx == rocks.len) {
                rock_idx = 0;
            }
        }

        unreachable;
    }
};

pub fn process(allocator: std.mem.Allocator, input: []const u8, n: u64) !void {
    const streams = std.mem.trim(u8, input, " \n");

    var Rocks = [_]Rock{
        Rock.init(.{
            .{ true, true, true, true },
            .{ false, false, false, false },
            .{ false, false, false, false },
            .{ false, false, false, false },
        }),
        Rock.init(.{
            .{ false, true, false, false },
            .{ true, true, true, false },
            .{ false, true, false, false },
            .{ false, false, false, false },
        }),
        Rock.init(.{
            .{ false, false, true, false },
            .{ false, false, true, false },
            .{ true, true, true, false },
            .{ false, false, false, false },
        }),
        Rock.init(.{
            .{ true, false, false, false },
            .{ true, false, false, false },
            .{ true, false, false, false },
            .{ true, false, false, false },
        }),
        Rock.init(.{
            .{ true, true, false, false },
            .{ true, true, false, false },
            .{ false, false, false, false },
            .{ false, false, false, false },
        }),
    };

    var chamber = Chamber.init(allocator);
    defer chamber.deinit();

    try std.fmt.format(stdout, "{s}\n", .{streams});

    var loop = try chamber.findLoop(&Rocks, streams);
    defer loop.heights.deinit();
    try chamber.print(stdout);
    try std.fmt.format(stdout, "height: {}\n", .{chamber.height});

    _ = n;

    var t0: u64 = loop.start;
    var t1: u64 = loop.end;
    var h0: u64 = loop.heights.items[t0];
    var h1: u64 = loop.heights.items[t1];

    var d = t1 - t0;
    var h = h1 - h0;

    try std.fmt.format(stdout, "loop detected!\n  start: {} [{}]\n  end: {} [{}]\n  duration: {}\n  height: {}\n", .{ t0, h0, t1, h1, d, h });

    var height: u64 = undefined;
    if (n < t0) {
        height = loop.heights.items[n];
    } else {
        var quo = (n - t0) / d;
        var rem = (n - t0) % d;
        height = quo * h + loop.heights.items[t0 + rem];
    }

    try std.fmt.format(stdout, "height after {} rocks: {}\n", .{ n, height });
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
    var n = try std.fmt.parseInt(u64, arg_it.next(allocator) orelse "2022" catch "2022", 10);
    try process(allocator, input, n);
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
fn crange(comptime n: usize) [n]void {
    return [1]void{.{}} ** n;
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
