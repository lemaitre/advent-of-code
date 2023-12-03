const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const SensorRead = struct {
    sensor: Vec2D(i32),
    beacon: Vec2D(i32),

    fn distance(self: SensorRead) i32 {
        return self.beacon.sub(self.sensor).l1();
    }
};

fn Interval(comptime T: type) type {
    return struct {
        const Self = @This();
        low: T,
        high: T,

        fn init(low: T, high: T) Self {
            assert(low <= high);
            return .{ .low = low, .high = high };
        }

        fn contains(self: Self, val: T) bool {
            return self.low <= val and val <= self.high;
        }

        fn merge(I1: Self, I2: Self) !Self {
            if (I2.high + 1 < I1.low) {
                return error.DisjointLower;
            }
            if (I1.high + 1 < I2.low) {
                return error.DisjointHigher;
            }

            return Self.init(@minimum(I1.low, I2.low), @maximum(I1.high, I2.high));
        }

        fn intersect(I1: Self, I2: Self) !Self {
            if (I2.high + 1 < I1.low) {
                return error.DisjointLower;
            }
            if (I1.high + 1 < I2.low) {
                return error.DisjointHigher;
            }

            return Self.init(@maximum(I1.low, I2.low), @minimum(I1.high, I2.high));
        }

        fn splitLeft(self: Self, val: T) [2]Self {
            assert(self.low <= val and val < self.high);
            return .{ Self.init(self.low, val), Self.init(val+1, self.high) };
        }
        fn splitRight(self: Self, val: T) [2]Self {
            assert(self.low < val and val <= self.high);
            return .{ Self.init(self.low, val-1), Self.init(val, self.high) };
        }
        fn splitInclude(self: Self, val: T) [2]Self {
            assert(self.low <= val and val <= self.high);
            return .{ Self.init(self.low, val), Self.init(val, self.high) };
        }
        fn splitExclude(self: Self, val: T) [2]Self {
            assert(self.low < val and val < self.high);
            return .{ Self.init(self.low, val-1), Self.init(val+1, self.high) };
        }
    };
}

