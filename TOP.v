`timescale 1ns / 1ps

module TOP(
    input         clk,
    input         reset,
    input         ExpSrc0, 
    input         ExpSrc1, 
    input         ExpSrc2, 
    output        Halt,
    output [31:0] Hex_Out,
    output reg [31:0] Total_Cycles,
    output reg [31:0] J,
    output reg [31:0] R,
    output reg [31:0] I
    );

    wire [31:0] pc_out, pc_plus_4, next_pc_normal, inst;
    wire [5:0]  op = inst[31:26];
    wire [5:0]  funct = inst[5:0];
    wire        is_r, is_i, is_j;
    wire        is_jal, is_shamt, mem_to_reg, reg_write, bne_or_beq;
    wire        alu_src, is_syscall, zero_extend, mem_read, mem_write;
    wire        jump, branch, reg_dst, is_jr, is_cop0, read_rs, read_rt;
    wire [3:0]  alu_op;
    wire [4:0]  rs = inst[25:21], rt = inst[20:16], rd = inst[15:11];
    wire [31:0] read_data_1, read_data_2, a0_wire, v0_wire;
    wire [4:0]  write_reg_num;
    wire [31:0] write_reg_data;
    wire        actual_reg_write;
    wire [31:0] imm_ext, alu_in_x, alu_in_y, alu_result, alu_result2;
    wire        alu_of, alu_cf, alu_equal;
    wire [31:0] mem_read_data;
    wire        has_exp, is_eret, ex_reg_write, exp_block;
    wire [31:0] cp0_dout, cp0_pcout;
    wire [31:0] branch_target, jump_target;
    wire        do_branch;

    assign pc_plus_4 = pc_out + 32'd4;
    assign branch_target = pc_plus_4 + (imm_ext << 2);
    assign jump_target = {pc_plus_4[31:28], inst[25:0], 2'b00};
    
    assign do_branch = branch & (bne_or_beq ? ~alu_equal : alu_equal);
    
    assign next_pc_normal = is_eret ? cp0_pcout : 
                            (is_jr ? read_data_1 : 
                            (jump ? jump_target : 
                            (do_branch ? branch_target : pc_plus_4)));

    assign alu_in_x = is_shamt ? {27'd0, inst[10:6]} : read_data_1;
    assign alu_in_y = alu_src ? imm_ext : read_data_2;
    
    reg [31:0] reg_hi, reg_lo;
    wire is_mult = (op == 6'd0) && (funct == 6'd24 || funct == 6'd25);
    wire is_div  = (op == 6'd0) && (funct == 6'd26 || funct == 6'd27);
    wire is_mflo = (op == 6'd0) && (funct == 6'd18);
    wire is_mfhi = (op == 6'd0) && (funct == 6'd16);
    wire is_mthi = (op == 6'd0) && (funct == 6'd17);
    wire is_mtlo = (op == 6'd0) && (funct == 6'd19);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_hi <= 0;
            reg_lo <= 0;
        end else begin
            if (is_mult || is_div) begin
                reg_hi <= alu_result2;
                reg_lo <= alu_result;
            end else if (is_mthi) begin
                reg_hi <= read_data_1;
            end else if (is_mtlo) begin
                reg_lo <= read_data_1;
            end
        end
    end

    assign write_reg_num = is_jal ? 5'd31 : (reg_dst ? rd : rt);
    
    assign write_reg_data = is_jal ? pc_plus_4 :
                            (ex_reg_write ? cp0_dout :
                            (mem_to_reg ? mem_read_data : 
                            (is_mflo ? reg_lo :
                            (is_mfhi ? reg_hi : alu_result))));
                            
    assign actual_reg_write = reg_write | ex_reg_write;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Total_Cycles <= 0; J <= 0; R <= 0; I <= 0;
        end else begin
            Total_Cycles <= Total_Cycles + 1;
            if (is_j) J <= J + 1;
            if (is_r) R <= R + 1;
            if (is_i) I <= I + 1;
        end
    end

    Program_Counter u_PC (.clk(clk), .reset(reset), .mux_pc_din_in1(next_pc_normal), .HasExp(has_exp), .reg_PC(pc_out));
    Instruction_Memory u_IMEM (.Address(pc_out), .Instruction(inst));
    Control_Unit u_Control (.op(op), .Funct(funct), .IsJAL(is_jal), .IsShamt(is_shamt), .MemtoReg(mem_to_reg), .RegWrite(reg_write), .BneOrBeq(bne_or_beq), .ALUSrc(alu_src), .IsSyscall(is_syscall), .ZeroExtend(zero_extend), .MemRead(mem_read), .MemWrite(mem_write), .Jump(jump), .Branch(branch), .RegDst(reg_dst), .IsJR(is_jr), .IsCOP0(is_cop0), .ReadRs(read_rs), .ReadRt(read_rt), .ALUop(alu_op));
    Statistics u_Stat (.op(op), .i(is_i), .r(is_r), .j(is_j));
    Register_File u_RegFile (.clk(clk), .WE(actual_reg_write), .R1_num(rs), .R2_num(rt), .RW_num(write_reg_num), .Din(write_reg_data), .R1(read_data_1), .R2(read_data_2), .a0(a0_wire), .v0(v0_wire));
    Imme_Extend u_ImmExt (.imm16(inst[15:0]), .ZeroExtend(zero_extend), .ext32(imm_ext));
    ALU u_ALU (.X(alu_in_x), .Y(alu_in_y), .AluOP(alu_op), .Result(alu_result), .Result2(alu_result2), .OF(alu_of), .CF(alu_cf), .Equal(alu_equal));
    Data_Memory u_DMEM (.clk(clk), .MemRead(mem_read), .MemWrite(mem_write), .Address(alu_result), .WriteData(read_data_2), .ReadData(mem_read_data));
    Syscall_Decoder u_Syscall (.clk(clk), .Enable(is_syscall), .v0(v0_wire), .a0(a0_wire), .Halt(Halt), .Hex(Hex_Out));
    
    CP0 u_CP0 (.clk(clk), .enable(is_cop0), .Inst(inst), .PCin(pc_out), .Din(read_data_2), 
               .ExpSrc0(ExpSrc0), .ExpSrc1(ExpSrc1), .ExpSrc2(ExpSrc2), 
               .HasExp(has_exp), .IsEret(is_eret), .ExRegWrite(ex_reg_write), .ExpBlock(exp_block), .Dout(cp0_dout), .PCout(cp0_pcout));
endmodule