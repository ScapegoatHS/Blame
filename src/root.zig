pub const minhook = @import("minhook");

pub const HookSingleton = @import("hook_singleton.zig").HookSingleton;

pub const memory = @import("memory.zig");
pub const Module = @import("Module.zig");
pub const Pattern = @import("Pattern.zig");

pub fn init() !void {
    try minhook.init();
}
