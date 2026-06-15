`timescale 1ns / 1ps

module Imme_Extend(
input [15:0] imm16, input ZeroExtend, output [31:0] ext32
    );
    assign ext32 = ZeroExtend ? {16'b0, imm16} : {{16{imm16[15]}}, imm16};
endmodule
