const std = @import("std");
const builtin = @import("builtin");
const cpu = @import("cpu.zig");
const instructions = @import("instructions.zig");

const program1 = [_]u8{
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
    0x89, 0x4d, 0xfc,                           // mov    DWORD PTR [ebp-0x4],ecx
    0x8b, 0x45, 0xfc,                           // mov    eax,DWORD PTR [ebp-0x4]
    0x83, 0xc4, 0x18,                           // add    esp,0x18
    0x5d,                                       // pop    ebp
    0xc3,                                       // ret
};

const program3 = [_]u8{
    0x55,                                       // push   %ebp
    0x89, 0xe5,                                 // mov    %esp,%ebp
    0x83, 0xec, 0x08,                           // sub    $0x8,%esp
    0xc7, 0x45, 0xf8, 0x01, 0x00, 0x00, 0x00,   // movl   $0x1,-0x8(%ebp)
    0x8b, 0x45, 0xf8,                           // mov    -0x8(%ebp),%eax
    0xc1, 0xe0, 0x03,                           // shl    $0x3,%eax
    0x89, 0x45, 0xf8,                           // mov    %eax,-0x8(%ebp)
    0x8b, 0x45, 0xf8,                           // mov    -0x8(%ebp),%eax
    0x83, 0xe0, 0x07,                           // and    $0x7,%eax
    0x89, 0x45, 0xf8,                           // mov    %eax,-0x8(%ebp)
    0x8b, 0x45, 0xf8,                           // mov    -0x8(%ebp),%eax
    0x89, 0x45, 0xfc,                           // mov    %eax,-0x4(%ebp)
    0x8b, 0x45, 0xfc,                           // mov    -0x4(%ebp),%eax
    0x83, 0xc4, 0x08,                           // add    $0x8,%esp
    0x5d,                                       // pop    %ebp
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
        .bytes = program3[0..],
        .index = 0,
    };
    while (id.next()) |inst| {
        std.log.info("In: {}", .{inst});
        inst.handler(&my_cpu, &inst);
        std.log.info("CPU: {X}\n", .{my_cpu});
        std.log.info("Stack: {s}\n", .{std.fmt.fmtSliceHexUpper(stack[1000..])});
    }
}

fn runProgram(program: []const u8) !u32 {
    if (builtin.endian != .Little) {
        @compileError("Not little endian");
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit());

    var my_cpu = cpu.CPU.init();

    var stack = try allocator.allocAdvanced(u8, @sizeOf(u32), 1024, .exact);
    defer allocator.free(stack);

    my_cpu.ebp = @ptrToInt(&stack[1023]) + 1;
    my_cpu.esp = @ptrToInt(&stack[1023]) + 1;

    var id = instructions.InstructionDecoder{
        .bytes = program,
        .index = 0,
    };
    while (id.next()) |inst| {
        inst.handler(&my_cpu, &inst);
    }
    return my_cpu.eax;
}

test "Test sample 1" {
    std.testing.expectEqual(try runProgram(program1[0..]), 1);
}

test "Test sample 2" {
    std.testing.expectEqual(try runProgram(program2[0..]), 2);
}

test "Test sample 3" {
    std.testing.expectEqual(try runProgram(program3[0..]), 0);
}
