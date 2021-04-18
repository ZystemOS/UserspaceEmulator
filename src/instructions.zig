const std = @import("std");
const cpu = @import("cpu.zig");

const PushType = struct {
    reg: cpu.Register,
};

const PopType = struct {
    reg: cpu.Register,
};

const MovRegToRegType = struct {
    reg_to: cpu.Register,
    reg_from: cpu.Register,
};

// move register location to reg
const MovImm32RegLocType = struct {
    reg: cpu.Register,
    displacement: i8,
    immediate: u32,
};

// move register location to reg
const MovRegLocToRegType = struct {
    reg_to: cpu.Register,
    reg_from: cpu.Register,
    displacement: i8,
};

// move register to reg location
const MovRegToRegLocType = struct {
    reg_to: cpu.Register,
    reg_from: cpu.Register,
    displacement: i8,
};

const AddImm8RegType = struct {
    reg: cpu.Register,
    imm8: i8,
};

const SubImm8RegType = struct {
    reg: cpu.Register,
    imm8: i8,
};

const ShiftLeftImm8RegType = struct {
    reg: cpu.Register,
    imm8: u8,
};

const AndImm8RegType = struct {
    reg: cpu.Register,
    imm8: u8,
};

pub const Instructions = union(enum) {
    Push: PushType,
    Pop: PopType,
    MovRegToReg: MovRegToRegType,
    MovImm32RegLoc: MovImm32RegLocType,
    MovRegLocToReg: MovRegLocToRegType,
    MovRegToRegLoc: MovRegToRegLocType,
    AddImm8Reg: AddImm8RegType,
    SubImm8Reg: SubImm8RegType,
    ShiftLeftImm8Reg: ShiftLeftImm8RegType,
    AndImm8Reg: AndImm8RegType,
    Ret: void,
};

pub const RegAddrMode = enum(u2) {
    RegAddr,
    RegAddrDisplace8,
    RegAddrDisplace16,
    Reg,
};

const Fn = fn(self: *cpu.CPU, instruction: *const Instruction) void;
pub const root_table: [256]InstructionTable = brk: {
    var root_table_init: [256]InstructionTable = [_]InstructionTable{InstructionTable{}} ** 256;

    // PUSH instructions
    root_table_init[0x50] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x51] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x52] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x53] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x54] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x55] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x56] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};
    root_table_init[0x57] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.pushReg};

    // POP instructions
    root_table_init[0x58] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x59] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5A] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5B] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5C] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5D] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5E] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};
    root_table_init[0x5F] = InstructionTable{.has_opcode_reg_encoded = true, .handler = cpu.CPU.popReg};

    var slash_83: [8]InstructionTable = [_]InstructionTable{InstructionTable{}} ** 8;
    // ADD
    slash_83[0] = InstructionTable{
        .has_mod_r_m = true,
        .has_immediate_i8 = true,

        .handler = cpu.CPU.addImm8RM32,
    };
    // AND
    slash_83[4] = InstructionTable{
        .has_mod_r_m = true,
        .has_immediate_u8 = true,

        .handler = cpu.CPU.andImm8,
    };
    // SUB
    slash_83[5] = InstructionTable{
        .has_mod_r_m = true,
        .has_immediate_i8 = true,

        .handler = cpu.CPU.subImm8RM32,
    };
    root_table_init[0x83] = InstructionTable{
        .has_mod_r_m = true,
        .has_slash = true,

        .next_table = slash_83[0..],
    };

    // MOV REG32 to RM32
    root_table_init[0x89] = InstructionTable{.has_mod_r_m = true, .handler = cpu.CPU.movReg32ToRM32};

    // MOV RM32 to REG32
    root_table_init[0x8B] = InstructionTable{.has_mod_r_m = true, .handler = cpu.CPU.movRM32ToReg32};

    // SHIFT
    var slash_c1: [8]InstructionTable = [_]InstructionTable{InstructionTable{}} ** 8;
    slash_c1[4] = InstructionTable{
        .has_mod_r_m = true,
        .has_immediate_u8 = true,

        .handler = cpu.CPU.shiftLeftImm8,
    };
    root_table_init[0xC1] = InstructionTable{
        .has_mod_r_m = true,
        .has_slash = true,

        .next_table = slash_c1[0..],
    };

    // RET
    root_table_init[0xC3] = InstructionTable{.handler = cpu.CPU.ret};

    // MOV IMM32 to RM32
    var slash_c7: [8]InstructionTable = [_]InstructionTable{InstructionTable{}} ** 8;
    slash_c7[0] = InstructionTable{
        .has_mod_r_m = true,
        .has_immediate_u32 = true,

        .handler = cpu.CPU.movImm32ToRM32,
    };
    root_table_init[0xC7] = InstructionTable{
        .has_mod_r_m = true,
        // .has_immediate_u32 = true,
        .has_slash = true,

        // .handler = cpu.CPU.movReg32ToRM
        .next_table = slash_c7[0..],
    };

    break :brk root_table_init;
};

