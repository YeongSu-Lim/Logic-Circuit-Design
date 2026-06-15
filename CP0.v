`timescale 1ns / 1ps

module CP0(
    input         clk,
    input         enable,     // IsCOP0 신호
    input  [31:0] Inst,       
    input  [31:0] PCin,       
    input  [31:0] Din,        
    input         ExpSrc0,    
    input         ExpSrc1,    
    input         ExpSrc2,    

    output        HasExp,     
    output        IsEret,     
    output        ExRegWrite, 
    output        ExpBlock,   
    output [31:0] Dout,       
    output [31:0] PCout       
    );
    
    // 명령어 해독
    wire [4:0] Sel = Inst[15:11];                                  
    assign ExRegWrite = enable & ~Inst[23];
    assign IsEret = (Inst[31:26] == 6'b010000) && (Inst[5:0] == 6'b011000);      

    // 예외 감지 로직
    wire BlockSrc0, BlockSrc1, BlockSrc2;
    wire mask0 = BlockSrc0 ? 1'b0 : ExpSrc0;
    wire mask1 = BlockSrc1 ? 1'b0 : ExpSrc1;
    wire mask2 = BlockSrc2 ? 1'b0 : ExpSrc2;
    wire ExpClick = (mask0 | mask1 | mask2) & ~ExpBlock;

    reg FF1_Q = 0;
    reg FF2_Q = 0;
    
    always @(posedge clk) begin
        if (FF2_Q) FF1_Q <= 1'b0;      
        else       FF1_Q <= ExpClick;  
        
        FF2_Q <= FF1_Q;
    end
    
    assign HasExp = FF1_Q;

    // Registers
    reg [31:0] Status = 0; 
    reg [31:0] Cause  = 0; 
    reg [31:0] EPC    = 0; 
    reg [31:0] Block  = 0; 

    assign PCout = EPC;
    assign ExpBlock = Status[0];
    assign {BlockSrc2, BlockSrc1, BlockSrc0} = Block[2:0];

    wire CP0Write = enable & ~ExRegWrite;

    always @(posedge clk) begin
        if (HasExp) begin
            EPC <= PCin; 
        end else if (CP0Write && (Sel == 5'd14)) begin
            EPC <= Din;  
        end

        if (CP0Write && (Sel == 5'd12)) begin
            Status <= Din;
        end

        if (CP0Write && (Sel == 5'd15)) begin
            Block <= Din;
        end

        if (ExpClick) begin
            if (ExpSrc0)      Cause <= 32'd1;
            else if (ExpSrc1) Cause <= 32'd3;
            else if (ExpSrc2) Cause <= 32'd7;
        end
    end

    //Data Out MUX
    reg [31:0] Dout_reg;
    always @(*) begin
        case (Sel)
            5'd12: Dout_reg = Status;
            5'd13: Dout_reg = Cause;
            5'd14: Dout_reg = EPC;
            5'd15: Dout_reg = Block;
            default: Dout_reg = 32'd0;
        endcase
    end
    assign Dout = Dout_reg;
    
endmodule