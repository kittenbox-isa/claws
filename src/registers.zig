const std = @import("std");

pub const Register = enum(u5) {
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    R8,
    R9,
    R10,
    R11,
    R12,
    R13,
    R14,
    R15,
    R16,
    R17,
    R18,
    R19,
    R20,
    R21,
    R22,
    R23,
    R24,
    R25,
    R26,
    R27,
    R28,
    R29,
    R30,
    R31,

    pub fn encode(self: Register) u5 {
        return @enumToInt(self);
    }

    pub fn decode(e: u5) Register {
        return @intToEnum(Register, e);
        
    }

    pub fn getName(self: Register) [:0]const u8 {
        return @tagName(self);
    }
};
