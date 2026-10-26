`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Combinational control decode for the 37-instruction subset in docs/cpu_isa.md.
// Illegal encodings retain their raw register fields but cannot request effects.
module decode (
    input  wire [31:0] instr,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output reg         rs1_used,
    output reg         rs2_used,
    output reg  [3:0]  alu_op,
    output reg  [1:0]  alu_a_sel,
    output reg         alu_b_imm,
    output reg  [2:0]  imm_sel,
    output reg         reg_write,
    output reg  [1:0]  wb_sel,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  mem_size,
    output reg         mem_unsigned,
    output reg  [2:0]  branch_op,
    output reg         jump,
    output reg         jalr,
    output reg         illegal
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    always @* begin
        rs1_used     = 1'b0;
        rs2_used     = 1'b0;
        alu_op       = `CPU_ALU_ADD;
        alu_a_sel    = `CPU_A_RS1;
        alu_b_imm    = 1'b0;
        imm_sel      = `CPU_IMM_NONE;
        reg_write    = 1'b0;
        wb_sel       = `CPU_WB_ALU;
        mem_read     = 1'b0;
        mem_write    = 1'b0;
        mem_size     = `CPU_MEM_WORD;
        mem_unsigned = 1'b0;
        branch_op    = `CPU_BR_NONE;
        jump         = 1'b0;
        jalr         = 1'b0;
        illegal      = 1'b1;

        case (opcode)
            7'b0110011: begin // Register-register arithmetic.
                rs1_used  = 1'b1;
                rs2_used  = 1'b1;
                reg_write = 1'b1;
                // Match every funct7 bit: M-extension/reserved forms are illegal.
                case ({funct7, funct3})
                    10'b0000000_000: begin alu_op = `CPU_ALU_ADD;  illegal = 1'b0; end
                    10'b0100000_000: begin alu_op = `CPU_ALU_SUB;  illegal = 1'b0; end
                    10'b0000000_001: begin alu_op = `CPU_ALU_SLL;  illegal = 1'b0; end
                    10'b0000000_010: begin alu_op = `CPU_ALU_SLT;  illegal = 1'b0; end
                    10'b0000000_011: begin alu_op = `CPU_ALU_SLTU; illegal = 1'b0; end
                    10'b0000000_100: begin alu_op = `CPU_ALU_XOR;  illegal = 1'b0; end
                    10'b0000000_101: begin alu_op = `CPU_ALU_SRL;  illegal = 1'b0; end
                    10'b0100000_101: begin alu_op = `CPU_ALU_SRA;  illegal = 1'b0; end
                    10'b0000000_110: begin alu_op = `CPU_ALU_OR;   illegal = 1'b0; end
                    10'b0000000_111: begin alu_op = `CPU_ALU_AND;  illegal = 1'b0; end
                    default: illegal = 1'b1;
                endcase
            end

            7'b0010011: begin // Register-immediate arithmetic.
                rs1_used  = 1'b1;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_I;
                reg_write = 1'b1;
                case (funct3)
                    3'b000: begin alu_op = `CPU_ALU_ADD;  illegal = 1'b0; end // ADDI
                    3'b010: begin alu_op = `CPU_ALU_SLT;  illegal = 1'b0; end // SLTI
                    3'b011: begin alu_op = `CPU_ALU_SLTU; illegal = 1'b0; end // SLTIU
                    3'b100: begin alu_op = `CPU_ALU_XOR;  illegal = 1'b0; end // XORI
                    3'b110: begin alu_op = `CPU_ALU_OR;   illegal = 1'b0; end // ORI
                    3'b111: begin alu_op = `CPU_ALU_AND;  illegal = 1'b0; end // ANDI
                    3'b001: begin
                        case (funct7)
                            7'b0000000: begin alu_op = `CPU_ALU_SLL; illegal = 1'b0; end
                            default: illegal = 1'b1;
                        endcase
                    end
                    3'b101: begin
                        case (funct7)
                            7'b0000000: begin alu_op = `CPU_ALU_SRL; illegal = 1'b0; end
                            7'b0100000: begin alu_op = `CPU_ALU_SRA; illegal = 1'b0; end
                            default: illegal = 1'b1;
                        endcase
                    end
                    default: illegal = 1'b1;
                endcase
            end

            7'b0110111: begin // LUI: zero + U immediate.
                alu_a_sel = `CPU_A_ZERO;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_U;
                reg_write = 1'b1;
                illegal   = 1'b0;
            end

            7'b0010111: begin // AUIPC: instruction PC + U immediate.
                alu_a_sel = `CPU_A_PC;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_U;
                reg_write = 1'b1;
                illegal   = 1'b0;
            end

            7'b1101111: begin // JAL: PC-relative target, PC+4 writeback.
                alu_a_sel = `CPU_A_PC;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_J;
                reg_write = 1'b1;
                wb_sel    = `CPU_WB_PC4;
                jump      = 1'b1;
                illegal   = 1'b0;
            end

            7'b1100111: begin // JALR: execution must clear target bit zero.
                case (funct3)
                    3'b000: begin
                        rs1_used  = 1'b1;
                        alu_b_imm = 1'b1;
                        imm_sel   = `CPU_IMM_I;
                        reg_write = 1'b1;
                        wb_sel    = `CPU_WB_PC4;
                        jump      = 1'b1;
                        jalr      = 1'b1;
                        illegal   = 1'b0;
                    end
                    default: illegal = 1'b1;
                endcase
            end

            7'b1100011: begin // Branch comparison; target uses separate PC+imm.
                rs1_used = 1'b1;
                rs2_used = 1'b1;
                imm_sel  = `CPU_IMM_B;
                case (funct3)
                    3'b000: begin
                        alu_op = `CPU_ALU_SUB; branch_op = `CPU_BR_EQ;  illegal = 1'b0;
                    end
                    3'b001: begin
                        alu_op = `CPU_ALU_SUB; branch_op = `CPU_BR_NE;  illegal = 1'b0;
                    end
                    3'b100: begin
                        alu_op = `CPU_ALU_SLT; branch_op = `CPU_BR_LT;  illegal = 1'b0;
                    end
                    3'b101: begin
                        alu_op = `CPU_ALU_SLT; branch_op = `CPU_BR_GE;  illegal = 1'b0;
                    end
                    3'b110: begin
                        alu_op = `CPU_ALU_SLTU; branch_op = `CPU_BR_LTU; illegal = 1'b0;
                    end
                    3'b111: begin
                        alu_op = `CPU_ALU_SLTU; branch_op = `CPU_BR_GEU; illegal = 1'b0;
                    end
                    default: illegal = 1'b1;
                endcase
            end

            7'b0000011: begin // Loads: rs1 + I immediate.
                rs1_used  = 1'b1;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_I;
                reg_write = 1'b1;
                wb_sel    = `CPU_WB_MEM;
                mem_read  = 1'b1;
                case (funct3)
                    3'b000: begin mem_size = `CPU_MEM_BYTE; illegal = 1'b0; end // LB
                    3'b001: begin mem_size = `CPU_MEM_HALF; illegal = 1'b0; end // LH
                    3'b010: begin mem_size = `CPU_MEM_WORD; illegal = 1'b0; end // LW
                    3'b100: begin // LBU
                        mem_size = `CPU_MEM_BYTE; mem_unsigned = 1'b1; illegal = 1'b0;
                    end
                    3'b101: begin // LHU
                        mem_size = `CPU_MEM_HALF; mem_unsigned = 1'b1; illegal = 1'b0;
                    end
                    default: illegal = 1'b1;
                endcase
            end

            7'b0100011: begin // Stores: rs1 + S immediate; rs2 supplies store data.
                rs1_used  = 1'b1;
                rs2_used  = 1'b1;
                alu_b_imm = 1'b1;
                imm_sel   = `CPU_IMM_S;
                mem_write = 1'b1;
                case (funct3)
                    3'b000: begin mem_size = `CPU_MEM_BYTE; illegal = 1'b0; end // SB
                    3'b001: begin mem_size = `CPU_MEM_HALF; illegal = 1'b0; end // SH
                    3'b010: begin mem_size = `CPU_MEM_WORD; illegal = 1'b0; end // SW
                    default: illegal = 1'b1;
                endcase
            end

            default: illegal = 1'b1;
        endcase

        // A recognized major opcode may still contain an illegal subencoding.
        // Scrub all controls, including defaults that do not directly commit state.
        if (illegal) begin
            rs1_used     = 1'b0;
            rs2_used     = 1'b0;
            alu_op       = `CPU_ALU_ADD;
            alu_a_sel    = `CPU_A_RS1;
            alu_b_imm    = 1'b0;
            imm_sel      = `CPU_IMM_NONE;
            reg_write    = 1'b0;
            wb_sel       = `CPU_WB_ALU;
            mem_read     = 1'b0;
            mem_write    = 1'b0;
            mem_size     = `CPU_MEM_WORD;
            mem_unsigned = 1'b0;
            branch_op    = `CPU_BR_NONE;
            jump         = 1'b0;
            jalr         = 1'b0;
        end
    end

endmodule
