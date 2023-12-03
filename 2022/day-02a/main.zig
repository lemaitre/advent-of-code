const std = @import("std");
const stdout = std.io.getStdOut().writer();

// A or X: Rock
// B or Y: Paper
// C or Z: Scissors

fn roundScore(abc: u8, xyz: u8) u32 {
    var left = abc - 'A';
    var right = xyz - 'X';

    var outcome = (4 + right - left) % 3;
    return 1 + right + 3 * outcome;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;
    var lines = std.mem.tokenize(u8, input, "\n");
    var score: u32 = 0;
    while (lines.next()) |line| {
        score += roundScore(line[0], line[2]);
    }
    _ = try std.fmt.format(stdout, "{}\n", .{score});
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
