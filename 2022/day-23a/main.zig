const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Dir = enum(u2) {
    north = 0,
    east = 1,
    south = 2,
    west = 3,

    fn parse(c: u8) Dir {
        return switch (c) {
            '^', 'n', 'N', 'u', 'U' => Dir.north,
            '>', 'e', 'E', 'r', 'R' => Dir.east,
            'v', 's', 'S', 'd', 'D' => Dir.south,
            '<', 'w', 'W', 'l', 'L' => Dir.west,
            else => unreachable,
        };
    }

    fn reverse(dir: Dir) Dir {
        return switch (dir) {
            .north => .south,
            .east => .west,
            .south => .north,
            .west => .east,
        };
    }

    fn inFront(dir: Dir) [3]@Vector(2, i32) {
        return switch (dir) {
            .north => .{
                .{ 0, -1 },
                .{ -1, -1 },
                .{ 1, -1 },
            },
            .east => .{
                .{ 1, 0 },
                .{ 1, -1 },
                .{ 1, 1 },
            },
            .south => .{
                .{ 0, 1 },
                .{ -1, 1 },
                .{ 1, 1 },
            },
            .west => .{
                .{ -1, 0 },
                .{ -1, -1 },
                .{ -1, 1 },
            },
        };
    }

    fn around() [8]@Vector(2, i32) {
        return .{
            .{ -1, -1 },
            .{ -1, 0 },
            .{ -1, 1 },
            .{ 0, -1 },
            //.{0, 0}, // center is ignored
            .{ 0, 1 },
            .{ 1, -1 },
            .{ 1, 0 },
            .{ 1, 1 },
        };
    }

    fn format(self: Dir, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;
        var c = [1]u8{switch (self) {
            .north => 'N',
            .east => 'E',
            .south => 'S',
            .west => 'W',
        }};
        try std.fmt.format(writer, "{s}", .{&c});
    }
};

const Simulator = struct {
    const Self = @This();
    const ElfMap = std.AutoHashMap(@Vector(2, i32), @Vector(2, i32));

    maps: [2]ElfMap,
    iter: u32 = 0,
    order: [4]Dir = .{ .north, .south, .west, .east },

    fn init(allocator: std.mem.Allocator) Simulator {
        return .{
            .maps = .{ ElfMap.init(allocator), ElfMap.init(allocator) },
        };
    }

    fn deinit(self: *Self) void {
        self.maps[0].deinit();
        self.maps[1].deinit();
    }

    fn step(self: *Self) !void {
        var src = &self.maps[self.iter & 1];
        var dst = &self.maps[(self.iter + 1) & 1];
        assert(dst.count() == 0);
        var order: @TypeOf(self.order) = undefined;
        for (order) |*o, i| {
            o.* = self.order[(self.iter + i) % self.order.len];
        }

        defer {
            self.iter += 1;
            src.clearRetainingCapacity();
        }

        var src_iter = src.keyIterator();
        while (src_iter.next()) |pos| {
            var has_neighbor: bool = false;
            for (Dir.around()) |neighbor| {
                if (src.contains(pos.* + neighbor)) {
                    has_neighbor = true;
                }
            }
            var new_dir: ?Dir = null;
            if (has_neighbor) {
                dir_loop: for (order) |dir| {
                    for (dir.inFront()) |front| {
                        var new_pos = pos.* + front;
                        if (src.contains(new_pos)) {
                            continue :dir_loop;
                        }
                    }
                    new_dir = dir;
                    break;
                }
            }
            if (new_dir) |ndir| {
                var new_pos = pos.* + ndir.inFront()[0];

                var entry = try dst.getOrPut(new_pos);
                if (entry.found_existing) {
                    var old_pos = entry.value_ptr.*;
                    _ = dst.remove(new_pos);
                    assert(!@reduce(.And, old_pos == new_pos));
                    for ([2]@Vector(2, i32){ pos.*, old_pos }) |p| {
                        var e = try dst.getOrPut(p);
                        e.value_ptr.* = p;
                        assert(!e.found_existing);
                    }
                } else {
                    entry.value_ptr.* = pos.*;
                }
            } else {
                var entry = try dst.getOrPut(pos.*);
                entry.value_ptr.* = pos.*;
                assert(!entry.found_existing);
            }
        }
    }

    const Box = struct {
        min: @Vector(2, i32),
        max: @Vector(2, i32),
    };
    fn getBox(self: Self) Box {
        var iter = self.maps[self.iter & 1].keyIterator();
        var box = Box{ .min = @splat(2, @as(i32, std.math.maxInt(i32))), .max = @splat(2, @as(i32, std.math.minInt(i32))) };
        while (iter.next()) |pos| {
            box.min = @select(i32, pos.* < box.min, pos.*, box.min);
            box.max = @select(i32, pos.* > box.max, pos.*, box.max);
        }

        return box;
    }

    fn print(self: Self, out: anytype) !void {
        var box = self.getBox();
        var map = self.maps[self.iter & 1];

        var y = box.min[1];
        while (y <= box.max[1]) : (y += 1) {
            var x = box.min[0];
            while (x <= box.max[0]) : (x += 1) {
                var c = [1]u8{'.'};
                if (map.contains(.{ x, y })) {
                    c[0] = '#';
                }
                try std.fmt.format(out, "{s}", .{&c});
            }
            try std.fmt.format(out, "\n", .{});
        }
    }
};

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var simulator = Simulator.init(allocator);
    defer simulator.deinit();

    var lines = std.mem.tokenize(u8, input, "\n");

    var y: i32 = 0;
    while (lines.next()) |line| {
        for (line) |c, cx| {
            var x = @intCast(i32, cx);

            if (c == '#') {
                try simulator.maps[0].put(.{ x, y }, .{ x, y });
            }
        }
        y += 1;
    }

    var nelves = @intCast(i32, simulator.maps[0].count());

    try std.fmt.format(stdout, "Initial state:\n  box: {}\n", .{simulator.getBox()});
    try simulator.print(stdout);

    for (range(10)) |_, i| {
        try simulator.step();
        try std.fmt.format(stdout, "End of Round {}: {}\n", .{ i + 1, simulator.getBox() });
        try simulator.print(stdout);
    }

    var box = simulator.getBox();
    var dims = box.max - box.min + @splat(2, @as(i32, 1));

    try std.fmt.format(stdout, "{}\nempty tiles: {}\n", .{ box, dims[0] * dims[1] - nelves });
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
        x: T,
        y: T,

        fn init(x: T, y: T) Self {
            return .{ .x = x, .y = y };
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
