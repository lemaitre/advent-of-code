const std = @import("std");
const assert = std.debug.assert;
const stdout = std.io.getStdOut().writer();

const TreeNode = struct {
    name: []const u8,
    size: usize,
    entries: ?std.ArrayListUnmanaged(TreeNode),
    parent: *TreeNode,

    fn deinit(self: *TreeNode, allocator: std.mem.Allocator) void {
        if (self.entries) |*nodes| {
            for (nodes.items) |*node| {
                node.deinit(allocator);
            }
            nodes.deinit(allocator);
        }
    }

    fn addFile(self: *TreeNode, allocator: std.mem.Allocator, name: []const u8, size: usize) !void {
        try self.entries.?.append(allocator, .{ .name = name, .size = size, .entries = null, .parent = self });
    }

    fn addDir(self: *TreeNode, allocator: std.mem.Allocator, name: []const u8) !void {
        try self.entries.?.append(allocator, .{ .name = name, .size = 0, .entries = .{}, .parent = self });
    }

    fn find(self: TreeNode, entry_name: []const u8) ?*TreeNode {
        if (self.entries) |nodes| {
            for (nodes.items) |*node| {
                if (std.mem.eql(u8, node.name, entry_name)) {
                    return node;
                }
            }
        }
        return null;
    }

    fn recSize(self: *TreeNode) usize {
        if (self.entries) |nodes| {
            var size : usize = 0;
            for (nodes.items) |*node| {
                size += node.recSize();
            }
            self.size = size;
        }
        
        return self.size;
    }

    fn printInternal(self: TreeNode, out: anytype, offset: u32) void {
        var i : u32 = 0;
        while (i < offset) : (i += 1) {
            _ = out.write("  ") catch undefined;
        }
        if (self.entries) |nodes| {
            _ = std.fmt.format(out, "- {s} (dir: {})\n", .{self.name, self.size}) catch undefined;
            for (nodes.items) |node| {
                node.printInternal(out, offset + 1);
            }
        } else {
            _ = std.fmt.format(out, "- {s} (file: {})\n", .{self.name, self.size}) catch undefined;
        }
    }
    fn print(self: TreeNode, out: anytype) !void {
        self.printInternal(out, 0);
    }
};


fn calcSize(root: TreeNode, threshold: usize) usize {
    var sum : usize = 0;
    if (root.entries) |nodes| {
        if (root.size <= threshold) {
            sum = root.size;
        }
        for (nodes.items) |node| {
            sum += calcSize(node, threshold);
        }
    }
    return sum;
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) !void {
    var root : TreeNode = undefined;
    root = .{ .name = "/", .size = 0, .entries = .{}, .parent = &root };
    defer root.deinit(allocator);
    var lines = std.mem.tokenize(u8, input, "\n");
    var line_ = lines.next();

    var current_dir = &root;

    while (line_ != null and line_.?.len > 0) {
        var line = line_.?;
        _ = try std.fmt.format(stdout, "# {s}\n", .{line});
        assert(line.len >= 4);
        assert(std.mem.eql(u8, line[0..2], "$ "));

        var cmd = line[2..4];
        if (std.mem.eql(u8, cmd, "cd")) {
            assert(std.mem.eql(u8, line[0..5], "$ cd "));
            var entry_name = line[5..line.len];
            if (std.mem.eql(u8, entry_name, "/")) {
                current_dir = &root;
            } else if (std.mem.eql(u8, entry_name, "..")) {
                current_dir = current_dir.parent;
            } else {
                current_dir = current_dir.find(entry_name).?;
            }
            line_ = lines.next();
        } else if (std.mem.eql(u8, cmd, "ls")) {
            assert(std.mem.eql(u8, line, "$ ls"));

            line_ = lines.next();
            while (line_ != null and line_.?.len > 0 and line_.?[0] != '$') {
                line = line_.?;
                _ = try std.fmt.format(stdout, "# {s}\n", .{line});
                var tokens = std.mem.tokenize(u8, line, " ");
                var first = tokens.next().?;
                var second = tokens.next().?;
                assert(tokens.next() == null);

                if (std.mem.eql(u8, first, "dir")) {
                    try current_dir.addDir(allocator, second);
                } else {
                    var size = try std.fmt.parseInt(usize, first, 10);
                    try current_dir.addFile(allocator, second, size);
                }
                line_ = lines.next();
            }
        } else {
            assert(false);
        }
    }

    _ = root.recSize();

    try root.print(stdout);

    try std.fmt.format(stdout, "size: {}\n", .{calcSize(root, 100000)});
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
