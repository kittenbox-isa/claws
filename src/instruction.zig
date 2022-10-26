const std = @import("std");
const Reg = @import("registers.zig").Register;

const Instruction = @This();

op: Opcode,
data: Data,

pub fn encode(self: Instruction) u32 {
    const datum: u32 = @as(u32, self.op.encode()) << 25;
    switch (self.data) {
        .reg_imm => {
            datum |= @as(u32, self.data.reg_imm.r.encode()) << 20;
            datum |= @as(u32, self.data.reg_imm.imm);
        },
        .reg_reg => {
            datum |= @as(u32, self.data.reg_reg.r1.encode()) << 20;
            datum |= @as(u32, self.data.reg_reg.r2.encode()) << 15;
        },
        .reg_reg_imm => {
            datum |= @as(u32, self.data.reg_reg_imm.r1.encode()) << 20;
            datum |= @as(u32, self.data.reg_reg_imm.r2.encode()) << 15;
            datum |= @as(u32, self.data.reg_reg_imm.imm);
        },
        .reg_reg_n => {
            datum |= @as(u32, self.data.reg_reg_n.r1.encode()) << 20;
            datum |= @as(u32, self.data.reg_reg_n.r2.encode()) << 15;
            datum |= @as(u32, self.data.reg_reg_n.n);
        },
        .reg_reg_reg => {
            datum |= @as(u32, self.data.reg_reg_reg.r1.encode()) << 20;
            datum |= @as(u32, self.data.reg_reg_reg.r2.encode()) << 15;
            datum |= @as(u32, self.data.reg_reg_reg.r3.encode()) << 10;
        },
        .jalcc => {
            datum |= @as(u32, self.data.jalcc.r1.encode()) << 20;
            datum |= @as(u32, self.data.jalcc.r2.encode()) << 15;
            datum |= @as(u32, self.data.jalcc.r3.encode()) << 10;
            datum |= @as(u32, self.data.jalcc.r4.encode()) << 5;
            datum |= @as(u32, self.data.jalcc.cmp.encode());
        },
        .load => {
            datum |= @as(u32, self.data.load.r.encode()) << 20;
            datum |= @as(u32, self.data.load.mcd.encode()) << 16;
            datum |= @as(u32, self.data.load.imm);
        },
    }
    return datum;
}

pub fn decode(e: u32) Instruction {
    const op = Opcode.decode(@truncate(u7, e >> 25));
    const data: Data = switch (op) {
        .sta => blk: {
            const reg = @truncate(u5, e >> 20);
            const imm = @truncate(u16, e);
            break :blk .{
                .reg_imm = .{
                    .r = Reg.decode(reg),
                    .imm = imm,
                },
            };
        },
        .ldi => blk: {
            const reg = @truncate(u5, e >> 20);
            const mcd = @truncate(u4, e >> 16);
            const imm = @truncate(u16, e);
            break :blk .{
                .load = .{
                    .r = Reg.decode(reg),
                    .mcd = Data.Load.decode(mcd),
                    .imm = imm,
                },
            };
        },
        .ldr => blk: {
            const reg1 = @truncate(u5, e >> 20);
            const reg2 = @truncate(u5, e >> 15);
            const imm = @truncate(u15, e);
            break :blk .{
                .reg_reg_imm = .{
                    .r1 = Reg.decode(reg1),
                    .r2 = Reg.decode(reg2),
                    .imm = imm,
                },
            };
        },
        .lsl,
        .lsr,
        => blk: {
            const reg1 = @truncate(u5, e >> 20);
            const reg2 = @truncate(u5, e >> 15);
            const nnnn = @truncate(u5, e >> 10);
            break :blk .{
                .reg_reg_n = .{
                    .r1 = Reg.decode(reg1),
                    .r2 = Reg.decode(reg2),
                    .n = nnnn,
                },
            };
        },
        .str,
        .not,
        => blk: {
            const reg1 = @truncate(u5, e >> 20);
            const reg2 = @truncate(u5, e >> 15);
            break :blk .{
                .reg_reg = .{
                    .r1 = Reg.decode(reg1),
                    .r2 = Reg.decode(reg2),
                },
            };
        },
        .add,
        .sub,
        .@"or",
        .@"and",
        .xor,
        => blk: {
            const reg1 = @truncate(u5, e >> 20);
            const reg2 = @truncate(u5, e >> 15);
            const reg3 = @truncate(u5, e >> 10);
            break :blk .{
                .reg_reg_reg = .{
                    .r1 = Reg.decode(reg1),
                    .r2 = Reg.decode(reg2),
                    .r3 = Reg.decode(reg3),
                },
            };
        },
        .jalcc => blk: {
            const reg1 = @truncate(u5, e >> 20);
            const reg2 = @truncate(u5, e >> 15);
            const reg3 = @truncate(u5, e >> 10);
            const reg4 = @truncate(u5, e >> 5);
            const comp = @truncate(u5, e);
            break :blk .{
                .jalcc = .{
                    .r1 = Reg.decode(reg1),
                    .r2 = Reg.decode(reg2),
                    .r3 = Reg.decode(reg3),
                    .r4 = Reg.decode(reg4),
                    .cmp = Data.Comparison.decode(comp),
                },
            };
        },
    };
    return .{ .op = op, .data = data };
}

