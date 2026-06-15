`timescale 1ns / 1ps

module Program_Counter(
    input         clk,
    input         reset,
    input  [31:0] mux_pc_din_in1,
    input         HasExp,
    output reg [31:0] reg_PC
    );

    wire [31:0] next_pc = HasExp ? 32'h00000800 : mux_pc_din_in1;

    always @(posedge clk or posedge reset) begin
        if (reset) 
        begin
            reg_PC <= 32'h00000000; 
        end 
        else 
        begin
            reg_PC <= next_pc;
        end
    end
endmodule