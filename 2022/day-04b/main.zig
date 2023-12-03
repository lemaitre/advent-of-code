const std = @import("std");
const expect = std.testing.expect;
const stdout = std.io.getStdOut().writer();

fn Interval(comptime T: type) type {
    return struct {
        const Self = @This();

        lower: T,
        upper: T,

        fn init(lower: T, upper: T) Self {
            return .{ .lower = lower, .upper = upper };
        }
        fn contains(self: Self, x: T) bool {
            return self.lower <= x and x <= self.upper;
        }
        fn overlaps(lhs: Self, rhs: Self) bool {
            return lhs.contains(rhs.lower) or lhs.contains(rhs.upper) or
                rhs.contains(lhs.lower) or rhs.contains(lhs.upper);
        }
        fn fullyOverlaps(lhs: Self, rhs: Self) bool {
            return (lhs.contains(rhs.lower) and lhs.contains(rhs.upper)) or
                (rhs.contains(lhs.lower) and rhs.contains(lhs.upper));
        }
    };
}

test "interval-contains" {
    try expect(!Interval(u8).init(3, 7).contains(2));
    try expect(Interval(u8).init(3, 7).contains(3));
    try expect(Interval(u8).init(3, 7).contains(4));
    try expect(Interval(u8).init(3, 7).contains(6));
    try expect(Interval(u8).init(3, 7).contains(7));
    try expect(!Interval(u8).init(3, 7).contains(8));
}
test "interval-overlaps" {
    try expect(!Interval(u8).init(3, 7).overlaps(Interval(u8).init(0, 1)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(0, 3)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(0, 4)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(0, 7)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(0, 8)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(3, 7)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(4, 7)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(4, 6)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(3, 6)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(3, 9)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(4, 9)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(6, 9)));
    try expect(Interval(u8).init(3, 7).overlaps(Interval(u8).init(7, 9)));
    try expect(!Interval(u8).init(3, 7).overlaps(Interval(u8).init(8, 9)));
}
test "interval-fullyOverlaps" {
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(0, 1)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(0, 3)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(0, 4)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(0, 7)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(0, 8)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(3, 7)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(4, 7)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(4, 6)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(3, 6)));
    try expect(Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(3, 9)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(4, 9)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(6, 9)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(7, 9)));
    try expect(!Interval(u8).init(3, 7).fullyOverlaps(Interval(u8).init(8, 9)));
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;

    var lines = std.mem.tokenize(u8, input, "\n");

    var count: u32 = 0;

    while (lines.next()) |line| {
        var index1 = std.mem.indexOfScalarPos(u8, line, 0, '-').?;
        var index2 = std.mem.indexOfScalarPos(u8, line, index1, ',').?;
        var index3 = std.mem.indexOfScalarPos(u8, line, index2, '-').?;

        var L0 = try std.fmt.parseInt(u32, line[0..index1], 10);
        var L1 = try std.fmt.parseInt(u32, line[(index1 + 1)..index2], 10);
        var R0 = try std.fmt.parseInt(u32, line[(index2 + 1)..index3], 10);
        var R1 = try std.fmt.parseInt(u32, line[(index3 + 1)..line.len], 10);

        var L = Interval(u32).init(L0, L1);
        var R = Interval(u32).init(R0, R1);

        count += @boolToInt(L.overlaps(R));
    }
    try std.fmt.format(stdout, "{}\n", .{count});
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
