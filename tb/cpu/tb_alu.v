`timescale 1ns / 1ps

// Run with a simulator that supports $fatal (for Icarus: -g2012).
// The testbench otherwise uses Verilog-2005 syntax.
module tb_alu;
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero;

    integer checks;
    integer errors;
    integer vector_index;
    integer operation_index;
    reg [31:0] random_state;
    reg [31:0] random_a;
    reg [31:0] random_b;

    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    // Fixed-seed xorshift32 makes runs reproducible across simulators.
    function [31:0] next_random;
        input [31:0] state;
        reg [31:0] value;
        begin
            value = state ^ (state << 13);
            value = value ^ (value >> 17);
            next_random = value ^ (value << 5);
        end
    endfunction

    // Model shifts one bit at a time and signed comparisons by sign bit,
    // independently of the DUT's likely variable-shift/$signed expressions.
    function [31:0] expected_result;
        input [31:0] a;
        input [31:0] b;
        input [3:0] operation;
        reg [31:0] shifted;
        integer bit_index;
        begin
            shifted = a;
            expected_result = 32'h00000000;
            case (operation)
                4'h0: expected_result = a + b;
                4'h1: expected_result = a - b;
                4'h2: expected_result = a & b;
                4'h3: expected_result = a | b;
                4'h4: expected_result = a ^ b;
                4'h5, 4'h6, 4'h7: begin
                    for (bit_index = 0; bit_index < b[4:0];
                         bit_index = bit_index + 1) begin
                        case (operation)
                            4'h5: shifted = {shifted[30:0], 1'b0};
                            4'h6: shifted = {1'b0, shifted[31:1]};
                            4'h7: shifted = {shifted[31], shifted[31:1]};
                        endcase
                    end
                    expected_result = shifted;
                end
                4'h8: begin
                    if (a[31] != b[31])
                        expected_result = {31'b0, a[31]};
                    else
                        expected_result = (a < b) ? 32'd1 : 32'd0;
                end
                4'h9: expected_result = (a < b) ? 32'd1 : 32'd0;
                default: expected_result = 32'h00000000;
            endcase
        end
    endfunction

    task check;
        input [31:0] a;
        input [31:0] b;
        input [3:0] operation;
        input [31:0] expected;
        begin
            operand_a = a;
            operand_b = b;
            alu_op = operation;
            #1;
            checks = checks + 1;
            if ((result !== expected) || (zero !== (expected == 0))) begin
                errors = errors + 1;
                $display("FAIL ALU check=%0d op=%h a=%h b=%h result=%h expected=%h zero=%b expected_zero=%b",
                         checks, operation, a, b, result, expected,
                         zero, (expected == 0));
            end
        end
    endtask

    initial begin
        checks = 0;
        errors = 0;
        operand_a = 0;
        operand_b = 0;
        alu_op = 0;
        random_state = 32'h1badf00d;

        // Carry/borrow and signed overflow wrap at 32 bits.
        check(32'hffffffff, 32'h00000001, 4'h0, 32'h00000000);
        check(32'h7fffffff, 32'h00000001, 4'h0, 32'h80000000);
        check(32'h80000000, 32'h80000000, 4'h0, 32'h00000000);
        check(32'h00000000, 32'h00000001, 4'h1, 32'hffffffff);
        check(32'h80000000, 32'h00000001, 4'h1, 32'h7fffffff);
        check(32'h13579bdf, 32'h13579bdf, 4'h1, 32'h00000000);
        check(32'ha5a5a5a5, 32'h5a5a5a5a, 4'h2, 32'h00000000);
        check(32'ha5a5a5a5, 32'h5a5a5a5a, 4'h3, 32'hffffffff);
        check(32'ha5a5a5a5, 32'ha5a5a5a5, 4'h4, 32'h00000000);
        check(32'hff00ff00, 32'h0f0f0f0f, 4'h2, 32'h0f000f00);
        check(32'hff00ff00, 32'h0f0f0f0f, 4'h3, 32'hff0fff0f);
        check(32'hff00ff00, 32'h0f0f0f0f, 4'h4, 32'hf00ff00f);

        // Shift limits, sign extension, and the required five-bit mask.
        check(32'h80000001, 32'd0,  4'h5, 32'h80000001);
        check(32'h80000001, 32'd31, 4'h5, 32'h80000000);
        check(32'h80000001, 32'd32, 4'h5, 32'h80000001);
        check(32'h80000001, 32'd33, 4'h5, 32'h00000002);
        check(32'h80000001, 32'd31, 4'h6, 32'h00000001);
        check(32'h80000001, 32'd32, 4'h6, 32'h80000001);
        check(32'h80000001, 32'hffffffff, 4'h6, 32'h00000001);
        check(32'h80000001, 32'd1,  4'h7, 32'hc0000000);
        check(32'h80000001, 32'd31, 4'h7, 32'hffffffff);
        check(32'h80000001, 32'd32, 4'h7, 32'h80000001);
        check(32'h7fffffff, 32'd31, 4'h7, 32'h00000000);
        check(32'h80000001, 32'hffffffc1, 4'h7, 32'hc0000000);

        // SLT and SLTU differ across the sign boundary; equality is false.
        check(32'hffffffff, 32'h00000001, 4'h8, 32'd1);
        check(32'hffffffff, 32'h00000001, 4'h9, 32'd0);
        check(32'h00000001, 32'hffffffff, 4'h8, 32'd0);
        check(32'h00000001, 32'hffffffff, 4'h9, 32'd1);
        check(32'h80000000, 32'hffffffff, 4'h8, 32'd1);
        check(32'hffffffff, 32'h80000000, 4'h8, 32'd0);
        check(32'h80000000, 32'h7fffffff, 4'h8, 32'd1);
        check(32'h80000000, 32'h7fffffff, 4'h9, 32'd0);
        check(32'h80000000, 32'h80000000, 4'h8, 32'd0);
        check(32'hffffffff, 32'hffffffff, 4'h9, 32'd0);

        // Enter each unsupported opcode from a nonzero result. This catches
        // a missing default assignment that would otherwise retain a value.
        for (operation_index = 10; operation_index < 16;
             operation_index = operation_index + 1) begin
            check(32'h12345678, 32'h00000000, 4'h0, 32'h12345678);
            check(32'hffffffff, 32'hffffffff, operation_index[3:0], 32'd0);
        end

        for (vector_index = 0; vector_index < 256;
             vector_index = vector_index + 1) begin
            random_state = next_random(random_state);
            random_a = random_state;
            random_state = next_random(random_state);
            random_b = random_state;
            for (operation_index = 0; operation_index < 16;
                 operation_index = operation_index + 1)
                check(random_a, random_b, operation_index[3:0],
                      expected_result(random_a, random_b, operation_index[3:0]));
        end

        if (errors != 0)
            $fatal(1, "FAIL tb_alu: %0d of %0d checks failed", errors, checks);
        $display("PASS tb_alu: %0d checks", checks);
        $finish;
    end
endmodule
