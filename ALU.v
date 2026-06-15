`timescale 1ns / 1ps

module ALU(
    input [31:0] X, input [31:0] Y, input [3:0] AluOP, output reg [31:0] Result, output reg [31:0] Result2, output reg OF, output reg CF, output Equal
    );
    assign Equal = (X==Y);
    
    reg signed [63:0] mult_res; // 64ºñÆ® °ö¼À °á°ú º¸È£

    always @(*) begin
        Result = 32'd0; Result2 = 32'd0; OF = 1'b0; CF = 1'b0; mult_res = 64'd0;
        
        case(AluOP)
            4'd0: Result = Y << X[4:0];
            4'd1: Result = $signed(Y) >>> X[4:0];
            4'd2: Result = Y >> X[4:0];
            4'd3: begin 
                mult_res = $signed(X) * $signed(Y);
                Result2 = mult_res[63:32]; Result = mult_res[31:0];
            end
            4'd14: begin 
                mult_res = X * Y;
                Result2 = mult_res[63:32]; Result = mult_res[31:0];
            end
            4'd4: begin 
                Result = $signed(X) / $signed(Y);
                Result2 = $signed(X) % $signed(Y);
            end
            4'd15: begin 
                Result = X / Y;
                Result2 = X % Y;
            end
            
            4'd5: begin
                {CF, Result} = {1'b0, X} + {1'b0, Y};
                OF = (X[31] == Y[31]) && (Result[31] != X[31]);
            end
            4'd6: begin
                {CF, Result} = {1'b0, X} - {1'b0, Y};
                OF = (X[31] != Y[31]) && (Result[31] != X[31]); 
            end
            4'd7: Result = X & Y;
            4'd8: Result = X | Y;
            4'd9: Result = X ^ Y;
            4'd10: Result = ~(X | Y);
            4'd11: begin
                if ($signed(X) < $signed(Y)) Result = 32'd1;
                else                         Result = 32'd0;
            end 
            4'd12: begin
                if (X < Y) Result = 32'd1;
                else       Result = 32'd0;
            end
            4'd13: Result = Y << 16; 
            default : begin
                 Result = 32'd0; Result2 = 32'd0; OF = 1'b0; CF = 1'b0;
            end
        endcase
    end
endmodule