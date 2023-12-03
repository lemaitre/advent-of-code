const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.split(u8, input, "\n");

    var elves = std.ArrayList(u32).init(allocator);
    defer elves.deinit();
    var currentFood: u32 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            try elves.append(currentFood);
            currentFood = 0;
            continue;
        }
        var food = try std.fmt.parseInt(u32, line, 10);
        currentFood += food;
    }
    try elves.append(currentFood);

    if (elves.items.len < 3) {
        return error.NotEnoughElves;
    }

    std.sort.sort(u32, elves.items, {}, comptime std.sort.desc(u32));

    var food = elves.items[0] + elves.items[1] + elves.items[2];

    _ = try std.fmt.format(stdout, "{}\n", .{food});
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
