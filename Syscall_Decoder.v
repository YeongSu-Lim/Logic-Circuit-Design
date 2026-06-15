`timescale 1ns / 1ps

module Syscall_Decoder(
    input         clk,
    input         Enable,
    input  [31:0] v0,
    input  [31:0] a0,
    output        Halt,
    output reg [31:0] Hex
    );
    
    // Halt 출력 (조합 논리)
    // Enable이 1일 때만 v0가 10(0x0a)인지 확인하여 Halt 신호 발생
    assign Halt = Enable ? (v0 == 32'h0000000A) : 1'b0;

    // 초기화 블록
    initial begin
        Hex = 32'd0;
    end

    // 2. Hex 출력 (순차 논리)
    // 클럭이 뛸 때마다 Enable이 1이면 a0의 값을 Hex에 저장
    always @(posedge clk) begin
        if (Enable == 1'b1) begin
            Hex <= a0;
        end
    end
    
endmodule
