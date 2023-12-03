const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const ResourceType = enum {
    ore,
    clay,
    obsidian,
    geode,
};

fn InnerState(comptime T: type) type {
    return struct {
        const Self = @This();
        ore: T,
        clay: T,
        obsidian: T,
        geode: T,

        fn add(lhs: anytype, rhs: anytype) Self {
            return .{
                .ore = lhs.ore + rhs.ore,
                .clay = lhs.clay + rhs.clay,
                .obsidian = lhs.obsidian + rhs.obsidian,
                .geode = lhs.geode + rhs.geode,
            };
        }

        fn sub(lhs: anytype, rhs: anytype) Self {
            return .{
                .ore = lhs.ore - rhs.ore,
                .clay = lhs.clay - rhs.clay,
                .obsidian = lhs.obsidian - rhs.obsidian,
                .geode = lhs.geode - rhs.geode,
            };
        }

        fn larger(lhs: anytype, rhs: anytype) bool {
            return lhs.ore >= rhs.ore and lhs.clay >= rhs.clay and lhs.obsidian >= rhs.obsidian and lhs.geode >= rhs.geode;
        }
    };
}

fn State(comptime T: type) type {
    return struct {
        resources: InnerState(T),
        robots: InnerState(T),
        remaining_time: T,
    };
}

fn Blueprint(comptime T: type) type {
    return InnerState(InnerState(T));
}

const Int = u16;

fn Simulator(comptime T: type) type {
    return struct {
        const Self = @This();

        blueprint: Blueprint(T),
        seen: std.AutoHashMap(State(T), void),
        max_geode: T = 0,

        fn init(allocator: std.mem.Allocator, blueprint: Blueprint(T)) Self {
            return .{
                .blueprint = blueprint,
                .seen = std.AutoHashMap(State(T), void).init(allocator),
            };
        }

        fn deinit(self: *Self) void {
            self.seen.deinit();
        }

        fn simulate(self: *Self, state: State(T)) std.mem.Allocator.Error!void {
            var geode_upper_bound = state.resources.geode + (state.robots.geode + state.remaining_time / 2) * state.remaining_time;
            if (geode_upper_bound < self.max_geode) {
                return;
            }
            if (state.remaining_time == 0) {
                self.max_geode = @maximum(self.max_geode, state.resources.geode);
                return;
            }

            var entry = try self.seen.getOrPut(state);
            if (entry.found_existing) {
                return;
            }

            for ([4]ResourceType{ .geode, .obsidian, .clay, .ore }) |res_type| {
                var candidate = switch (res_type) {
                    .ore => self.blueprint.ore,
                    .clay => self.blueprint.clay,
                    .obsidian => self.blueprint.obsidian,
                    .geode => self.blueprint.geode,
                };

                if (!state.resources.larger(candidate)) {
                    continue;
                }

                var new_robot = switch (res_type) {
                    .ore => InnerState(T){ .ore = 1, .clay = 0, .obsidian = 0, .geode = 0 },
                    .clay => InnerState(T){ .ore = 0, .clay = 1, .obsidian = 0, .geode = 0 },
                    .obsidian => InnerState(T){ .ore = 0, .clay = 0, .obsidian = 1, .geode = 0 },
                    .geode => InnerState(T){ .ore = 0, .clay = 0, .obsidian = 0, .geode = 1 },
                };

                try self.simulate(.{
                    .resources = state.resources.sub(candidate).add(state.robots),
                    .robots = state.robots.add(new_robot),
                    .remaining_time = state.remaining_time - 1,
                });
            }

            try self.simulate(.{
                .resources = state.resources.add(state.robots),
                .robots = state.robots,
                .remaining_time = state.remaining_time - 1,
            });
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

        var blueprint: Blueprint(u16) = .{
            .ore = .{ .ore = 0, .clay = 0, .obsidian = 0, .geode = 0 },
            .clay = .{ .ore = 0, .clay = 0, .obsidian = 0, .geode = 0 },
            .obsidian = .{ .ore = 0, .clay = 0, .obsidian = 0, .geode = 0 },
            .geode = .{ .ore = 0, .clay = 0, .obsidian = 0, .geode = 0 },
        };

        _ = tokens.next().?; // Blueprint
        _ = tokens.next().?; // X:
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint.ore.ore = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // clay
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint.clay.ore = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // obsidian
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint.obsidian.ore = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // and
        blueprint.obsidian.clay = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // clay.
        _ = tokens.next().?; // Each
        _ = tokens.next().?; // geode
        _ = tokens.next().?; // robot
        _ = tokens.next().?; // costs
        blueprint.geode.ore = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // ore
        _ = tokens.next().?; // and
        blueprint.geode.obsidian = try std.fmt.parseInt(u16, tokens.next().?, 10); // XX
        _ = tokens.next().?; // obsidian.
        assert(tokens.next() == null);

        var simulator = Simulator(u16).init(allocator, blueprint);
        defer simulator.deinit();

        try simulator.simulate(.{
            .resources = .{ .ore = 0, .clay = 0, .obsidian = 0, .geode = 0 },
            .robots = .{ .ore = 1, .clay = 0, .obsidian = 0, .geode = 0 },
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
