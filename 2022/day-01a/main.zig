const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    _ = allocator;
    var lines = std.mem.split(u8, input, "\n");
    var maxFood: u32 = 0;
    var currentFood: u32 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            maxFood = std.math.max(maxFood, currentFood);
            currentFood = 0;
            continue;
        }
        var food = try std.fmt.parseInt(u32, line, 10);
        currentFood += food;
    }

    maxFood = std.math.max(maxFood, currentFood);
    _ = try std.fmt.format(stdout, "{}\n", .{maxFood});
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