pub const InstructionTable = struct {
    handler: Fn = cpu.CPU.notImplemented,

    has_opcode_reg_encoded: bool = false,
    has_mod_r_m: bool = false,

    has_immediate_i8: bool = false,
    has_immediate_u8: bool = false,
    has_immediate_u32: bool = false,

    has_next_opcode: bool = false,
    has_slash: bool = false,
    next_table: []InstructionTable = &[_]InstructionTable{},
};

pub const Instruction = struct {
    opcodes: [3]u8,

    reg_addr_mode: ?RegAddrMode,

    reg_to: cpu.Register,
    reg_from: ?cpu.Register,

    displacement8: ?i8,
    displacement16: ?i16,

    immediate_i8: ?i8,
    immediate_u8: ?u8,
    immediate_u32: ?u32,

    handler: Fn,
};

fn getRegister(opcode: u32) cpu.Register {
    return @intToEnum(cpu.Register, @intCast(u3, opcode & 0x7));
}

pub const InstructionDecoder = struct {
    bytes: []const u8,
    index: u32,

    pub fn next(self: *InstructionDecoder) ?Instruction {
        if (self.bytes.len == self.index) {
            return null;
        }
        const opcode = self.bytes[self.index];
        self.index += 1;
        var inst_table = root_table[opcode];

        // Parse the opcodes
        var opcodes: [3]u8 = undefined;
        opcodes[0] = opcode;

        var next_opcode_index: u32 = 0;
        while (inst_table.has_next_opcode) {
            next_opcode_index += 1;
            const next_opcode = self.bytes[self.index];
            self.index += 1;
            inst_table = inst_table.next_table[next_opcode];
            opcodes[next_opcode_index] = next_opcode;
        }

        // Decode the MODR/M byte if there is one
        var reg_addr_mode: ?RegAddrMode = null;
        var reg_to: cpu.Register = undefined;
        var reg_from: ?cpu.Register = null;
        if (inst_table.has_mod_r_m) {
            const mod_r_m = self.bytes[self.index];
            self.index += 1;

            // Parse the register address mode
            reg_addr_mode = @intToEnum(RegAddrMode, @intCast(u2, mod_r_m >> 6));

            // Parse the Register to
            reg_to = @intToEnum(cpu.Register, @intCast(u3, mod_r_m & 0b111));

            // If is a slash instruction, then get the next table, else get the register from
            const op_or_reg = (mod_r_m >> 3) & 0b111;
            if (inst_table.has_slash) {
                inst_table = inst_table.next_table[op_or_reg];
            } else {
                if (inst_table.has_opcode_reg_encoded) {
                    reg_from = @intToEnum(cpu.Register, @intCast(u3, opcodes[0] & 0b111));
                } else {
                    reg_from = @intToEnum(cpu.Register, @intCast(u3, op_or_reg));
                }
            }
        } else {
            reg_from = @intToEnum(cpu.Register, @intCast(u3, opcodes[0] & 0b111));
        }

        // TODO: Parsing the SIB bytes

        // Parse the displacement
        var displacement8: ?i8 = null;
        var displacement16: ?i16 = null;
        if (reg_addr_mode) |mode| {
            if (mode == .RegAddrDisplace8) {
            // if (inst_table.has_displacement) {
                displacement8 = @bitCast(i8, self.bytes[self.index]);
                self.index += 1;
            }
            if (mode == .RegAddrDisplace16) {
            // if (inst_table.has_displacement) {
                displacement16 = @bitCast(i16, std.mem.bytesAsSlice(u16, self.bytes[self.index..self.index+1])[0]);
                self.index += 2;
            }
        }

        // Parse immediate
        var immediate_i8: ?i8 = null;
        var immediate_u8: ?u8 = null;
        var immediate_u32: ?u32 = null;
        if (inst_table.has_immediate_i8) {
            immediate_i8 = @bitCast(i8, self.bytes[self.index]);
            self.index += 1;
        } else if (inst_table.has_immediate_u8) {
            immediate_u8 = self.bytes[self.index];
            self.index += 1;
        } else if (inst_table.has_immediate_u32) {
            immediate_u32 = std.mem.bytesAsSlice(u32, self.bytes[self.index..self.index+4])[0];
            self.index += 4;
        }

        const inst = Instruction{
            .opcodes = opcodes,

            .reg_addr_mode = reg_addr_mode,

            .reg_to = reg_to,
            .reg_from = reg_from,

            .displacement8 = displacement8,
            .displacement16 = displacement16,

            .immediate_i8 = immediate_i8,
            .immediate_u8 = immediate_u8,
            .immediate_u32 = immediate_u32,

            .handler = inst_table.handler,

        };

        return inst;
        // if (inst_table.has_sib) {

        // }


        // MOD:
        // if 11 then is reg to reg
        // if 01 then from reg is the address of
        // return switch (opcode) {
        //     // Push REG
        //     0x50...0x57 => brk: {
        //         const inst = Instructions{.Push = .{.reg = getRegister(opcode)}};
        //         self.index += 1;
        //         break :brk inst;
        //     },
        //     else => {
        //         std.log.info("Not implemented: {X}", .{opcode});
        //         break :brk null;
        //     },
        // };
    }
};
