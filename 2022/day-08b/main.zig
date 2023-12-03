const std = @import("std");
const assert = std.debug.assert;
const stdout = std.io.getStdOut().writer();

fn gridAlloc(allocator: std.mem.Allocator, n: usize) ![]const[]u8 {
    const data = try allocator.alloc(u8, n*n);
    errdefer allocator.free(data);
    const grid = try allocator.alloc([]u8, n);
    errdefer allocator.free(grid);

    for (grid) |*row, i| {
        row.* = data[(i*n)..(i*n+n)];
    }

    return grid;
}
fn gridFree(allocator: std.mem.Allocator, grid: []const[]u8) void {
    var n = grid.len;
    var data = @ptrCast([*]u8, grid[0])[0..(n*n)];
    allocator.free(data);
    allocator.free(grid);
}

fn gridPrint(out: anytype, grid: []const[]const u8) !void {
    for (grid) |row| {
        try std.fmt.format(out, "{s}\n", .{row});
    }
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var lines = std.mem.tokenize(u8, input, "\n");
    var line_ = lines.next();
    const n = line_.?.len;
    const grid = try gridAlloc(allocator, n);
    defer gridFree(allocator, grid);
    var i : u32 = 0;
    while (line_) |line| : ({line_ = lines.next(); i += 1;}) {
        if (line.len == 0) {
            break;
        }
        assert(i < n);
        assert(line.len == n);

        var row = grid[i];

        for (line) |c, j| {
            row[j] = c;
        }
    }
    var j : u32 = undefined;

    const Spot = struct {
        i: u32 = 0,
        j: u32 = 0,
        score: u32 = 0,
    };
    var best = Spot{};

    i = 0;
    while (i < n) : (i += 1) {
        j = 0;
        while (j < n) : (j += 1) {
            var h = grid[i][j];
            //If (i == 0 or j == 0 or i == n-1 or j == n-1) {
            //    continue;
            //}
            var left : u32 = 0;
            while (left < j) {
                left += 1;
                if (grid[i][j-left] >= h) {
                    break;
                }
            }
            var right : u32 = 0;
            while (j + right < n-1) {
                right += 1;
                if (grid[i][j+right] >= h) {
                    break;
                }
            }
            var up : u32 = 0;
            while (up < i) {
                up += 1;
                if (grid[i-up][j] >= h) {
                    break;
                }
            }
            var down : u32 = 0;
            while (i + down < n-1) {
                down += 1;
                if (grid[i+down][j] >= h) {
                    break;
                }
            }
            var candidate = Spot{ .i = i, .j = j, .score = left*right*up*down};
            if (candidate.score >= best.score) {
                best = candidate;
            }
        }
    }

    try std.fmt.format(stdout, "forest:\n", .{});
    try gridPrint(stdout, grid);

    try std.fmt.format(stdout, "best: @({}, {}) = {}\n", .{best.i, best.j, best.score});

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
