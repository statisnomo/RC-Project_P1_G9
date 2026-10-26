`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Combinational RV32I ALU. Encodings are part of the CPU/decode interface.
// 0 ADD   1 SUB   2 AND   3 OR    4 XOR
// 5 SLL   6 SRL   7 SRA   8 SLT   9 SLTU
// A-F are reserved and produce zero. See docs/cpu_blocks.md.
module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero
);

    localparam [3:0] ALU_ADD  = `CPU_ALU_ADD;
    localparam [3:0] ALU_SUB  = `CPU_ALU_SUB;
    localparam [3:0] ALU_AND  = `CPU_ALU_AND;
    localparam [3:0] ALU_OR   = `CPU_ALU_OR;
    localparam [3:0] ALU_XOR  = `CPU_ALU_XOR;
    localparam [3:0] ALU_SLL  = `CPU_ALU_SLL;
    localparam [3:0] ALU_SRL  = `CPU_ALU_SRL;
    localparam [3:0] ALU_SRA  = `CPU_ALU_SRA;
    localparam [3:0] ALU_SLT  = `CPU_ALU_SLT;
    localparam [3:0] ALU_SLTU = `CPU_ALU_SLTU;

    always @* begin
        case (alu_op)
            ALU_ADD:  result = operand_a + operand_b;
            ALU_SUB:  result = operand_a - operand_b;
            ALU_AND:  result = operand_a & operand_b;
            ALU_OR:   result = operand_a | operand_b;
            ALU_XOR:  result = operand_a ^ operand_b;
            ALU_SLL:  result = operand_a << operand_b[4:0];
            ALU_SRL:  result = operand_a >> operand_b[4:0];
            ALU_SRA:  result = $signed(operand_a) >>> operand_b[4:0];
            ALU_SLT:  result = {31'b0, ($signed(operand_a) < $signed(operand_b))};
            ALU_SLTU: result = {31'b0, (operand_a < operand_b)};
            default:  result = 32'b0;
        endcase
    end

    // SUB with zero asserted means the two input operands are equal.
    assign zero = (result == 32'b0);

endmodule
