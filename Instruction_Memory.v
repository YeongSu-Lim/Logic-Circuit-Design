`timescale 1ns / 1ps

module Instruction_Memory(
    input  [31:0] Address,      
    output [31:0] Instruction   
    );

    reg [31:0] rom_main [0:1023]; 
    reg [31:0] rom_exc  [0:1023]; 
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            rom_main[i] = 32'd0;
            rom_exc[i]  = 32'd0;
        end
        $readmemh("inst_main.mem", rom_main);
        $readmemh("inst_exc.mem", rom_exc);
    end

    // 0x0800 구간 예외 처리
    wire is_exc = (Address >= 32'h00000800 && Address < 32'h00001000);
    wire [31:0] exc_addr = Address - 32'h00000800;
    
    assign Instruction = is_exc ? rom_exc[exc_addr[11:2]] : rom_main[Address[11:2]];
    
endmodule