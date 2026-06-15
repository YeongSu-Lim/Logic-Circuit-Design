`timescale 1ns / 1ps

module Register_File(
input         clk,
    input         WE,       
    input  [4:0]  R1_num,   
    input  [4:0]  R2_num,   
    input  [4:0]  RW_num,   
    input  [31:0] Din,      
    output [31:0] R1,       
    output [31:0] R2,       
    output [31:0] a0,
    output [31:0] v0 
    );
    
    reg [31:0] registers [0:31];
    
    // 초기화 블록
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    //비동기식 읽기 (총 4개의 출력 할당)
    assign R1 = registers[R1_num];
    assign R2 = registers[R2_num];
    
    assign v0 = registers[5'd2];
    assign a0 = registers[5'd4];

    //동기식 쓰기 (0번 레지스터 보호)
    always @(posedge clk) begin
        if (WE == 1'b1 && RW_num != 5'd0) begin
            registers[RW_num] <= Din;
        end
    end   
endmodule
