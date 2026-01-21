pub const HookSingleton = @import("hook_singleton.zig").HookSingleton;

pub const memory = @import("memory.zig");
pub const Module = @import("Module.zig");
pub const Pattern = @import("Pattern.zig");

comptime {
    _ = @import("Pattern.zig");
}
