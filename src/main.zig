const std = @import("std");
const builtin = @import("builtin");
const cpu = @import("cpu.zig");
const instructions = @import("instructions.zig");

const program = [_]u8{
    0x55,                                       // push   ebp
    0x89, 0xe5,                                 // mov    ebp,esp
    0x50,                                       // push   eax
    0xc7, 0x45, 0xfc, 0x01, 0x00, 0x00, 0x00,   // mov    DWORD PTR [ebp-0x4],0x1
    0x8b, 0x45, 0xfc,                           // mov    eax,DWORD PTR [ebp-0x4]
    0x83, 0xc4, 0x04,                           // add    esp,0x4
    0x5d,                                       // pop    ebp
    0xc3,                                       // ret
};

const program2 = [_]u8{
    0x55,                                       // push   ebp
    0x89, 0xe5,                                 // mov    ebp,esp
    0x83, 0xec, 0x18,                           // sub    esp,0x18
    0xc7, 0x45, 0xf8, 0x01, 0x00, 0x00, 0x00,   // mov    DWORD PTR [ebp-0x8],0x1
    0x8b, 0x45, 0xf8,                           // mov    eax,DWORD PTR [ebp-0x8]
    0x83, 0xc0, 0x01,                           // add    eax,0x1
    0x89, 0x45, 0xf4,                           // mov    DWORD PTR [ebp-0xc],eax
    0x8b, 0x45, 0xf4,                           // mov    eax,DWORD PTR [ebp-0xc]
    0x89, 0x45, 0xf8,                           // mov    DWORD PTR [ebp-0x8],eax
    0x8b, 0x4d, 0xf8,                           // mov    ecx,DWORD PTR [ebp-0x8]
    0x8b, 0x4d, 0xfc,                           // mov    DWORD PTR [ebp-0x4],ecx
    0x8b, 0x45, 0xfc,                           // mov    eax,DWORD PTR [ebp-0x4]
    0x83, 0xc4, 0x18,                           // add    esp,0x18
    0x5d,                                       // pop    ebp
    0xc3,                                       // ret
};

pub fn main() anyerror!void {
    if (builtin.endian != .Little) {
        @compileError("Not little endian");
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit());

    var my_cpu = cpu.CPU.init();

    var stack = try allocator.allocAdvanced(u8, @sizeOf(u32), 1025, .exact);
    defer allocator.free(stack);

    my_cpu.ebp = @ptrToInt(&stack[1024]);
    my_cpu.esp = @ptrToInt(&stack[1024]);

    std.log.info("CPU: {X}\n", .{my_cpu});
    std.log.info("Stack: {s}\n", .{std.fmt.fmtSliceHexUpper(stack)});

    var id = instructions.InstructionDecoder{
        .bytes = program2[0..],
        .index = 0,
    };
    while (id.next()) |inst| {
        std.log.info("In: {}", .{inst});
        my_cpu.execInstruction(inst);
        std.log.info("CPU: {X}\n", .{my_cpu});
        std.log.info("Stack: {s}\n", .{std.fmt.fmtSliceHexUpper(stack[1000..])});
    }
}
