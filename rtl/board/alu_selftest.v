`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Synthesizable test equipment: load a vector, then check on the next edge.
// No simulation-only delays or $display calls are used in this hardware.
module alu_selftest (
    input wire clk,
    input wire rst,
    output reg done,
    output reg failed,
    output reg [3:0] first_failure
);
    reg [3:0] test_index;
    reg check_phase;
    (* DONT_TOUCH = "yes" *) reg [31:0] operand_a, operand_b;
    (* DONT_TOUCH = "yes" *) reg [3:0] operation;
    reg [31:0] expected;
    reg [31:0] vector_a, vector_b, vector_expected;
    reg [3:0] vector_op;
    wire [31:0] alu_result;
    wire alu_zero;

    // Preserve the actual ALU hierarchy when synthesizing the fixed vectors.
    (* DONT_TOUCH = "yes", KEEP_HIERARCHY = "yes" *)
    alu checked_alu (
        .operand_a(operand_a), .operand_b(operand_b), .alu_op(operation),
        .result(alu_result), .zero(alu_zero)
    );

    always @* begin
        vector_a = 32'd0;
        vector_b = 32'd0;
        vector_op = `CPU_ALU_ADD;
        vector_expected = 32'd0;
        case (test_index)
            4'd0: begin
                vector_a = 5; vector_b = 7; vector_expected = 12;
            end
            4'd1: begin
                vector_a = 7; vector_b = 7; vector_op = `CPU_ALU_SUB;
            end
            4'd2: begin
                vector_a = 'hf0; vector_b = 'h0f; vector_op = `CPU_ALU_AND;
            end
            4'd3: begin
                vector_a = 'hf0; vector_b = 'h0f; vector_op = `CPU_ALU_OR;
                vector_expected = 'hff;
            end
            4'd4: begin
                vector_a = 'haa55; vector_b = 'h0f0f; vector_op = `CPU_ALU_XOR;
                vector_expected = 'ha55a;
            end
            4'd5: begin
                vector_a = 1; vector_b = 31; vector_op = `CPU_ALU_SLL;
                vector_expected = 32'h80000000;
            end
            4'd6: begin
                vector_a = 32'h80000000; vector_b = 31; vector_op = `CPU_ALU_SRL;
                vector_expected = 1;
            end
            4'd7: begin
                vector_a = 32'h80000000; vector_b = 31; vector_op = `CPU_ALU_SRA;
                vector_expected = 32'hffffffff;
            end
            4'd8: begin
                vector_a = 32'hffffffff; vector_b = 1; vector_op = `CPU_ALU_SLT;
                vector_expected = 1;
            end
            4'd9: begin
                vector_a = 32'hffffffff; vector_b = 1; vector_op = `CPU_ALU_SLTU;
            end
            4'd10: begin
                vector_a = 32'hffffffff; vector_b = 1;
            end
            4'd11: begin
                vector_b = 1; vector_op = `CPU_ALU_SUB;
                vector_expected = 32'hffffffff;
            end
            4'd12: begin
                vector_a = 32'h12345678; vector_b = 32; vector_op = `CPU_ALU_SLL;
                vector_expected = 32'h12345678;
            end
            4'd13: begin
                vector_a = 32'h80000001; vector_b = 1; vector_op = `CPU_ALU_SRA;
                vector_expected = 32'hc0000000;
            end
            4'd14: begin
                vector_a = 32'h80000000; vector_b = 32'h7fffffff;
                vector_op = `CPU_ALU_SLT; vector_expected = 1;
            end
            4'd15: begin
                vector_a = 32'hffffffff; vector_b = 32'hffffffff;
                vector_op = 4'hf; // Reserved ALU control must produce zero.
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            failed <= 0;
            first_failure <= 0;
            test_index <= 0;
            check_phase <= 0;
            operand_a <= 0;
            operand_b <= 0;
            operation <= `CPU_ALU_ADD;
            expected <= 0;
        end else if (!done) begin
            if (!check_phase) begin
                operand_a <= vector_a;
                operand_b <= vector_b;
                operation <= vector_op;
                expected <= vector_expected;
                check_phase <= 1;
            end else begin
                if ((alu_result != expected) || (alu_zero != (expected == 0))) begin
                    failed <= 1;
                    if (!failed)
                        first_failure <= test_index;
                end
                if (test_index == 15)
                    done <= 1;
                else
                    test_index <= test_index + 1'b1;
                check_phase <= 0;
            end
        end
    end
endmodule
