const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Element = union(enum) {
    int: u32,
    list: std.ArrayList(Element),

    fn initInt(int: u32) Element {
        return .{ .int = int };
    }

    fn initList(allocator: std.mem.Allocator) Element {
        return .{ .list = std.ArrayList(Element).init(allocator) };
    }

    fn deinit(self: *Element) void {
        switch (self.*) {
            .int => void{},
            .list => |*vec| vec.deinit(),
        }
    }

    fn addElement(self: *Element, el: Element) !void {
        switch (self.*) {
            .int => return error.ElementIsInt,
            .list => |*vec| try vec.append(el),
        }
    }

    fn order(lhs: Element, rhs: Element) std.math.Order {
        return switch (lhs) {
            .int => |lint| switch (rhs) {
                .int => |rint| std.math.order(lint, rint),
                .list => |rlist| Element.orderSlice(&([1]Element){lhs}, rlist.items),
            },
            .list => |llist| switch (rhs) {
                .int => Element.orderSlice(llist.items, &([1]Element){rhs}),
                .list => |rlist| Element.orderSlice(llist.items, rlist.items),
            },
        };
    }

    fn orderSlice(lhs: []Element, rhs: []Element) std.math.Order {
        var n = @minimum(lhs.len, rhs.len);
        for (range(n)) |_, i| {
            var o = lhs[i].order(rhs[i]);
            if (o != .eq) {
                return o;
            }
        }
        return std.math.order(lhs.len, rhs.len);
    }

    fn ord() fn (void, Element, Element) std.math.Order {
        const impl = struct {
            fn inner(context: void, a: Element, b: Element) std.math.Order {
                _ = context;
                return a.order(b);
            }
        };
        return impl.inner;
    }
    fn asc() fn (void, Element, Element) bool {
        const impl = struct {
            fn inner(context: void, a: Element, b: Element) bool {
                _ = context;
                return a.order(b) == .lt;
            }
        };
        return impl.inner;
    }
    fn desc() fn (void, Element, Element) bool {
        const impl = struct {
            fn inner(context: void, a: Element, b: Element) bool {
                _ = context;
                return a.order(b) == .gt;
            }
        };
        return impl.inner;
    }

    const ParserError = error {
        ElementIsInt,
        InvalidToken,
        EndOfElementToken,
        CommaToken,
        EndOfStr,
        Memory,
        OutOfMemory,
    };

    fn parseTokens(allocator: std.mem.Allocator, str: []const u8, i: *u32) ParserError!Element {
        if (i.* >= str.len) {
            return error.EndOfStr;
        }
        switch (str[i.*]) {
            '[' => {
                var list = Element.initList(allocator);
                errdefer list.deinit();

                if (i.* < str.len-1 and str[i.* + 1] == ']') {
                    i.* += 2;
                    return list;
                }

                var delimiter : u8 = '[';

                while (true) {
                    if (i.* >= str.len) {
                        return error.EndOfStr;
                    } else if (str[i.*] == ']') {
                        i.* += 1;
                        return list;
                    } else if (str[i.*] == delimiter) {
                        i.* += 1;
                        delimiter = ',';
                    } else {
                        return error.InvalidToken;
                    }
                    try list.addElement(try Element.parseTokens(allocator, str, i));
                }
            },
            ']' => return error.EndOfElementToken,
            ',' => return error.CommaToken,
            '0'...'9' => {
                // Parse int
                var x: u32 = 0;
                while (i.* < str.len and '0' <= str[i.*] and str[i.*] <= '9') : (i.* += 1) {
                    x = x * 10 + str[i.*] - '0';
                }
                return Element.initInt(x);
            },
            else => return error.InvalidToken,
        }
    }

    fn parse(allocator: std.mem.Allocator, str: []const u8) !Element {
        try std.fmt.format(stdout, "str: {s}\n", .{str});
        var i : u32 = 0;
        var el = try Element.parseTokens(allocator, str, &i);
        if (i < str.len) {
            return error.PartialRead;
        }
        return el;
    }

    const PrintError = error {
        DiskQuota,
        FileTooBig,
        InputOutput,
        NoSpaceLeft,
        AccessDenied,
        BrokenPipe,
        SystemResources,
        OperationAborted,
        NotOpenForWriting,
        WouldBlock,
        ConnectionResetByPeer,
        Unexpected,
    };

    fn print(self: Element, out: anytype, indent: u32) PrintError!void {
        for (range(indent)) |_| {
            try std.fmt.format(out, "  ", .{});
        }
        switch (self) {
            .int => |i| {
                try std.fmt.format(out, "{}\n", .{i});
            },
            .list => |list| {
                try std.fmt.format(out, "[\n", .{});
                for (list.items) |el| {
                    try el.print(out, indent + 1);
                }
                for (range(indent)) |_| {
                    try std.fmt.format(out, "  ", .{});
                }
                try std.fmt.format(out, "]\n", .{});

            },
        }
    }
};

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var startPacket = try Element.parse(allocator, "[[2]]");
    defer startPacket.deinit();
    var stopPacket = try Element.parse(allocator, "[[6]]");
    defer stopPacket.deinit();
    var packets = Element.initList(allocator);
    defer packets.deinit();
    try packets.addElement(startPacket);
    try packets.addElement(stopPacket);

    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        try packets.addElement(try Element.parse(allocator, line));
    }

    std.sort.sort(Element, packets.list.items, void{}, comptime Element.asc());

    var start = std.sort.binarySearch(Element, startPacket, packets.list.items, void{}, comptime Element.ord()).? + 1;
    var stop  = std.sort.binarySearch(Element, stopPacket,  packets.list.items, void{}, comptime Element.ord()).? + 1;

    try std.fmt.format(stdout, "{} x {} = {}\n", .{start, stop, start*stop});
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

        fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i + rhs.i, lhs.j + rhs.j);
        }
        fn sub(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.i - rhs.i, lhs.j - rhs.j);
        }

        fn as(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @as(U, self.i), .j = @as(U, self.j) };
        }
        fn cast(self: Self, comptime U: type) Vec2D(U) {
            return .{ .i = @intCast(U, self.i), .j = @intCast(U, self.j) };
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
