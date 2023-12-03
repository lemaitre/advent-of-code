const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

fn gcd(comptime T: type, x: T, y: T) T {
    if (x == 0) {
        return y;
    }

    return gcd(T, @mod(y, x), x);
}

fn lcm(comptime T: type, x: T, y: T) T {
    return x * y / gcd(T, x, y);
}

const Value = union(enum) {
    constant: u30,
    worry,

    fn initConstant(val: u30) Value {
        return .{ .constant = val };
    }
    fn initWorry() Value {
        return .{ .worry = .{} };
    }

    fn parse(input: []const u8) !Value {
        if (std.fmt.parseInt(u30, input, 10)) |val| {
            return Value.initConstant(val);
        } else |_| {
            return Value.initWorry();
        }
    }

    fn eval(self: Value, worry: u64) u64 {
        return switch (self) {
            Value.constant => |x| x,
            Value.worry => worry,
        };
    }
};

const Operator = enum {
    add,
    mul,

    fn apply(self: Operator, lhs: u64, rhs: u64) u64 {
        return switch (self) {
            Operator.add => lhs + rhs,
            Operator.mul => lhs * rhs,
        };
    }
};

const Monkey = struct {
    items: std.ArrayList(u64),
    args: [2]Value,
    operator: Operator,
    divisibility: u64,
    then_throw: u32,
    else_throw: u32,
    thrown: usize = 0,
};

const Monkeys = struct {
    monkeys: std.ArrayList(Monkey),
    round: u32 = 1,
    lcm: u64 = 1,

    fn init(allocator: std.mem.Allocator) Monkeys {
        return .{ .monkeys = std.ArrayList(Monkey).init(allocator) };
    }
    fn deinit(self: *Monkeys) void {
        for (self.monkeys.items) |*monkey| {
            monkey.items.deinit();
        }
        self.monkeys.deinit();
    }

    fn addMonkey(self: *Monkeys, monkey: Monkey) !void {
        //self.lcm = lcm(u64, self.lcm, monkey.divisibility);
        self.lcm *= monkey.divisibility;
        try self.monkeys.append(monkey);
    }

    fn doRound(self: *Monkeys) !void {
        for (self.monkeys.items) |*monkey| {
            for (monkey.items.items) |itemWorry| {
                var lhs = monkey.args[0].eval(itemWorry);
                var rhs = monkey.args[1].eval(itemWorry);
                var worry = monkey.operator.apply(lhs, rhs) % self.lcm;

                var targetIdx : u32 = undefined;
                if (@mod(worry, monkey.divisibility) == 0) {
                    targetIdx = monkey.then_throw;
                } else {
                    targetIdx = monkey.else_throw;
                }
                var target = &self.monkeys.items[targetIdx];
                assert(target != monkey);

                try target.items.append(worry);
            }
            monkey.thrown += monkey.items.items.len;
            try monkey.items.resize(0);
        }
    }
};

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

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var monkeys = Monkeys.init(allocator);
    defer monkeys.deinit();
    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |monkeyLine| {
        // monkey line
        _ = removePrefix(monkeyLine, "Monkey ");
        var monkey : Monkey = undefined;
        monkey.thrown = 0;

        // starting items line
        monkey.items = std.ArrayList(u64).init(allocator);
        var itemIt = std.mem.split(u8, removePrefix(lines.next().?, "  Starting items: "), ", ");
        while (itemIt.next()) |item| {
            var val = try std.fmt.parseInt(u32, item, 10);
            try monkey.items.append(val);
        }

        // operation line
        var tokens : [3][]const u8 = undefined;
        try iterIntoExact(&std.mem.tokenize(u8, removePrefix(lines.next().?, "  Operation: new = "), " "), &tokens);
        monkey.args[0] = try Value.parse(tokens[0]);
        monkey.args[1] = try Value.parse(tokens[2]);
        assert(tokens[1].len == 1);
        var opChr = tokens[1][0];
        if (opChr == '+') {
            monkey.operator = Operator.add;
        } else if (opChr == '*') {
            monkey.operator = Operator.mul;
        } else {
            unreachable;
        }

        monkey.divisibility = try std.fmt.parseInt(u32, removePrefix(lines.next().?, "  Test: divisible by "), 10);
        monkey.then_throw = try std.fmt.parseInt(u32, removePrefix(lines.next().?, "    If true: throw to monkey "), 10);
        monkey.else_throw = try std.fmt.parseInt(u32, removePrefix(lines.next().?, "    If false: throw to monkey "), 10);

        try monkeys.addMonkey(monkey);
    }

    try std.fmt.format(stdout, "lcm: {}\n", .{monkeys.lcm});
    for (range(10000)) |_| {
        try monkeys.doRound();
    }

    var thrown = try allocator.alloc(usize, monkeys.monkeys.items.len);
    defer allocator.free(thrown);

    for (monkeys.monkeys.items) |monkey, i| {
        thrown[i] = monkey.thrown;
        try std.fmt.format(stdout, "Monkey {} inspected items {} times.\n", .{i, monkey.thrown});
    }

    std.sort.sort(usize, thrown, {}, comptime std.sort.desc(usize));

    for (thrown) |monkeyThrown| {
        try std.fmt.format(stdout, "Thrown {}\n", .{monkeyThrown});
    }
    try std.fmt.format(stdout, "{}\n", .{thrown[0] * thrown[1]});



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
