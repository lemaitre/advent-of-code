const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const ResourceType = .{
    .ore = 0,
    .clay = 1,
    .obsidian = 2,
    .geode = 3,
};

fn State(comptime T: type) type {
    return struct {
        resources: @Vector(4, T),
        robots: @Vector(4, T),
        remaining_time: T,
    };
}

fn Blueprint(comptime T: type) type {
    return [4]@Vector(4, T);
}

const Int = u16;

fn Simulator(comptime T: type) type {
    return struct {
        const Self = @This();

        blueprint: Blueprint(T),
        seen: std.AutoHashMap(State(T), void),
        max_robots: @Vector(4, T),
        max_geode: T = 0,

        fn init(allocator: std.mem.Allocator, blueprint: Blueprint(T)) Self {
            var max_robots = @Vector(4, T){ 0, 0, 0, 9999 };
            for (range(4)) |_, resource_type| {
                var robot = blueprint[resource_type];
                max_robots = @select(T, max_robots > robot, max_robots, robot);
            }
            return .{
                .blueprint = blueprint,
                .seen = std.AutoHashMap(State(T), void).init(allocator),
                .max_robots = max_robots,
            };
        }

        fn deinit(self: *Self) void {
            self.seen.deinit();
        }

        fn simulate(self: *Self, state: State(T)) std.mem.Allocator.Error!void {
            var geode_upper_bound = state.resources[3] + (state.robots[3] + (state.remaining_time - 1) / 2) * state.remaining_time;
            if (geode_upper_bound < self.max_geode) {
                return;
            }

            var is_useful = state.robots < self.max_robots;
            _ = is_useful;
            var built: bool = false;
            for (range(4)) |_, res_type| {
                var candidate = self.blueprint[res_type];

                if (!is_useful[res_type]) {
                    continue;
                }

                var wait = @splat(4, @as(T, 1));
                inline for (.{ 0, 1, 2, 3 }) |i| {
                    if (candidate[i] > state.resources[i]) {
                        if (state.robots[i] == 0) {
                            wait[i] = state.remaining_time + 1;
                        } else {
                            var needed = candidate[i] - state.resources[i];
                            wait[i] = @maximum(wait[i], 1 + (needed + state.robots[i] - 1) / state.robots[i]);
                        }
                    }
                }

                var n = @reduce(.Max, wait);
                if (n > state.remaining_time) {
                    continue;
                }

                const Robots = [4]@Vector(4, T){
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 0, 0, 0, 1 },
                };
                var new_robot = Robots[res_type];

                try self.simulate(.{
                    .resources = state.resources - candidate + state.robots * @splat(4, n),
                    .robots = state.robots + new_robot,
                    .remaining_time = state.remaining_time - n,
                });

                built = true;
            }

            if (!built) {
                self.max_geode = @maximum(self.max_geode, state.resources[3] + state.remaining_time * state.robots[3]);
            }
        }
    };
}

pub fn process(allocator: std.mem.Allocator, input: []const u8, n: u16) !void {
    var lines = std.mem.tokenize(u8, input, "\n");

    var prod: u64 = 1;

    var i: u32 = 1;
    while (lines.next()) |line| {
        if (i > 3) {
            break;
        }
        var tokens = std.mem.tokenize(u8, line, " ");

        var blueprint: Blueprint(u16) = [1]@Vector(4, u16){.{ 0, 0, 0, 0 }} ** 4;

        _ = tokens.next().?; // Blueprint
        _ = tokens.next().?; // X:
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint[0][0] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // clay
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint[1][0] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // obsidian
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint[2][0] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // and
        blueprint[2][1] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // clay.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // geode
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint[3][0] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // and
        blueprint[3][2] = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // obsidian.
        assert(tokens.next() == null);

        var simulator = Simulator(u16).init(allocator, blueprint);
        defer simulator.deinit();

        try simulator.simulate(.{
            .resources = .{ 0, 0, 0, 0 },
            .robots = .{ 1, 0, 0, 0 },
            .remaining_time = n,
        });

        try std.fmt.format(stdout, "Blueprint {}: {} geodes\n", .{ i, simulator.max_geode });
        i += 1;

        prod *= simulator.max_geode;
    }

    try std.fmt.format(stdout, "Total score: {}\n", .{prod});
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

    var n = try std.fmt.parseInt(u16, arg_it.next(allocator) orelse "24" catch "24", 10);

    var timer = try std.time.Timer.start();
    try process(allocator, input, n);
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
