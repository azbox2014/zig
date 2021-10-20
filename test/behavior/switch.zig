const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqual = std.testing.expectEqual;

test "switch with numbers" {
    try testSwitchWithNumbers(13);
}

fn testSwitchWithNumbers(x: u32) !void {
    const result = switch (x) {
        1, 2, 3, 4...8 => false,
        13 => true,
        else => false,
    };
    try expect(result);
}

test "switch with all ranges" {
    try expect(testSwitchWithAllRanges(50, 3) == 1);
    try expect(testSwitchWithAllRanges(101, 0) == 2);
    try expect(testSwitchWithAllRanges(300, 5) == 3);
    try expect(testSwitchWithAllRanges(301, 6) == 6);
}

fn testSwitchWithAllRanges(x: u32, y: u32) u32 {
    return switch (x) {
        0...100 => 1,
        101...200 => 2,
        201...300 => 3,
        else => y,
    };
}

test "implicit comptime switch" {
    const x = 3 + 4;
    const result = switch (x) {
        3 => 10,
        4 => 11,
        5, 6 => 12,
        7, 8 => 13,
        else => 14,
    };

    comptime {
        try expect(result + 1 == 14);
    }
}

test "switch on enum" {
    const fruit = Fruit.Orange;
    nonConstSwitchOnEnum(fruit);
}
const Fruit = enum {
    Apple,
    Orange,
    Banana,
};
fn nonConstSwitchOnEnum(fruit: Fruit) void {
    switch (fruit) {
        Fruit.Apple => unreachable,
        Fruit.Orange => {},
        Fruit.Banana => unreachable,
    }
}

test "switch statement" {
    try nonConstSwitch(SwitchStatementFoo.C);
}
fn nonConstSwitch(foo: SwitchStatementFoo) !void {
    const val = switch (foo) {
        SwitchStatementFoo.A => @as(i32, 1),
        SwitchStatementFoo.B => 2,
        SwitchStatementFoo.C => 3,
        SwitchStatementFoo.D => 4,
    };
    try expect(val == 3);
}
const SwitchStatementFoo = enum { A, B, C, D };

test "switch with multiple expressions" {
    const x = switch (returnsFive()) {
        1, 2, 3 => 1,
        4, 5, 6 => 2,
        else => @as(i32, 3),
    };
    try expect(x == 2);
}
fn returnsFive() i32 {
    return 5;
}

const Number = union(enum) {
    One: u64,
    Two: u8,
    Three: f32,
};

const number = Number{ .Three = 1.23 };

fn returnsFalse() bool {
    switch (number) {
        Number.One => |x| return x > 1234,
        Number.Two => |x| return x == 'a',
        Number.Three => |x| return x > 12.34,
    }
}
test "switch on const enum with var" {
    try expect(!returnsFalse());
}

test "switch on type" {
    try expect(trueIfBoolFalseOtherwise(bool));
    try expect(!trueIfBoolFalseOtherwise(i32));
}

fn trueIfBoolFalseOtherwise(comptime T: type) bool {
    return switch (T) {
        bool => true,
        else => false,
    };
}

test "switching on booleans" {
    try testSwitchOnBools();
    comptime try testSwitchOnBools();
}

fn testSwitchOnBools() !void {
    try expect(testSwitchOnBoolsTrueAndFalse(true) == false);
    try expect(testSwitchOnBoolsTrueAndFalse(false) == true);

    try expect(testSwitchOnBoolsTrueWithElse(true) == false);
    try expect(testSwitchOnBoolsTrueWithElse(false) == true);

    try expect(testSwitchOnBoolsFalseWithElse(true) == false);
    try expect(testSwitchOnBoolsFalseWithElse(false) == true);
}

fn testSwitchOnBoolsTrueAndFalse(x: bool) bool {
    return switch (x) {
        true => false,
        false => true,
    };
}

fn testSwitchOnBoolsTrueWithElse(x: bool) bool {
    return switch (x) {
        true => false,
        else => true,
    };
}

fn testSwitchOnBoolsFalseWithElse(x: bool) bool {
    return switch (x) {
        false => true,
        else => false,
    };
}

test "u0" {
    var val: u0 = 0;
    switch (val) {
        0 => try expect(val == 0),
    }
}

test "undefined.u0" {
    var val: u0 = undefined;
    switch (val) {
        0 => try expect(val == 0),
    }
}

test "switch with disjoint range" {
    var q: u8 = 0;
    switch (q) {
        0...125 => {},
        127...255 => {},
        126...126 => {},
    }
}

test "switch variable for range and multiple prongs" {
    const S = struct {
        fn doTheTest() !void {
            var u: u8 = 16;
            try doTheSwitch(u);
            comptime try doTheSwitch(u);
            var v: u8 = 42;
            try doTheSwitch(v);
            comptime try doTheSwitch(v);
        }
        fn doTheSwitch(q: u8) !void {
            switch (q) {
                0...40 => |x| try expect(x == 16),
                41, 42, 43 => |x| try expect(x == 42),
                else => try expect(false),
            }
        }
    };
    _ = S;
}

var state: u32 = 0;
fn poll() void {
    switch (state) {
        0 => {
            state = 1;
        },
        else => {
            state += 1;
        },
    }
}

test "switch on global mutable var isn't constant-folded" {
    while (state < 2) {
        poll();
    }
}
