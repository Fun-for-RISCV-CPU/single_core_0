module ID_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   if_id_stage_reg_t if_id_stage_reg,
    output  id_ex_stage_reg_t id_ex_stage_reg,

    // Control signals, comes from the wb stage
    input   logic [4:0]     wb_rd_s,
    input   logic [31:0]    wb_rd_v,
    input   logic           wb_regf_we
);  

    logic               valid;
    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [63:0]      order;
    // control signal
    ex_signal_t     ex_signal;
    mem_signal_t    mem_signal;
    wb_signal_t     wb_signal;
    // value
    logic   [31:0]      i_imm;
    logic   [31:0]      s_imm;
    logic   [31:0]      b_imm;
    logic   [31:0]      u_imm;
    logic   [31:0]      j_imm;
    logic   [31:0]      rs1_v;
    logic   [31:0]      rs2_v;
    logic   [4:0]       rs1_s;
    logic   [4:0]       rs2_s;
    logic   [4:0]       rd_s;
    logic   [2:0]       funct3;
    logic   [6:0]       funct7;
    logic   [6:0]       opcode;

    always_comb begin
        valid = if_id_stage_reg.valid;
        inst = if_id_stage_reg.inst;
        pc = if_id_stage_reg.pc;
        order = if_id_stage_reg.order;
        funct3 = if_id_stage_reg.funct3;
        funct7 = if_id_stage_reg.funct7;
        opcode = if_id_stage_reg.opcode;
        i_imm = if_id_stage_reg.i_imm;
        s_imm = if_id_stage_reg.s_imm;
        b_imm = if_id_stage_reg.b_imm;
        u_imm = if_id_stage_reg.u_imm;
        j_imm = if_id_stage_reg.j_imm;
        rs1_s = if_id_stage_reg.rs1_s;
        rs2_s = if_id_stage_reg.rs2_s;
        rd_s = if_id_stage_reg.rd_s;
    end

    regfile regfile(
        .clk(clk),
        .rst(rst),
        .regf_we(wb_regf_we),
        .rd_s(wb_rd_s),
        .rd_v(wb_rd_v),
        .rs1_s(rs1_s),
        .rs2_s(rs2_s),
        .rs1_v(rs1_v),
        .rs2_v(rs2_v)
    );

    always_comb begin 
        ex_signal.alu_m1_sel = 'x;
        ex_signal.alu_m2_sel = 'x;
        ex_signal.alu_ops = 'x;
        ex_signal.cmp_m_sel = 'x;
        ex_signal.cmp_ops = 'x;

        mem_signal.MemRead = '0;
        mem_signal.MemWrite = '0;
        mem_signal.load_ops = 'x;
        mem_signal.store_ops = 'x;

        wb_signal.regf_m_sel = 'x;
        wb_signal.regf_we = '0;

        case (opcode) 
            lui_opcode: begin
                wb_signal.regf_m_sel = u_imm_wb;
                wb_signal.regf_we = '1;
            end
            auipc_opcode: begin
                ex_signal.alu_m1_sel = pc_out_alu_ex;
                ex_signal.alu_m2_sel = u_imm_alu_ex;
                ex_signal.alu_ops = add_alu_op;
                wb_signal.regf_m_sel = alu_out_wb;
                wb_signal.regf_we = '1;
            end
            imm_opcode: begin 
                wb_signal.regf_we = '1;
                case (funct3)
                    slt_funct3: begin 
                        ex_signal.cmp_m_sel = i_imm_cmp_ex;
                        ex_signal.cmp_ops = blt_cmp_op;
                        wb_signal.regf_m_sel = br_en_wb;
                    end
                    sltu_funct3: begin 
                        ex_signal.cmp_m_sel = i_imm_cmp_ex;
                        ex_signal.cmp_ops = bltu_cmp_op;
                        wb_signal.regf_m_sel = br_en_wb;
                    end 
                    sr_funct3: begin 
                        ex_signal.alu_m1_sel = rs1_v_alu_ex;
                        ex_signal.alu_m2_sel = i_imm_alu_ex;
                        if (funct7[5]) begin 
                            ex_signal.alu_ops = sra_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end else begin 
                            ex_signal.alu_ops = srl_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end 
                    end 
                    default: begin 
                        ex_signal.alu_m1_sel = rs1_v_alu_ex;
                        ex_signal.alu_m2_sel = i_imm_alu_ex;
                        ex_signal.alu_ops = funct3;
                        wb_signal.regf_m_sel = alu_out_wb;
                    end 
                endcase
            end
            reg_opcode: begin 
                wb_signal.regf_we = '1;
                case (funct3)  
                    slt_funct3: begin 
                        ex_signal.cmp_m_sel = rs2_v_cmp_ex;
                        ex_signal.cmp_ops = blt_cmp_op;
                        wb_signal.regf_m_sel = br_en_wb;
                    end 
                    sltu_funct3: begin 
                        ex_signal.cmp_m_sel = rs2_v_cmp_ex;
                        ex_signal.cmp_ops = bltu_cmp_op;
                        wb_signal.regf_m_sel = br_en_wb;
                    end
                    sr_funct3: begin 
                        ex_signal.alu_m1_sel = rs1_v_alu_ex;
                        ex_signal.alu_m2_sel = rs2_v_alu_ex;
                        if (funct7[5]) begin 
                            ex_signal.alu_ops = sra_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end else begin 
                            ex_signal.alu_ops = srl_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end 
                    end
                    add_funct3: begin 
                        ex_signal.alu_m1_sel = rs1_v_alu_ex;
                        ex_signal.alu_m2_sel = rs2_v_alu_ex;
                        if (funct7[5]) begin 
                            ex_signal.alu_ops = sub_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end else begin 
                            ex_signal.alu_ops = add_alu_op;
                            wb_signal.regf_m_sel = alu_out_wb;
                        end 
                    end 
                    default: begin 
                        ex_signal.alu_m1_sel = rs1_v_alu_ex;
                        ex_signal.alu_m2_sel = rs2_v_alu_ex;
                        ex_signal.alu_ops = funct3;
                        wb_signal.regf_m_sel = alu_out_wb;
                    end 

                endcase 

            end

        endcase

    end 

    always_comb begin 
        id_ex_stage_reg.valid = valid;
        id_ex_stage_reg.inst = inst;
        id_ex_stage_reg.pc = pc;
        id_ex_stage_reg.order = order;
        id_ex_stage_reg.is_stall = 1'b0; // default is not stall
        id_ex_stage_reg.ex_signal = ex_signal;
        id_ex_stage_reg.mem_signal = mem_signal;
        id_ex_stage_reg.wb_signal = wb_signal;
        id_ex_stage_reg.i_imm = i_imm;
        id_ex_stage_reg.s_imm = s_imm;
        id_ex_stage_reg.b_imm = b_imm;
        id_ex_stage_reg.u_imm = u_imm;
        id_ex_stage_reg.j_imm = j_imm;
        id_ex_stage_reg.rs1_v = rs1_v;
        id_ex_stage_reg.rs2_v = rs2_v;
        id_ex_stage_reg.rs1_s = rs1_s;
        id_ex_stage_reg.rs2_s = rs2_s;
        id_ex_stage_reg.rd_s = rd_s;
    end

endmodule