pub fn writeInto(self: Instruction, out: anytype) !void {
    const op = self.op;
    const data = self.data;

    if (op != .jalcc and op != .ldi) try out.print("{s: <6}", .{op.getName()});

    switch (data) {
        .reg_imm => |ri| {
            try out.print(" {s: <3} 0x{X:0>4}\n", .{
                ri.r.getName(),
                ri.imm,
            });
        },
        .reg_reg_imm => |rri| {
            try out.print(" {s: <3} {s: <3} 0x{X:0>4}\n", .{
                rri.r1.getName(),
                rri.r2.getName(),
                rri.imm,
            });
        },
        .reg_reg_n => |rrn| {
            try out.print(" {s: <3} {s: <3} 0x{X:0>4}\n", .{
                rrn.r1.getName(),
                rrn.r2.getName(),
                rrn.n,
            });
        },
        .reg_reg => |rr| {
            try out.print(" {s: <3} {s: <3}\n", .{
                rr.r1.getName(),
                rr.r2.getName(),
            });
        },
        .reg_reg_reg => |rrr| {
            try out.print(" {s: <3} {s: <3} {s: <3}\n", .{
                rrr.r1.getName(),
                rrr.r2.getName(),
                rrr.r3.getName(),
            });
        },
        .jalcc => |jc| {
            try out.print("{s: <6} {s: <3} {s: <3} {s: <3} {s: <3}\n", .{
                jc.cmp.getJmpName(),
                jc.r1.getName(),
                jc.r2.getName(),
                jc.r3.getName(),
                jc.r4.getName(),
            });
        },
        .load => |ld| {
            switch (ld.mcd) {
                .ldli,
                .ldui,
                .ldlz,
                .lduz,
                .ldls,
                .ldus,
                => try out.print("{s: <6} {s: <3} 0x{X:0>4}\n", .{
                    ld.mcd.getLoadName(),
                    ld.r.getName(),
                    ld.imm,
                }),
                ._UNUSED1, ._UNUSED2 => @panic("Unused MCD in LOAD instruction"),
                else => {
                    const x = @as(u4, 0b0111) & ld.mcd.encode();
                    const addr = @as(u20, ld.imm) | (@as(u20, x) << 16);
                    try out.print("{s: <6} {s: <3} [0x{X:0>4}]", .{ "LOAD", ld.r.getName(), addr });
                },
            }
        },
    }
}

pub const Opcode = enum(u7) {
    ldi,
    ldr,
    sta,
    str,
    add,
    sub,
    @"or",
    @"and",
    xor,
    not,
    lsl,
    lsr,
    jalcc,

    pub fn encode(self: Opcode) u7 {
        return @enumToInt(self);
    }

    pub fn decode(e: u7) Opcode {
        return @intToEnum(Opcode, e);
    }

    pub fn getName(self: Opcode) [:0]const u8 {
        return switch (self) {
            .ldi => "LDI",
            .ldr => "LDR",
            .sta => "STA",
            .str => "STR",
            .add => "ADD",
            .sub => "SUB",
            .@"or" => "OR",
            .@"and" => "AND",
            .xor => "XOR",
            .not => "NOT",
            .lsl => "LSL",
            .lsr => "LSR",
            .jalcc => "JALCC",
        };
    }
};

pub const Data = union(enum) {
    reg_imm: struct { r: Reg, imm: u16 },
    reg_reg_imm: struct { r1: Reg, r2: Reg, imm: u15 },
    reg_reg_n: struct { r1: Reg, r2: Reg, n: u5 },
    reg_reg: struct { r1: Reg, r2: Reg },
    reg_reg_reg: struct { r1: Reg, r2: Reg, r3: Reg },
    jalcc: struct { r1: Reg, r2: Reg, r3: Reg, r4: Reg, cmp: Comparison },
    load: struct { r: Reg, mcd: Load, imm: u16 },

    pub const Comparison = enum(u5) {
        eq = 0b00000,
        gt, // = 0b10001,
        lt, // = 0b10010,
        gts, // = 0b10011,
        lts, // = 0b10100,
        neq = 0b10000,
        leq, // = 0b00001,
        geq, // = 0b00010,
        leqs, // = 0b00011,
        geqs, // = 0b00100,

        pub fn encode(self: Comparison) u5 {
            return @enumToInt(self);
        }

        pub fn decode(e: u5) Comparison {
            return @intToEnum(Comparison, e);
        }

        pub fn getJmpName(self: Comparison) [:0]const u8 {
            return switch (self) {
                .eq => "JALEQ",
                .gt => "JALG",
                .lt => "JALL",
                .gts => "JALGS",
                .lts => "JALLS",
                .neq => "JALNEQ",
                .leq => "JALLEQ",
                .geq => "JALGEQ",
                .leqs => "JALLEQS",
                .geqs => "JALGEQS",
            };
        }
    };

    pub const Load = enum(u4) {
        ldli,
        ldui,
        ldlz,
        lduz,
        ldls,
        ldus,
        _UNUSED1,
        _UNUSED2,
        _,

        pub fn encode(self: Load) u4 {
            return @enumToInt(self);
        }

        pub fn decode(e: u4) Load {
            return @intToEnum(Load, e);
        }

        pub fn getLoadName(self: Load) [:0]const u8 {
            return switch (self) {
                .ldli => "LDLI",
                .ldui => "LDUI",
                .ldlz => "LDLZ",
                .lduz => "LDUZ",
                .ldls => "LDLS",
                .ldus => "LDUS",
                ._UNUSED1, ._UNUSED2 => "XXXX",
                else => "LOAD",
            };
        }
    };
};
