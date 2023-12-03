const std = @import("std");
const assert = std.debug.assert;
const stdout = std.io.getStdOut().writer();

fn CrateStacks(comptime T: type) type {
    return struct {
        const Self = @This();
        const Stack = std.ArrayListUnmanaged(T);
        const Stacks = []Stack;

        items: Stacks,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator, n: usize) !Self {
            var stacks = try allocator.alloc(Stack, n);
            for (stacks) |*stack| {
                stack.* = .{};
            }
            return @as(Self, .{ .items = stacks, .allocator = allocator });
        }

        fn deinit(self: *Self) void {
            for (self.items) |*stack| {
                stack.deinit(self.allocator);
            }
            self.allocator.free(self.items);
        }

        fn pushCrate(self: *Self, stackId: usize, crate: T) !void {
            var stack = &self.items[stackId];
            try stack.append(self.allocator, crate);
        }

        fn popCrate(self: *Self, stackId: usize) T {
            var stack = &self.items[stackId];
            return stack.pop();
        }

        fn reverseCrates(self: *Self) void {
            for (self.items) |stack| {
                std.mem.reverse(T, stack.items);
            }
        }
    };
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {

    var lines = std.mem.split(u8, input, "\n");
    var headerLine = lines.next().?;

    const n = (headerLine.len + 1) / 4;
    var stacks = try CrateStacks(u8).init(allocator, n);
    defer stacks.deinit();

    while (!std.mem.eql(u8, headerLine, "")) : (headerLine = lines.next().?) {
        var i : u32 = 0;
        while (i < n) : (i += 1) {
            if (headerLine[4*i] == '[') {
                try stacks.pushCrate(i, headerLine[4*i+1]);
            }
        }
    }
    stacks.reverseCrates();

    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var tokens = std.mem.tokenize(u8, line, " ");
        var token0 = tokens.next().?;
        var token1 = tokens.next().?;
        var token2 = tokens.next().?;
        var token3 = tokens.next().?;
        var token4 = tokens.next().?;
        var token5 = tokens.next().?;
        assert(tokens.next() == null);
        assert(std.mem.eql(u8, token0, "move"));
        assert(std.mem.eql(u8, token2, "from"));
        assert(std.mem.eql(u8, token4, "to"));

        var nb = try std.fmt.parseInt(u32, token1, 10);
        var from = (try std.fmt.parseInt(u32, token3, 10)) - 1;
        var to = (try std.fmt.parseInt(u32, token5, 10)) - 1;

        var fromStack = &stacks.items[from];
        var toStack = &stacks.items[to];

        var slice = fromStack.items[(fromStack.items.len - nb)..fromStack.items.len];

        try toStack.appendSlice(allocator, slice);
        try fromStack.resize(allocator, fromStack.items.len - nb);
    }

    for (stacks.items) |*stack| {
        try std.fmt.format(stdout, "{c}", .{stack.pop()});
    }
    try std.fmt.format(stdout, "\n", .{});
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
