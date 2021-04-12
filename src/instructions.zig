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

pub const Instructions = union(enum) {
    Push: PushType,
    Pop: PopType,
    MovRegToReg: MovRegToRegType,
    MovImm32RegLoc: MovImm32RegLocType,
    MovRegLocToReg: MovRegLocToRegType,
    MovRegToRegLoc: MovRegToRegLocType,
    AddImm8Reg: AddImm8RegType,
    Ret: void,
};

fn getRegister(opcode: u32) cpu.Register {
    return @intToEnum(cpu.Register, @intCast(u3, opcode & 0x7));
}

pub const InstructionDecoder = struct {
    bytes: []const u8,
    index: u32,

    pub fn next(self: *InstructionDecoder) ?Instructions {
        if (self.bytes.len == self.index) {
            return null;
        }
        const opcode = self.bytes[self.index];
        // MOD:
        // if 11 then is reg to reg
        // if 01 then from reg is the address of
        return switch (opcode) {
            // Push REG
            0x50...0x57 => brk: {
                const inst = Instructions{.Push = .{.reg = getRegister(opcode)}};
                self.index += 1;
                break :brk inst;
            },
            // Pop REG
            0x58...0x5F => brk: {
                const inst = Instructions{.Pop = .{.reg = getRegister(opcode)}};
                self.index += 1;
                break :brk inst;
            },
            // Add
            0x83 => brk: {
                const mod_r_m = self.bytes[self.index+1];
                const mod = mod_r_m & 0xC0;
                if (mod != 0xC0) {
                    std.log.info("0x83 Not implemented: 0b{b}", .{mod});
                    break :brk null;
                }
                const inst = Instructions{.AddImm8Reg = .{
                    .reg = getRegister(mod_r_m),
                    .imm8 = @bitCast(i8, self.bytes[self.index+2])
                }};
                self.index += 3;
                break :brk inst;
            },
            // MOV REG/MEM => REG
            0x89 => brk: {
                // 0b xx  xxx      xxx
                //    mod reg_from reg_to
                const mod_r_m = self.bytes[self.index+1];
                const mod = mod_r_m & 0xC0;
                // MOV MEM => REG
                if (mod != 0xC0) {
                    const reg = getRegister(mod_r_m);
                    const displacement = @bitCast(i8, self.bytes[self.index+2]);
                    const inst = Instructions{.MovRegToRegLoc = .{
                        .reg_to = getRegister(mod_r_m),
                        .reg_from = getRegister(mod_r_m >> 3),
                        .displacement = displacement,
                    }};
                    self.index += 3;
                    break :brk inst;
                } else { // MOV REG => REG
                    const inst = Instructions{.MovRegToReg = .{
                        .reg_to = getRegister(mod_r_m),
                        .reg_from = getRegister(mod_r_m >> 3)
                    }};
                    self.index += 2;
                    break :brk inst;
                }
            },
            // MOV REG => REG/MEM
            0x8B => brk: {
                const mod_r_m = self.bytes[self.index+1];
                const mod = mod_r_m & 0xC0;
                if (mod != 0x40) {
                    std.log.info("0x8B Not implemented: 0b{b}", .{mod});
                    break :brk null;
                }
                const reg = getRegister(mod_r_m);
                const displacement = @bitCast(i8, self.bytes[self.index+2]);
                const inst = Instructions{.MovRegLocToReg = .{
                    .reg_to = getRegister(mod_r_m >> 3),
                    .reg_from = getRegister(mod_r_m),
                    .displacement = displacement,
                }};
                self.index += 3;
                break :brk inst;
            },
            // MOV IMM REG/MEM
            0xC7 => brk: {
                const mod_r_m = self.bytes[self.index+1];
                const mod = mod_r_m & 0xC0;
                if (mod != 0x40) {
                    std.log.info("0xC7 Not implemented: 0b{b}", .{mod});
                    break :brk null;
                }
                const reg = getRegister(mod_r_m);
                const displacement = @bitCast(i8, self.bytes[self.index+2]);
                const immediate = std.mem.bytesAsSlice(u32, self.bytes[self.index+3..self.index+7])[0];
                self.index += 7;
                const inst = Instructions{.MovImm32RegLoc = .{
                    .reg = reg,
                    .displacement = displacement,
                    .immediate = immediate
                }};
                break :brk inst;
            },
            0xC3 => brk: {
                const inst = Instructions{.Ret = {}};
                self.index += 1;
                break :brk inst;
            },
            else => brk: {
                std.log.info("Not implemented: {X}", .{opcode});
                break :brk null;
            },
        };
    }
};
