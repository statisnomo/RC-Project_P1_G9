`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Reconstruct byte-scale RV32I immediates. Shift operations use imm[4:0].
module imm_gen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] imm
);

    always @* begin
        case (imm_sel)
            `CPU_IMM_I: imm = {{20{instr[31]}}, instr[31:20]};
            `CPU_IMM_S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            `CPU_IMM_B: imm = {{19{instr[31]}}, instr[31], instr[7],
                              instr[30:25], instr[11:8], 1'b0};
            `CPU_IMM_U: imm = {instr[31:12], 12'b0};
            `CPU_IMM_J: imm = {{11{instr[31]}}, instr[31], instr[19:12],
                              instr[20], instr[30:21], 1'b0};
            default:    imm = 32'b0; // NONE and reserved selectors.
        endcase
    end

endmodule
