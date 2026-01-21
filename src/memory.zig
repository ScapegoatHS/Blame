const std = @import("std");

const Pattern = @import("Pattern.zig");
const Module = @import("Module.zig");

pub fn resolveRipDisplacement(comptime T: type, instruction: []const u8, offset: *const [4]u8) T {
    const rip_offset = std.mem.readInt(u32, offset, .little);
    return @ptrCast(@alignCast(instruction.ptr[instruction.len..][rip_offset..]));
}

pub const Function = struct {
    pub const Location = union(enum) {
        pattern: Pattern,
        offset: usize,
        proc: [:0]const u8,
    };

    module: [:0]const u8,
    location: Location,
    Type: type,

    pub fn inCurrentProcess(comptime self: Function) !self.Type {
        const module: Module = try .fromCurrentProcess(self.module);
        switch (self.location) {
            .pattern => |pattern| {
                const slice = try pattern.findInModule(module);
                return @ptrCast(slice.ptr);
            },
            .offset => |offset| {
                const module_memory = try module.slice();
                return @ptrCast(module_memory.ptr + offset);
            },
            .proc => |proc_name| {
                return @ptrCast(module.getProcAddress(proc_name));
            },
        }
    }
};

pub const Instruction = struct {
    module: [:0]const u8,
    pattern: Pattern,

    pub fn inCurrentProcess(comptime self: Instruction) ![]const u8 {
        return try self.pattern.findInModule(try .fromCurrentProcess(self.module));
    }

    pub fn inCurrentProcessMutable(comptime self: Instruction) ![]u8 {
        return @constCast(try self.inCurrentProcess());
    }
};
