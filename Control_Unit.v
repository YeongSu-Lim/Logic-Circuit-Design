`timescale 1ns / 1ps

module Control_Unit(
    input  [5:0] op,
    input  [5:0] Funct,
    output reg       IsJAL, IsShamt, MemtoReg, RegWrite, BneOrBeq,
    output reg       ALUSrc, IsSyscall, ZeroExtend, MemRead, MemWrite,
    output reg       Jump, Branch, RegDst, IsJR, IsCOP0, ReadRs, ReadRt,
    output reg [3:0] ALUop
    );
    
always @(*) begin
        IsJAL = 0; IsShamt = 0; MemtoReg = 0; RegWrite = 0; BneOrBeq = 0;
        ALUSrc = 0; IsSyscall = 0; ZeroExtend = 0; MemRead = 0; MemWrite = 0;
        Jump = 0; Branch = 0; RegDst = 0; IsJR = 0; IsCOP0 = 0; 
        ReadRs = 1; ReadRt = 1;
        ALUop = 4'd0; 

        if (op == 6'd16) IsCOP0 = 1;

        case (op)
            // R-type
            6'd0: begin 
                RegDst = 1;   
                RegWrite = 1; 
                
                case (Funct)
                    6'd32, 6'd33: ALUop = 4'd5;  // add, addu
                    6'd34, 6'd35: ALUop = 4'd6;  // sub, subu
                    6'd36: ALUop = 4'd7;  // and
                    6'd37: ALUop = 4'd8;  // or
                    6'd38: ALUop = 4'd9;  // xor
                    6'd39: ALUop = 4'd10; // nor
                    6'd42: ALUop = 4'd11; // slt 
                    6'd43: ALUop = 4'd12; // sltu 
                    
                    6'd0:  begin IsShamt = 1; ALUop = 4'd0; end // sll
                    6'd2:  begin IsShamt = 1; ALUop = 4'd2; end // srl
                    6'd3:  begin IsShamt = 1; ALUop = 4'd1; end // sra

                    6'd4:  ALUop = 4'd0; // sllv
                    6'd6:  ALUop = 4'd2; // srlv
                    6'd7:  ALUop = 4'd1; // srav
                    
                    6'd8:  begin IsJR = 1; Jump = 1; RegWrite = 0; end // jr
                    6'd12: begin IsSyscall = 1; RegWrite = 0; end      // syscall
                    
                    6'd16, 6'd18: ; // mfhi, mflo 
                    6'd24: begin ALUop = 4'd3; RegWrite = 0; end  // mult (signed)
                    6'd25: begin ALUop = 4'd14; RegWrite = 0; end // multu (unsigned)
                    6'd26: begin ALUop = 4'd4; RegWrite = 0; end  // div (signed)
                    6'd27: begin ALUop = 4'd15; RegWrite = 0; end // divu (unsigned)
                endcase
            end

            // I-type
            6'd35: begin ALUSrc = 1; MemRead = 1; MemtoReg = 1; RegWrite = 1; ALUop = 4'd5; end // lw
            6'd43: begin ALUSrc = 1; MemWrite = 1; ALUop = 4'd5; end // sw
            6'd4:  begin Branch = 1; BneOrBeq = 0; ALUop = 4'd6; end // beq
            6'd5:  begin Branch = 1; BneOrBeq = 1; ALUop = 4'd6; end // bne
            6'd8, 6'd9: begin ALUSrc = 1; RegWrite = 1; ALUop = 4'd5; end // addi, addiu
            6'd10: begin ALUSrc = 1; RegWrite = 1; ALUop = 4'd11; end // slti
            6'd11: begin ALUSrc = 1; RegWrite = 1; ALUop = 4'd12; end // sltiu
            6'd12: begin ALUSrc = 1; RegWrite = 1; ZeroExtend = 1; ALUop = 4'd7; end // andi
            6'd13: begin ALUSrc = 1; RegWrite = 1; ZeroExtend = 1; ALUop = 4'd8; end // ori
            6'd14: begin ALUSrc = 1; RegWrite = 1; ZeroExtend = 1; ALUop = 4'd9; end // xori
            6'd15: begin ALUSrc = 1; RegWrite = 1; ALUop = 4'd13; end // lui
            
            // J-type
            6'd2:  begin Jump = 1; end // j
            6'd3:  begin Jump = 1; IsJAL = 1; RegWrite = 1; end // jal
        endcase
    end
endmodule