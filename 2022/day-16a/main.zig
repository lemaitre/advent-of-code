const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Valve = struct {
    const ID = u6;

    id: ID = 0,
    name: [2]u8 = undefined,
    connections: []ID = &[0]ID{},
    flow: u32 = 0,

    fn key(name: []const u8) u16 {
        return @as(u16, name[0] - 'A') + @as(u16, name[1] - 'A') * 26;
    }
};

const Network = struct {
    valves: std.ArrayList(Valve),
    valveLUT: [26 * 26]Valve.ID = [1]Valve.ID{-%@as(Valve.ID, 1)} ** (26 * 26),

    fn init(allocator: std.mem.Allocator) Network {
        return .{ .valves = std.ArrayList(Valve).init(allocator) };
    }

    fn deinit(self: *Network) void {
        self.valves.deinit();
    }

    fn allocate_valve(self: *Network, name: []const u8) !Valve.ID {
        var key = Valve.key(name);
        var id = self.valveLUT[key];
        if (id > self.valves.items.len) {
            id = @intCast(Valve.ID, self.valves.items.len);
            try self.valves.append(.{ .id = id });
            self.valveLUT[key] = id;
        }
        return id;
    }

    fn add_valve(self: *Network, valve: Valve) !*Valve {
        var id = try self.allocate_valve(&valve.name);
        var ptr = &self.valves.items[id];

        ptr.* = valve;
        ptr.id = id;

        return ptr;
    }

    fn find_id(self: *Network, valve_name: []const u8) Valve.ID {
        return self.valveLUT[Valve.key(valve_name)];
    }
    fn find(self: *Network, valve_name: []const u8) *Valve {
        return self.valves.items[self.find_id(valve_name)];
    }

    const State = struct {
        valveId: Valve.ID,
        opened: u64 = 0,
    };
    const TimedState = struct {
        valveId: Valve.ID,
        opened: u64 = 0,
        pressure: u32 = 0,
        timeRemaining: u32,

        fn without_time(self: TimedState) State {
            return .{ .valveId = self.valveId, .opened = self.opened };
        }

        fn is_open(self: TimedState, valve: Valve) bool {
            return (self.opened >> valve.id) & 1 == 1;
        }
        fn open(self: *TimedState, valve: Valve) void {
            self.opened |= @as(u64, 1) << valve.id;
            self.pressure += self.timeRemaining * valve.flow;
        }
    };
};

fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        inner: std.TailQueue(T),
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) Self {
            return .{ .inner = .{}, .allocator = allocator };
        }

        fn deinit(self: *Self) void {
            while (self.inner.pop()) |node| {
                self.allocator.destroy(node);
            }
        }

        fn push(self: *Self, val: T) !void {
            var node = try self.allocator.create(std.TailQueue(T).Node);
            node.* = .{ .data = val };
            self.inner.prepend(node);
        }
        fn pop(self: *Self) ?T {
            if (self.inner.pop()) |node| {
                var val = node.data;
                self.allocator.destroy(node);
                return val;
            }
            return null;
        }
    };
}

fn find(allocator: std.mem.Allocator, network: Network, initialState: Network.TimedState) !u32 {
    var seen = std.AutoHashMap(Network.State, u32).init(allocator);
    defer seen.deinit();
    var queue = Queue(Network.TimedState).init(allocator);
    defer queue.deinit();

    try queue.push(initialState);
    try seen.put(initialState.without_time(), 0);

    var maxPressure: u32 = 0;
    while (queue.pop()) |state| {
        if (state.timeRemaining == 0) {
            maxPressure = @maximum(maxPressure, state.pressure);
            continue;
        }

        var valve = network.valves.items[state.valveId];
        if (!state.is_open(valve) and valve.flow > 0) {
            var newState = state;
            newState.timeRemaining -= 1;
            newState.open(valve);

            var entry = try seen.getOrPut(newState.without_time());
            if (!entry.found_existing or entry.value_ptr.* < newState.pressure) {
                entry.value_ptr.* = newState.pressure;
                try queue.push(newState);
            }
        }

        for (valve.connections) |conn| {
            var newState = state;
            newState.timeRemaining -= 1;
            newState.valveId = conn;

            var entry = try seen.getOrPut(newState.without_time());
            if (!entry.found_existing or entry.value_ptr.* < newState.pressure) {
                entry.value_ptr.* = newState.pressure;
                try queue.push(newState);
            }
        }
    }

    return maxPressure;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var network = Network.init(allocator);
    defer {
        for (network.valves.items) |valve| {
            allocator.free(valve.connections);
        }
        network.deinit();
    }
    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var valve = Valve{};

        var tokens = std.mem.tokenize(u8, line, " ");
        _ = tokens.next().?; // "Valve"
        std.mem.copy(u8, &valve.name, tokens.next().?); // XX
        _ = tokens.next().?; // "has"
        _ = tokens.next().?; // "flow"
        var flowStr = tokens.next().?; // rate=XX;
        valve.flow = try std.fmt.parseInt(u32, flowStr[5..(flowStr.len - 1)], 10);
        _ = tokens.next().?; // "tunnel(s)"
        _ = tokens.next().?; // "lead(s)"
        _ = tokens.next().?; // "to"
        _ = tokens.next().?; // "valve(s)"
        var connectionTokens = std.mem.split(u8, tokens.rest(), ", ");

        var connections = std.ArrayList(Valve.ID).init(allocator);
        errdefer connections.deinit();

        while (connectionTokens.next()) |conn| {
            try connections.append(try network.allocate_valve(conn));
        }

        (try network.add_valve(valve)).connections = connections.toOwnedSlice();
    }
    for (network.valves.items) |valve| {
        if (valve.connections.len == 0) {
            continue;
        }
        try std.fmt.format(stdout, "Valve {s} (#{}), flow={}, leads to ", .{ valve.name, valve.id, valve.flow });
        var delimiter: []const u8 = "";
        for (valve.connections) |conn| {
            var remote = network.valves.items[conn];
            try std.fmt.format(stdout, "{s}{s}", .{ delimiter, remote.name });
            delimiter = ", ";
        }
        try std.fmt.format(stdout, "\n", .{});
    }

    var state = Network.TimedState{ .valveId = network.find_id("AA"), .timeRemaining = 30 };
    var pressure = find(allocator, network, state);
    try std.fmt.format(stdout, "max released pressure: {}\n", .{pressure});
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
