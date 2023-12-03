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
        return .{
            .valves = std.ArrayList(Valve).init(allocator),
        };
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
        const N = 2;
        const Agent = struct {
            valve_id: Valve.ID,
            remaining_time: u8 = 0,
        };
        opened: u64 = 0,
        agents: [N]Agent,
        pressure: u32 = 0,

        fn is_open(self: State, id: Valve.ID) bool {
            return (self.opened >> id) & 1 == 1;
        }
        fn open(self: *State, id: Valve.ID) void {
            self.opened |= @as(u64, 1) << id;
        }

        fn normalize(self: *State) void {
            std.sort.sort(Agent, &self.agents, void{}, struct {
                fn inner(_: void, lhs: Agent, rhs: Agent) bool {
                    return lhs.valve_id < rhs.valve_id;
                }
            }.inner);
        }

        fn normalized(self: State) State {
            var copy = self;
            copy.normalize();
            return copy;
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

fn find(alloc: std.mem.Allocator, net: Network, init: Network.State) !u32 {
    const Finder = struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        network: Network,
        openable_valves: std.ArrayList(Valve),
        max_pressure: u32 = 0,
        seen: std.AutoHashMap(Network.State, u32),
        queue: Queue(Network.State),
        pathes: Grid(u8),

        fn init(allocator: std.mem.Allocator, network: Network) !Self {
            var n = @intCast(Valve.ID, network.valves.items.len);
            var pathes = try Grid(u8).init(allocator, n);
            errdefer pathes.deinit(allocator);

            var openable_valves = std.ArrayList(Valve).init(allocator);
            errdefer openable_valves.deinit();

            const State = struct {
                valve_id: Valve.ID,
                distance: u8 = 1,
            };
            var queue = Queue(State).init(allocator);
            defer queue.deinit();

            for (network.valves.items) |valve| {
                if (valve.flow > 0) {
                    try openable_valves.append(valve);
                }
            }
            std.sort.sort(Valve, openable_valves.items, void{}, struct {
                fn inner(_: void, lhs: Valve, rhs: Valve) bool {
                    return lhs.flow < rhs.flow;
                }
            }.inner);
            for (network.valves.items) |_, valve_id| {
                var row = pathes.rows[valve_id];
                std.mem.set(u8, row, 255);
                try queue.push(.{ .valve_id = @intCast(Valve.ID, valve_id) });

                while (queue.pop()) |state| {
                    if (row[state.valve_id] <= state.distance) {
                        continue;
                    }
                    row[state.valve_id] = state.distance;

                    var valve = network.valves.items[state.valve_id];
                    for (valve.connections) |conn| {
                        var d = row[conn];
                        if (d > state.distance + 1) {
                            try queue.push(.{ .valve_id = conn, .distance = state.distance + 1 });
                        }
                    }
                }
            }

            return Self{
                .allocator = allocator,
                .network = network,
                .openable_valves = openable_valves,
                .seen = std.AutoHashMap(Network.State, u32).init(allocator),
                .queue = Queue(Network.State).init(allocator),
                .pathes = pathes,
            };
        }

        fn deinit(self: *Self) void {
            self.seen.deinit();
            self.queue.deinit();
            self.pathes.deinit(self.allocator);
        }

        fn find(self: *Self, state: Network.State) void {
            self.max_pressure = @maximum(self.max_pressure, state.pressure);

            var max_remaining_time: u32 = 0;
            var max_releasable_pressure: u32 = state.pressure;
            for (state.agents) |agent| {
                max_remaining_time = @maximum(max_remaining_time, agent.remaining_time);
            }
            for (self.openable_valves.items) |valve| {
                if (!state.is_open(valve.id)) {
                    max_remaining_time -|= 1;
                    max_releasable_pressure += max_remaining_time * valve.flow;
                }
            }

            if (max_releasable_pressure <= self.max_pressure) {
                return;
            }
            for (self.openable_valves.items) |valve| {
                if (state.is_open(valve.id)) {
                    continue;
                }

                for (state.agents) |agent, i| {
                    var distance = self.pathes.rows[valve.id][agent.valve_id];
                    if (agent.remaining_time <= distance) {
                        continue;
                    }

                    var new_state = state;
                    var remaining_time = agent.remaining_time - distance;
                    new_state.open(valve.id);
                    new_state.agents[i] = .{
                        .valve_id = valve.id,
                        .remaining_time = remaining_time,
                    };
                    new_state.pressure += valve.flow * remaining_time;

                    self.find(new_state);
                }
            }
        }
    };
    var finder = try Finder.init(alloc, net);
    defer finder.deinit();
    var timer = try std.time.Timer.start();
    finder.find(init);
    var duration = timer.read();
    try std.fmt.format(stdout, "elapsed time: {}\n", .{std.fmt.fmtDuration(duration)});
    return finder.max_pressure;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8, n: u8) !void {
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

    var id = network.find_id("AA");
    var state = Network.State{ .agents = undefined };
    for (state.agents) |*agent| {
        agent.* = .{ .valve_id = id, .remaining_time = n };
    }
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
    var n = try std.fmt.parseInt(u8, arg_it.next(allocator) orelse "26" catch "26", 10);

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

pub fn Dequeue(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        data: []T = &[0]T{},
        start: usize = 0,
        end: usize = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
            self.* = Self.init(self.allocator);
        }

        pub fn size(self: Self) usize {
            if (self.end < self.start) {
                return self.end + 1 + self.data.len - self.start;
            } else {
                return self.end - self.start;
            }
        }

        pub fn capacity(self: Self) usize {
            return self.data.len;
        }

        pub fn empty(self: Self) bool {
            return self.start == self.end;
        }
        pub fn full(self: Self) bool {
            return self.size() == self.capacity();
            //return self.start == self.end + 1 or (self.start == 0 and self.end == self.data.len);
        }

        pub fn reserve(self: *Self, target_capacity: usize) !void {
            if (target_capacity <= self.capacity()) {
                return;
            }

            var new_capacity = self.capacity();
            new_capacity += new_capacity / 2;
            new_capacity = @maximum(new_capacity, @maximum(target_capacity, 4));

            if (self.end < self.start) {
                var old_capacity = self.data.len;
                var new_start = self.start + new_capacity - old_capacity;
                if (self.allocator.resize(self.data, new_capacity)) |new_data| {
                    self.data = new_data;
                    std.mem.copyBackwards(T, self.data[new_start..new_capacity], self.data[self.start..old_capacity]);
                } else {
                    var new_data = try self.allocator.alloc(T, new_capacity);
                    std.mem.copy(T, new_data[0..(self.end + 1)], self.data[0..(self.end + 1)]);
                    std.mem.copy(T, new_data[new_start..new_capacity], self.data[self.start..old_capacity]);
                    self.allocator.free(self.data);
                    self.data = new_data;
                }
                self.start = new_start;
            } else {
                self.data = try self.allocator.realloc(self.data, new_capacity);
            }
        }

        pub fn popFront(self: *Self) ?T {
            if (self.empty()) {
                return null;
            }

            var val = self.data[self.start];
            self.start += 1;

            if (self.start == self.data.len) {
                self.start = 0;
                self.end -= 1;
            }

            return val;
        }

        pub fn popBack(self: *Self) ?T {
            if (self.empty()) {
                return null;
            }

            if (self.end < self.start) {
                var val = self.data[self.end];
                if (self.end == 0) {
                    self.end = self.data.len;
                } else {
                    self.end -= 1;
                }
                return val;
            }

            self.end -= 1;
            return self.data[self.end];
        }

        pub fn pushFront(self: *Self, val: T) !void {
            if (self.full()) {
                try self.reserve(self.capacity() + 1);
            }

            if (self.start == 0) {
                self.start = self.data.len;
            }
            self.start -= 1;
            self.data[self.start] = val;
        }

        pub fn pushBack(self: *Self, val: T) !void {
            if (self.full()) {
                try self.reserve(self.capacity() + 1);
            }

            if (self.end < self.start) {
                self.end += 1;
                self.data[self.end] = val;
            } else if (self.end == self.data.len) {
                self.end = 0;
                self.data[self.end] = val;
            } else {
                self.data[self.end] = val;
                self.end += 1;
            }
        }
    };
}
