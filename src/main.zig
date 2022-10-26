const std = @import("std");
const Instruction = @import("instruction.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.skip();
    var out_buf = std.io.bufferedWriter(std.io.getStdOut().writer());

    var out = out_buf.writer();
    while (args.next()) |fname| {
        var file = try std.fs.cwd().openFile(fname, .{});
        var file_r = file.reader();
        var input_buf = std.io.bufferedReader(file_r);
        var input = input_buf.reader();
        defer file.close();
        var idx: usize = 0;
        while (true) {
            const instr = input.readIntBig(u32) catch break;
            const ins = Instruction.decode(instr);
            try out.print("{x:0>4} (0x{x:0>8}) ", .{ idx, instr });
            try ins.writeInto(out);
            idx += 4;
        }
    }
    try out_buf.flush();
}

test {
    const instrs = [_]u8{ 0x00, 0x10, 0x51, 0x00, 0x00, 0x30, 0x00, 0x03, 0x00, 0x40, 0x00, 0x18, 0x00, 0x60, 0x00, 0x01, 0x02, 0x20, 0xFF, 0xBC, 0x00, 0x20, 0xF8, 0x00, 0x08, 0x20, 0x80, 0x00, 0x0A, 0x11, 0x84, 0x00, 0x0C, 0x23, 0x08, 0x00, 0x1A, 0x02, 0x00, 0x00 };
    var out = std.io.getStdOut().writer();

    var idx: usize = 0;
    while (idx < instrs.len) : (idx += 4) {
        const ins = std.mem.readIntSliceBig(u32, instrs[idx .. idx + 4]);
        const i = Instruction.decode(ins);
        try out.print("{x:0>4} ", .{idx});
        try i.writeInto(out);
    }
}