fn Intervals(comptime T: type) type {
    return struct {
        const Self = @This();
        const Atom = Interval(T);

        atoms: std.ArrayList(Atom),

        fn init(allocator: std.mem.Allocator) Self {
            return .{ .atoms = std.ArrayList(Atom).init(allocator) };
        }
        fn deinit(self: *Self) void {
            self.atoms.deinit();
        }
        fn add(self: *Self, interval: Atom) !void {
            var int = interval;
            var n = self.atoms.items.len;
            var i : u32 = 0;
            var j : u32 = 0;

            while (j < n) {
                if (int.merge(self.atoms.items[j])) |merged| {
                    int = merged;
                    j += 1;
                } else |err| switch (err) {
                    error.DisjointLower => {
                        assert(i == j);
                        i += 1;
                        j += 1;
                    },
                    error.DisjointHigher => {
                        break;
                    },
                }
            }
            try self.atoms.replaceRange(i, j-i, &([1]Atom){int});
        }

        fn merge(I1: Self, I2: Self) !Self {
            var n1 = I1.atoms.items.len;
            var n2 = I2.atoms.items.len;

            var result = Self.init(I1.allocator);
            errdefer result.deinit();

            // If either is empty, the merge is the clone of the other
            if (n1 == 0) {
                try result.appendSlice(I2.atoms.items);
                return result;
            }
            if (n2 == 0) {
                try result.appendSlice(I1.atoms.items);
                return result;
            }

            var int1 = I1.atoms.items[0];
            var int2 = I2.atoms.items[0];

            var j1 : u32 = 0;
            var j2 : u32 = 0;

            while (true) {
                if (int1.merge(int2)) |merged| {
                    if (int1.high < int2.high) {
                        int2 = merged;
                        j1 += 1;
                        if (j1 < n1) {
                            int1 = I1.atoms.items[j1];
                        } else {
                            break;
                        }
                    } else {
                        int1 = merged;
                        j2 += 1;
                        if (j2 < n2) {
                            int2 = I2.atoms.items[j2];
                        } else {
                            break;
                        }
                    }
                } else |err| switch (err) {
                    error.DisjointLower => {
                        try result.append(int1);
                        j1 += 1;
                        if (j1 < n1) {
                            int1 = I1.atoms.items[j1];
                        } else {
                            break;
                        }
                    },
                    error.DisjointHigher => {
                        try result.append(int2);
                        j2 += 1;
                        if (j2 < n2) {
                            int2 = I2.atoms.items[j2];
                        } else {
                            break;
                        }
                    },
                }
            }

            if (j1 < n1) {
                try result.append(int1);
                try result.appendSlice(I1.atoms.items[(j1+1)..n1]);
            }
            if (j2 < n2) {
                try result.append(int2);
                try result.appendSlice(I2.atoms.items[(j2+1)..n2]);
            }

            return result;
        }

        fn intersect(I1: Self, I2: Self) !Self {
            var n1 = I1.atoms.items.len;
            var n2 = I2.atoms.items.len;

            var result = Self.init(I1.allocator);
            errdefer result.deinit();

            // If either is empty, the intersect is also empty
            if (n1 == 0 or n2 == 0) {
                return result;
            }

            var int1 = I1.atoms.items[0];
            var int2 = I2.atoms.items[0];

            var j1 : u32 = 0;
            var j2 : u32 = 0;

            while (true) {
                if (int1.intersect(int2)) |inter| {
                    try result.append(inter);
                    if (int1.high < int2.high) {
                        j1 += 1;
                        if (j1 < n1) {
                            int1 = I1.atoms.items[j1];
                        } else {
                            break;
                        }
                    } else {
                        j2 += 1;
                        if (j2 < n2) {
                            int2 = I2.atoms.items[j2];
                        } else {
                            break;
                        }
                    }
                } else |err| switch (err) {
                    error.DisjointLower => {
                        j1 += 1;
                        if (j1 < n1) {
                            int1 = I1.atoms.items[j1];
                        } else {
                            break;
                        }
                    },
                    error.DisjointHigher => {
                        j2 += 1;
                        if (j2 < n2) {
                            int2 = I2.atoms.items[j2];
                        } else {
                            break;
                        }
                    },
                }
            }

            return result;
        }
    };
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var sensorReads = std.ArrayList(SensorRead).init(allocator);
    defer sensorReads.deinit();
    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var points : [2][]const u8 = undefined;
        try iterIntoExact(&std.mem.split(u8, removePrefix(line, "Sensor at "), ": closest beacon is at "), &points);

        var vecs : [2]Vec2D(i32) = undefined;
        for (range(2)) |_, i| {
            var coords : [2][]const u8 = undefined;
            try iterIntoExact(&std.mem.split(u8, removePrefix(points[i], "x="), ", y="), &coords);
            var x = try std.fmt.parseInt(i32, coords[0], 10);
            var y = try std.fmt.parseInt(i32, coords[1], 10);

            vecs[i] = Vec2D(i32).init(y, x);
        }

        try sensorReads.append(.{ .sensor = vecs[0], .beacon = vecs[1] });
    }

    const n = 4000000;
    var pos : Vec2D(i32) = undefined;
    outer: for (range(n)) |_, i| {
        var ints = Intervals(i32).init(allocator);
        defer ints.deinit();

        for (sensorReads.items) |read| {
            var distance = read.distance();
            var rowDistance = std.math.absInt(read.sensor.i - @intCast(i32, i)) catch unreachable;
            if (distance < rowDistance) {
                continue;
            }

            var j = read.sensor.j;
            var w = distance - rowDistance;
            try ints.add(Interval(i32).init(j - w, j + w));
        }

        for (ints.atoms.items) |int| {
            if (int.high >= 0 and int.high < n) {
                pos = Vec2D(i32).init(@intCast(i32, i), int.high+1);
                break :outer;
            }
        }
    }

    try std.fmt.format(stdout, "{}:{} -> {}\n", .{pos.i, pos.j, pos.cast(i64).j * 4000000 + pos.cast(i64).i});
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
