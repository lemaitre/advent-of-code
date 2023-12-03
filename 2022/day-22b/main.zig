const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Int = u8;

const Pos = struct {
    x: Int = 0,
    y: Int = 0,
    dir: u2 = 0,

    fn parseDir(c: u8) u2 {
        return switch (c) {
            '>' => 0,
            'v' => 1,
            '<' => 2,
            '^' => 3,
            else => unreachable,
        };
    }

    fn format(self: Pos, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;
        const c = [1]u8{">v<^"[self.dir]};
        try std.fmt.format(writer, "({}, {}, {})", .{ self.x, self.y, &c });
    }

    fn turn(self: Pos, c: u8) Pos {
        return .{
            .x = self.x,
            .y = self.y,
            .dir = switch (c) {
                'L', 'l' => self.dir -% 1,
                'R', 'r' => self.dir +% 1,
                else => unreachable,
            },
        };
    }

    fn advance(self: Pos) Pos {
        const Moves = [_][2]Int{
            .{ 1, 0 },
            .{ 0, 1 },
            .{ -%@as(Int, 1), 0 },
            .{ 0, -%@as(Int, 1) },
        };

        var dx = Moves[self.dir][0];
        var dy = Moves[self.dir][1];

        return .{
            .x = self.x +% dx,
            .y = self.y +% dy,
            .dir = self.dir,
        };
    }

    fn toVec(self: Pos) Vec2D(Int) {
        return .{
            .i = self.y,
            .j = self.x,
        };
    }
};

const Map = struct {
    allocator: std.mem.Allocator,
    cells: std.AutoHashMapUnmanaged(Vec2D(Int), bool) = .{},
    row_start: std.ArrayListUnmanaged(Int) = .{},
    row_end: std.ArrayListUnmanaged(Int) = .{},
    col_start: std.ArrayListUnmanaged(Int) = .{},
    col_end: std.ArrayListUnmanaged(Int) = .{},

    fn init(allocator: std.mem.Allocator) Map {
        return .{ .allocator = allocator };
    }

    fn deinit(self: *Map) void {
        self.cells.deinit(self.allocator);
        self.row_start.deinit(self.allocator);
        self.row_end.deinit(self.allocator);
        self.col_start.deinit(self.allocator);
        self.col_end.deinit(self.allocator);
    }

    fn addRow(self: *Map, row: []const u8) !void {
        assert(self.row_start.items.len == self.row_end.items.len);
        assert(self.col_start.items.len == self.col_end.items.len);
        { // resize col ctart/end
            var prev_width = self.col_start.items.len;
            var new_width = @maximum(row.len, prev_width);
            try self.col_start.resize(self.allocator, new_width);
            try self.col_end.resize(self.allocator, new_width);
            var x = prev_width;
            while (x < new_width) : (x += 1) {
                self.col_start.items[x] = std.math.maxInt(Int);
                self.col_end.items[x] = std.math.minInt(Int);
            }
        }
        var y = @intCast(Int, self.row_start.items.len);

        var i: Int = 0;
        while (row[i] == ' ') {
            i += 1;
        }

        var j: Int = i;
        while (j < row.len and row[j] != ' ') {
            j += 1;
        }

        try self.row_start.append(self.allocator, @intCast(Int, i));
        try self.row_end.append(self.allocator, @intCast(Int, j - 1));

        var x = i;
        while (x < j) : (x += 1) {
            self.col_start.items[x] = @minimum(self.col_start.items[x], y);
            self.col_end.items[x] = @maximum(self.col_end.items[x], y);
            var wall = row[x] == '#';
            try self.cells.put(self.allocator, (Pos{ .x = x, .y = y }).toVec(), wall);
        }
    }

    fn width(self: Map) usize {
        return self.col_start.items.len;
    }
    fn height(self: Map) usize {
        return self.row_start.items.len;
    }

    fn advanceOne(self: Map, pos: Pos) ?Pos {
        var new_pos = pos.advance();
        var wall: bool = undefined;
        if (self.cells.get(new_pos.toVec())) |cell| {
            wall = cell;
        } else {
            new_pos = switch (pos.dir) {
                0 => .{
                    .x = self.row_start.items[@intCast(usize, pos.y)],
                    .y = pos.y,
                    .dir = pos.dir,
                },
                1 => .{
                    .x = pos.x,
                    .y = self.col_start.items[@intCast(usize, pos.x)],
                    .dir = pos.dir,
                },
                2 => .{
                    .x = self.row_end.items[@intCast(usize, pos.y)],
                    .y = pos.y,
                    .dir = pos.dir,
                },
                3 => .{
                    .x = pos.x,
                    .y = self.col_end.items[@intCast(usize, pos.x)],
                    .dir = pos.dir,
                },
            };

            wall = self.cells.get(new_pos.toVec()).?;
        }

        if (wall) {
            return null;
        } else {
            return new_pos;
        }
    }

    fn advance(self: Map, pos: Pos, n: u32) Pos {
        var cur = pos;
        for (range(n)) |_| {
            if (self.advanceOne(cur)) |new_pos| {
                cur = new_pos;
            } else {
                break;
            }
        }
        return cur;
    }
};

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var map = Map.init(allocator);
    defer map.deinit();

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }

        try map.addRow(line);
    }

    var rest = lines.next().?;
    var pos = Pos{
        .x = map.row_start.items[0],
    };

    while (rest.len > 0) {
        var idx: usize = rest.len;
        if (std.mem.indexOfAny(u8, rest, "LR")) |i| {
            idx = i;
        }
        if (idx > 0) {
            var n = try std.fmt.parseInt(Int, rest[0..idx], 10);
            pos = map.advance(pos, n);
        }
        if (idx < rest.len) {
            pos = pos.turn(rest[idx]);
            idx += 1;
        }
        rest = rest[idx..rest.len];
    }

    try std.fmt.format(stdout, "Final pos: {}\n{}\n", .{ pos, 1000 * @as(u32, pos.y + 1) + 4 * @as(u32, pos.x + 1) + pos.dir });
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
