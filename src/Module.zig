const win32 = @import("win32").everything;

const Error = error{WinApiError};

const Module = @This();

pub fn win32Fallible(ret: win32.BOOL) !void {
    if (ret == win32.FALSE) return Error.WinApiError;
}

pub fn win32Nullable(ret: anytype) !@TypeOf(ret.?) {
    if (ret == null) return Error.WinApiError;
    return ret.?;
}

pub const Process = struct {
    handle: win32.HANDLE,

    pub fn current() Process {
        return .{ .handle = win32.GetCurrentProcess().? };
    }
};

pub const Info = struct {
    image_size: usize,

    pub fn fromWin32ModuleInfo(module_info: win32.MODULEINFO) Info {
        return .{
            .image_size = module_info.SizeOfImage,
        };
    }
};

process: Process,
handle: win32.HINSTANCE,

pub fn fromCurrentProcess(name: [:0]const u8) !Module {
    return .{
        .process = .current(),
        .handle = try win32Nullable(win32.GetModuleHandleA(name)),
    };
}

pub fn info(self: Module) !Info {
    var module_info: win32.MODULEINFO = undefined;
    try win32Fallible(win32.K32GetModuleInformation(
        self.process.handle,
        self.handle,
        &module_info,
        @sizeOf(win32.MODULEINFO),
    ));

    return .fromWin32ModuleInfo(module_info);
}

pub fn slice(self: Module) ![]const u8 {
    const inf = try self.info();
    const start: [*]u8 = @ptrCast(self.handle);

    return start[0..inf.image_size];
}

pub fn getProcAddress(self: Module, proc_name: [:0]const u8) ?*const anyopaque {
    return @ptrCast(win32.GetProcAddress(self.handle, proc_name));
}
