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

    pub fn notImplemented(cpu: *CPU, instruction: *const instructions.Instruction) void {
        @panic("Instructions not implemented\n");
    }

    pub fn pushReg(self: *CPU, instruction: *const instructions.Instruction) void {
        self.esp -= 4;
        var loc = @intToPtr(*u32, self.esp);
        loc.* = self.getRegisterValue(instruction.reg_from.?);
    }

    pub fn popReg(self: *CPU, instruction: *const instructions.Instruction) void {
        var loc = @intToPtr(*u32, self.esp);
        self.setRegisterValue(instruction.reg_from.?, loc.*);
        self.esp += 4;
    }

    pub fn movReg32ToRM32(self: *CPU, instruction: *const instructions.Instruction) void {
        switch (instruction.reg_addr_mode.?) {
            .Reg => {
                const from_val = self.getRegisterValue(instruction.reg_from.?);
                self.setRegisterValue(instruction.reg_to, from_val);
            },
            .RegAddrDisplace8 => {
                var reg_val = self.getRegisterValue(instruction.reg_to);
                if (instruction.displacement8.? < 0) {
                    const abs_displacement = std.math.absCast(instruction.displacement8.?);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, instruction.displacement8.?);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                reg_pointing_to.* = self.getRegisterValue(instruction.reg_from.?);
            },
            else => @panic("TODO"),
        }
    }

    pub fn movImm32ToRM32(self: *CPU, instruction: *const instructions.Instruction) void {
        switch (instruction.reg_addr_mode.?) {
            .RegAddrDisplace8 => {
                var reg_val = self.getRegisterValue(instruction.reg_to);
                if (instruction.displacement8.? < 0) {
                    const abs_displacement = std.math.absCast(instruction.displacement8.?);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, instruction.displacement8.?);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                reg_pointing_to.* = instruction.immediate_u32.?;
            },
            else => @panic("TODO"),
        }
    }

    pub fn movRM32ToReg32(self: *CPU, instruction: *const instructions.Instruction) void {
        switch (instruction.reg_addr_mode.?) {
            .RegAddrDisplace8 => {
                var reg_val = self.getRegisterValue(instruction.reg_to);
                if (instruction.displacement8.? < 0) {
                    const abs_displacement = std.math.absCast(instruction.displacement8.?);
                    reg_val -= abs_displacement;
                } else {
                    reg_val += @intCast(u32, instruction.displacement8.?);
                }
                const reg_pointing_to = @intToPtr(*u32, reg_val);
                self.setRegisterValue(instruction.reg_from.?, reg_pointing_to.*);
            },
            else => @panic("TODO"),
        }
    }

    pub fn addImm8RM32(self: *CPU, instruction: *const instructions.Instruction) void {
        switch(instruction.reg_addr_mode.?) {
            .Reg => {
                var new_reg_val = self.getRegisterValue(instruction.reg_to);

                if (instruction.immediate_i8.? < 0) {
                    const abs_imm8 = std.math.absCast(instruction.immediate_i8.?);
                    new_reg_val -= abs_imm8;
                } else {
                    new_reg_val += @intCast(u32, instruction.immediate_i8.?);
                }
                self.setRegisterValue(instruction.reg_to, new_reg_val);
            },
            else => @panic("TODO"),
        }
    }

    pub fn subImm8RM32(self: *CPU, instruction: *const instructions.Instruction) void {
        switch(instruction.reg_addr_mode.?) {
            .Reg => {
                var new_reg_val = self.getRegisterValue(instruction.reg_to);

                if (instruction.immediate_i8.? < 0) {
                    const abs_imm8 = std.math.absCast(instruction.immediate_i8.?);
                    new_reg_val += abs_imm8;
                } else {
                    new_reg_val -= @intCast(u32, instruction.immediate_i8.?);
                }
                self.setRegisterValue(instruction.reg_to, new_reg_val);
            },
            else => @panic("TODO"),
        }
    }

    pub fn shiftLeftImm8(self: *CPU, instruction: *const instructions.Instruction) void {
        // TODO: shift with u8
        const new_reg_val = self.getRegisterValue(instruction.reg_to) << @intCast(u5, instruction.immediate_u8.?);
        self.setRegisterValue(instruction.reg_to, new_reg_val);
    }

    pub fn andImm8(self: *CPU, instruction: *const instructions.Instruction) void {
        const new_reg_val = self.getRegisterValue(instruction.reg_to) & instruction.immediate_u8.?;
        self.setRegisterValue(instruction.reg_to, new_reg_val);
    }

    pub fn ret(self: *CPU, instruction: *const instructions.Instruction) void {
        std.log.info("Returning: {}\n", .{self.eax});
    }

    // TODO set eflags register

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
