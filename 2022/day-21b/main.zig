const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Expr = union(enum) {
    add: [2][]const u8,
    sub: [2][]const u8,
    mul: [2][]const u8,
    div: [2][]const u8,
    val: i64,
    ukn,

    fn args(self: Expr, map: std.StringHashMap(Expr)) [2]*Expr {
        return switch (self) {
            .add => |args| .{ map.getPtr(args[0]).?, map.getPtr(args[1]).? },
            .sub => |args| .{ map.getPtr(args[0]).?, map.getPtr(args[1]).? },
            .mul => |args| .{ map.getPtr(args[0]).?, map.getPtr(args[1]).? },
            .div => |args| .{ map.getPtr(args[0]).?, map.getPtr(args[1]).? },
            .val => unreachable,
            .ukn => unreachable,
        };
    }

    fn value(self: Expr) i64 {
        return switch (self) {
            .add => unreachable,
            .sub => unreachable,
            .mul => unreachable,
            .div => unreachable,
            .val => |val| val,
            .ukn => unreachable,
        };
    }

    fn isOperation(self: Expr) bool {
        return switch (self) {
            .add => true,
            .sub => true,
            .mul => true,
            .div => true,
            .val => false,
            .ukn => false,
        };
    }

    fn isVal(self: Expr) bool {
        return switch (self) {
            .add => false,
            .sub => false,
            .mul => false,
            .div => false,
            .val => true,
            .ukn => false,
        };
    }

    fn print(self: Expr, out: anytype, map: std.StringHashMap(Expr), indent: u32) void {
        for (range(indent)) |_| {
            std.fmt.format(out, "  ", .{}) catch unreachable;
        }

        if (self.isOperation()) {
            var operands = self.args(map);
            var opc: []const u8 = switch (self) {
                .add => "+",
                .sub => "-",
                .mul => "*",
                .div => "/",
                else => unreachable,
            };
            std.fmt.format(out, "{s}\n", .{opc}) catch unreachable;
            operands[0].print(out, map, indent + 1);
            operands[1].print(out, map, indent + 1);
        } else if (self.isVal()) {
            std.fmt.format(out, "{}\n", .{self.val}) catch unreachable;
        } else {
            std.fmt.format(out, "?\n", .{}) catch unreachable;
        }
    }

    fn eval(self: Expr, map: std.StringHashMap(Expr)) i64 {
        return switch (self) {
            .add => |args| map.get(args[0]).?.eval(map) + map.get(args[1]).?.eval(map),
            .sub => |args| map.get(args[0]).?.eval(map) - map.get(args[1]).?.eval(map),
            .mul => |args| map.get(args[0]).?.eval(map) * map.get(args[1]).?.eval(map),
            .div => |args| @divFloor(map.get(args[0]).?.eval(map), map.get(args[1]).?.eval(map)),
            .val => |val| val,
        };
    }

    fn simplify(self: *Expr, map: std.StringHashMap(Expr)) ?i64 {
        if (self.isVal()) {
            return self.val;
        }
        if (!self.isOperation()) {
            return null;
        }
        var operands = self.args(map);
        var a = operands[0].simplify(map);
        var b = operands[1].simplify(map);

        if (a) |a_val| {
            if (b) |b_val| {
                var val: i64 = switch (self.*) {
                    .add => a_val + b_val,
                    .sub => a_val - b_val,
                    .mul => a_val * b_val,
                    .div => @divTrunc(a_val, b_val),
                    else => unreachable,
                };
                self.* = .{ .val = val };
                return val;
            }
        }

        return null;
    }

    fn solve(self: Expr, map: std.StringHashMap(Expr), target: i64) i64 {
        if (!self.isVal() and !self.isOperation()) {
            return target;
        }

        var operands = self.args(map);
        var a = operands[0];
        var b = operands[1];

        if (a.isVal()) {
            return switch (self) {
                .add => b.solve(map, target - a.val),
                .sub => b.solve(map, a.val - target),
                .mul => b.solve(map, @divFloor(target, a.val)),
                .div => b.solve(map, @divFloor(a.val, target)),
                else => unreachable,
            };
        } else if (b.isVal()) {
            return switch (self) {
                .add => a.solve(map, target - b.val),
                .sub => a.solve(map, target + b.val),
                .mul => a.solve(map, @divFloor(target, b.val)),
                .div => a.solve(map, target * b.val),
                else => unreachable,
            };
        } else {
            std.fmt.format(stdout, "a: {any}\nb: {any}\n", .{ a, b }) catch unreachable;
            unreachable;
        }
    }
};

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var expr_nodes = std.StringHashMap(Expr).init(allocator);
    defer expr_nodes.deinit();

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        var tokens = std.mem.tokenize(u8, line, ": ");
        var name = tokens.next().?;
        var entry = try expr_nodes.getOrPut(name);
        var node = entry.value_ptr;
        if (std.mem.eql(u8, name, "humn")) {
            node.* = .ukn;
            continue;
        }

        var arg = tokens.next().?;

        if (tokens.next()) |op| {
            var a = arg;
            var b = tokens.next().?;

            assert(tokens.next() == null);
            var opc = op[0];
            if (std.mem.eql(u8, name, "root")) {
                opc = '-';
            }

            node.* = switch (opc) {
                '+' => Expr{ .add = .{ a, b } },
                '-' => Expr{ .sub = .{ a, b } },
                '*' => Expr{ .mul = .{ a, b } },
                '/' => Expr{ .div = .{ a, b } },
                else => unreachable,
            };
        } else {
            node.* = .{ .val = try std.fmt.parseInt(i32, arg, 10) };
        }
    }

    var root = expr_nodes.getPtr("root").?;
    _ = root.simplify(expr_nodes);
    //root.print(stdout, expr_nodes, 0);

    try std.fmt.format(stdout, "result: {}\n", .{root.solve(expr_nodes, 0)});
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
