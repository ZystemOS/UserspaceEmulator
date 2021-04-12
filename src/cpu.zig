const std = @import("std");
const instructions = @import("instructions.zig");

pub const Register = enum {
    EAX = 0,
    ECX = 1,
    EDX = 2,
    EBX = 3,
    ESP = 4,
    EBP = 5,
    ESI = 6,
    EDI = 7,
};

pub const CPU = struct {
    eip: u32,
    
    esp: u32,
    ebp: u32,

    eax: u32,
    ecx: u32,
    edx: u32,
    ebx: u32,

    esi: u32,
    edi: u32,

    eflags: u32,

    const Self = @This();

    fn getRegPart(self: *self, comptime Width: type, register: Register) Width {
        if (Width != u8 or Width != u16 or Width != u32) {
            @compileError("Expects u8, u16 or u32 only");
        }
        return switch (register) {
            .EAX => @truncate(Width, self.eax),
            .EBX => @truncate(Width, self.ebx),
            .ECX => @truncate(Width, self.ecx),
            .EDX => @truncate(Width, self.edx),
            .ESI => @truncate(Width, self.esi),
            .EDI => @truncate(Width, self.edi),
        };
    }

    fn getRegisterValue(self: *Self, reg: Register) u32 {
        return switch (reg) {
            .EAX => self.eax,
            .ECX => self.ecx,
            .EDX => self.edx,
            .EBX => self.ebx,
            .ESP => self.esp,
            .EBP => self.ebp,
            .ESI => self.esi,
            .EDI => self.edi,
        };
    }

    fn setRegisterValue(self: *Self, reg: Register, value: u32) void {
        switch (reg) {
            .EAX => self.eax = value,
            .ECX => self.ecx = value,
            .EDX => self.edx = value,
            .EBX => self.ebx = value,
            .ESP => self.esp = value,
            .EBP => self.ebp = value,
            .ESI => self.esi = value,
            .EDI => self.edi = value,
        }
    }

    pub fn execInstruction(self: *CPU, instruction: instructions.Instructions) void {
        switch (instruction) {
            .Push => |push_val| {
                self.esp -= 4;
                var loc = @intToPtr(*u32, self.esp);
                loc.* = self.getRegisterValue(push_val.reg);
            },
            .Pop => |pop_val| {
                var loc = @intToPtr(*u32, self.esp);
                self.setRegisterValue(pop_val.reg, loc.*);
                self.esp += 4;
            },
            .MovRegToReg => |mov_val| {
                const from_val = self.getRegisterValue(mov_val.reg_from);
                self.setRegisterValue(mov_val.reg_to, from_val);
            },
            .MovImm32RegLoc => |mov_val| {
                var reg_val = self.getRegisterValue(mov_val.reg);
                if (mov_val.displacement < 0) {
                    const abs_displacement = std.math.absCast(mov_val.displacement);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, mov_val.displacement);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                reg_pointing_to.* = mov_val.immediate;
            },
            .MovRegLocToReg => |mov_val| {
                var reg_val = self.getRegisterValue(mov_val.reg_from);
                if (mov_val.displacement < 0) {
                    const abs_displacement = std.math.absCast(mov_val.displacement);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, mov_val.displacement);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                self.setRegisterValue(mov_val.reg_to, reg_pointing_to.*);
            },
            .MovRegToRegLoc => |mov_val| {
                var reg_val = self.getRegisterValue(mov_val.reg_to);
                if (mov_val.displacement < 0) {
                    const abs_displacement = std.math.absCast(mov_val.displacement);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, mov_val.displacement);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                reg_pointing_to.* =self.getRegisterValue(mov_val.reg_from);
            },
            .AddImm8Reg => |add_val| {
                var new_reg_val = self.getRegisterValue(add_val.reg);
                
                if (add_val.imm8 < 0) {
                    const abs_imm8 = std.math.absCast(add_val.imm8);
                    new_reg_val -= abs_imm8;
                } else {
                    new_reg_val += @intCast(u32, add_val.imm8);
                }
                self.setRegisterValue(add_val.reg, new_reg_val);
            },
            .Ret => {
                std.log.info("Returning: {}\n", .{self.eax});
            },
        }
    }

    pub fn init() CPU {
        return .{
            .eip = 0,
            .esp = 0,
            .ebp = 0,
            .eax = 0,
            .ecx = 0,
            .edx = 0,
            .ebx = 0,
            .esi = 0,
            .edi = 0,
            .eflags = 0,
        };
    }
};
