`timescale 1ns / 1ps

module Data_Memory(
    input         clk,
    input         MemRead,
    input         MemWrite,
    input  [31:0] Address,      
    input  [31:0] WriteData,    
    output [31:0] ReadData      
    );
    
    reg [31:0] ram [0:4095];
    integer i;

    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            ram[i] = 32'd0;
        end
    end

    assign ReadData = (MemRead) ? ram[Address[13:2]] : 32'd0;

    always @(posedge clk) begin
        if (MemWrite) begin
            ram[Address[13:2]] <= WriteData;
        end
    end
        
endmodule