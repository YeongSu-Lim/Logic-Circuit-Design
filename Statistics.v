`timescale 1ns / 1ps

module Statistics(
input [5:0] op, output i, output r, output j
    );

    // R-type: 000000 (0)
    assign r = (op == 6'd0);

    // J-type: 000010 (2), 000011 (3)
    assign j = (op == 6'd2) || (op == 6'd3);

    // I-type: 진리표에서 추출한 9개
    assign i = (op == 6'd4)  ||  // 000100
               (op == 6'd5)  ||  // 000101
               (op == 6'd8)  ||  // 001000
               (op == 6'd9)  ||  // 001001
               (op == 6'd10) ||  // 001010
               (op == 6'd12) ||  // 001100
               (op == 6'd13) ||  // 001101
               (op == 6'd35) ||  // 100011
               (op == 6'd43);    // 101011
endmodule
