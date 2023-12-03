const std = @import("std");
const TypeInfo = std.builtin.TypeInfo;
const print = std.debug.print;

fn makeTuple(comptime T: type) type {
    comptime var typeinfo = @typeInfo(T);
    comptime typeinfo.Struct.is_tuple = true;
    return @Type(typeinfo);
}
fn Vec2D(comptime T: type) type {
    return makeTuple(struct {
        i: T,
        j: T,
    });
    //comptime var typeinfo = @typeInfo(struct {
    //    i: T,
    //    j: T,
    //});

    //comptime typeinfo.Struct.is_tuple = true;
    //comptime typeinfo.Struct.is_tuple = true;
    //return @Type(typeinfo);
}

pub fn main() !void {
    print("Vec: {}\n", .{Vec2D(u8)});
    const Foo = struct {
        i: i8,
    };

    var foo1: Foo = .{
        .i = 1,
    };
    var foo2: Foo = .{
        .i = 2,
    };
    var fooPtr = &foo1;

    print("foo: {}\n", .{fooPtr});
    fooPtr.i = 3;
    print("foo: {}\n", .{fooPtr});
    fooPtr = &foo2;
    print("foo: {}\n", .{foo1});
}
