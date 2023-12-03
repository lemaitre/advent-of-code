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
    const gridView = try gridAlloc(allocator, n);
    defer gridFree(allocator, gridView);
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

    i = 0;
    while (i < n) : (i += 1) {
        j = 0;
        while (j < n) : (j += 1) {
            if (i == 0 or j == 0 or i == n-1 or j == n-1) {
                gridView[i][j] = '.';
                continue;
            }
            var left = leftBlk: {
                var h : u8 = 0;
                var k : u32 = 0;
                while (k < j) : (k += 1) {
                    h = @maximum(h, grid[i][k]);
                }
                break :leftBlk h;
            };
            var right = rightBlk: {
                var h : u8 = 0;
                var k : u32 = j+1;
                while (k < n) : (k += 1) {
                    h = @maximum(h, grid[i][k]);
                }
                break :rightBlk h;
            };
            var up = upBlk: {
                var h : u8 = 0;
                var k : u32 = 0;
                while (k < i) : (k += 1) {
                    h = @maximum(h, grid[k][j]);
                }
                break :upBlk h;
            };
            var down = downBlk: {
                var h : u8 = 0;
                var k : u32 = i+1;
                while (k < n) : (k += 1) {
                    h = @maximum(h, grid[k][j]);
                }
                break :downBlk h;
            };
            var h = @minimum(@minimum(left, right), @minimum(up, down));
            gridView[i][j] = h;
        }
    }

    var count : u32 = 0;
    i = 0;
    while (i < n) : (i += 1) {
        j = 0;
        while (j < n) : (j += 1) {
            if (grid[i][j] > gridView[i][j] or gridView[i][j] == 0) {
                count += 1;
            }
        }
    }

    try std.fmt.format(stdout, "forest:\n", .{});
    try gridPrint(stdout, grid);
    try std.fmt.format(stdout, "forest view:\n", .{});
    try gridPrint(stdout, gridView);

    try std.fmt.format(stdout, "count: {}\n", .{count});

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
