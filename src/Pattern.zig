const std = @import("std");
const Module = @import("Module.zig");

const Pattern = @This();

expected_bytes: []const ?u8,

pub const Style = enum {
    ghidra,
    ida,
};

pub fn parse(style: Style, comptime data: []const u8) Pattern {
    @setEvalBranchQuota(data.len * 2);
    var result: []const ?u8 = &.{};

    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        switch (data[i]) {
            ' ' => if (style == .ida) continue,
            '.' => if (style == .ghidra) {
                result = result ++ .{null};
                continue;
            },
            '?' => if (style == .ida) {
                result = result ++ .{null};
                i += 1;
                continue;
            },
            '\\', 'x' => {
                if (style == .ghidra) continue;
            },
            '0'...'9', 'A'...'Z', 'a'...'f' => {
                var out_byte: [1]u8 = undefined;
                _ = std.fmt.hexToBytes(&out_byte, data[i..][0..2]) catch unreachable;
                result = result ++ .{out_byte[0]};
                i += 1;
                continue;
            },
            else => {},
        }
        @compileError(std.fmt.comptimePrint("Unknown byte parsing pattern: 0x{c} in {s}", .{ data[i], data }));
    }

    return .{ .expected_bytes = result };
}

pub fn searchSlice(comptime self: Pattern, haystack: []const u8) ?[]const u8 {
    if (self.expected_bytes.len == 0) @compileError("Pattern must be at least one byte");

    haystack_scan: for (0..haystack.len) |i| {
        inline for (0.., self.expected_bytes) |j, expected| {
            const byte = expected orelse continue;
            if (haystack[i..][j] != byte) continue :haystack_scan;
        }
        return haystack[i..][0..self.expected_bytes.len];
    }

    return null;
}

pub fn findInModule(comptime self: Pattern, module: Module) ![]const u8 {
    return self.searchSlice(try module.slice()) orelse return error.PatternNotFound;
}

test Pattern {
    const global: []const u8 = &.{ 0x50, 0x40, 0x30, 0x20, 0x40, 0x50, 0x60 };
    const pattern: Pattern = .{ .expected_bytes = &.{ 0x40, null, null, 0x40 } };

    const found = pattern.searchSlice(global);

    try std.testing.expect(found != null);
    try std.testing.expectEqualSlices(u8, found.?, global[1..5]);
}
