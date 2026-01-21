const std = @import("std");
const minhook = @import("minhook");
const win32 = @import("win32").everything;

const memory = @import("memory.zig");

pub fn HookSingleton(comptime log_scope: @Type(.enum_literal), comptime function_ref: memory.Function, comptime detour_function: anytype) type {
    return struct {
        pub const scope = log_scope;
        pub const log = std.log.scoped(log_scope);

        pub const function = function_ref;
        pub const detour = detour_function;

        const Fn = @TypeOf(detour_function);

        pub var is_hooked: bool = false;

        pub var function_call_ptr: *const Fn = undefined;
        pub var minhook_hook: minhook.Hook(*const Fn) = undefined;
        pub var trampoline: *const Fn = undefined;

        pub fn create() !void {
            function_call_ptr = try function.inCurrentProcess();
            minhook_hook = try .create(function_call_ptr, detour_function, &trampoline);
        }

        pub fn createFromThunk(jmp_offset: usize) !void {
            const thunk_ref = try function.inCurrentProcess();
            const thunk_bytes: [*]const u8 = @ptrCast(thunk_ref);

            const jmp_displacement = std.mem.readInt(u32, &thunk_bytes[jmp_offset..][3..7].*, .little);
            const jmp_rip = thunk_bytes + jmp_offset + 7;

            const new_ptr: *const ?*const anyopaque = @ptrCast(@alignCast(jmp_rip + jmp_displacement));
            function_call_ptr = @ptrCast(new_ptr.*);

            log.info("Thunk offset: {x} + {x} = {x}", .{ @intFromPtr(jmp_rip), jmp_displacement, @intFromPtr(new_ptr) });

            minhook_hook = try .create(function_call_ptr, detour_function, &trampoline);
        }

        pub fn enable() !void {
            try minhook_hook.enable();
            log.info("Enabled hook! {x} -> {x}", .{ @intFromPtr(function_call_ptr), @intFromPtr(&detour_function) });
            is_hooked = true;
        }
    };
}
