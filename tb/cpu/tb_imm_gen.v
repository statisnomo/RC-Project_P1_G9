`timescale 1ns / 1ps

// Selectors and encoding builders deliberately do not include cpu_defs.vh.
// $fatal requires a SystemVerilog-capable simulation mode.
module tb_imm_gen;
    reg [31:0] instr;
    reg [2:0] imm_sel;
    wire [31:0] imm;
    integer checks;
    integer errors;
    integer offset;
    integer iteration;
    integer selector;
    reg [31:0] random_state;
    reg [31:0] value;
    reg [31:0] noise;

    imm_gen dut (.instr(instr), .imm_sel(imm_sel), .imm(imm));

    function [31:0] next_random;
        input [31:0] state;
        reg [31:0] mixed;
        begin
            mixed = state ^ (state << 13);
            mixed = mixed ^ (mixed >> 17);
            next_random = mixed ^ (mixed << 5);
        end
    endfunction

    // Start from an original byte offset, encode its fields, and compare the
    // DUT's reconstructed value with that original value (not a second
    // extraction of the instruction). Noise exercises all unrelated bits.
    function [31:0] encode_i;
        input [31:0] original;
        input [31:0] other;
        begin
            encode_i = {original[11:0], other[19:0]};
        end
    endfunction
    function [31:0] encode_s;
        input [31:0] original;
        input [31:0] other;
        begin
            encode_s = {original[11:5], other[24:12], original[4:0], other[6:0]};
        end
    endfunction
    function [31:0] encode_b;
        input [31:0] original;
        input [31:0] other;
        begin
            encode_b = {original[12], original[10:5], other[24:12],
                        original[4:1], original[11], other[6:0]};
        end
    endfunction
    function [31:0] encode_u;
        input [31:0] original;
        input [31:0] other;
        begin
            encode_u = {original[31:12], other[11:0]};
        end
    endfunction
    function [31:0] encode_j;
        input [31:0] original;
        input [31:0] other;
        begin
            encode_j = {original[20], original[10:1], original[11],
                        original[19:12], other[11:0]};
        end
    endfunction

    task check;
        input [31:0] word;
        input [2:0] selection;
        input [31:0] expected;
        begin
            instr = word;
            imm_sel = selection;
            #1;
            checks = checks + 1;
            if (imm !== expected) begin
                errors = errors + 1;
                $display("FAIL imm_gen check=%0d instr=%h sel=%0d got=%h expected=%h",
                         checks, word, selection, imm, expected);
            end
        end
    endtask

    task check_j;
        input [31:0] original;
        begin
            random_state = next_random(random_state);
            check(encode_j(original, random_state), 3'd5, original);
        end
    endtask

    initial begin
        instr = 0;
        imm_sel = 0;
        checks = 0;
        errors = 0;
        random_state = 32'h5eed1a2b;

        // Every signed 12-bit I/S offset, including -2048, -1, 0 and 2047.
        for (offset = -2048; offset <= 2047; offset = offset + 1) begin
            random_state = next_random(random_state);
            check(encode_i(offset, random_state), 3'd1, offset);
            random_state = next_random(random_state);
            check(encode_s(offset, random_state), 3'd2, offset);
        end

        // Every representable B offset: -4096 through +4094, step two.
        for (offset = -4096; offset <= 4094; offset = offset + 2) begin
            random_state = next_random(random_state);
            check(encode_b(offset, random_state), 3'd3, offset);
        end

        // J sign boundary and the separate immediate bits at 11/12/19/20.
        check_j(-32'd1048576);
        check_j(-32'd1048574);
        check_j(-32'd524288);
        check_j(-32'd4096);
        check_j(-32'd2048);
        check_j(-32'd2);
        check_j(32'd0);
        check_j(32'd2);
        check_j(32'd2048);
        check_j(32'd4096);
        check_j(32'd524288);
        check_j(32'd1048574);

        check(encode_u(32'h00000000, 32'hffffffff), 3'd4, 32'h00000000);
        check(encode_u(32'h00001000, 32'hffffffff), 3'd4, 32'h00001000);
        check(encode_u(32'h7ffff000, 32'hffffffff), 3'd4, 32'h7ffff000);
        check(encode_u(32'h80000000, 32'hffffffff), 3'd4, 32'h80000000);
        check(encode_u(32'hfffff000, 32'hffffffff), 3'd4, 32'hfffff000);

        for (iteration = 0; iteration < 1024; iteration = iteration + 1) begin
            random_state = next_random(random_state);
            // Choose an original signed J offset arithmetically, avoiding
            // the DUT's likely concatenation-based sign-extension model.
            value = (random_state % 32'd1048576) * 2;
            if (value >= 32'd1048576)
                value = value - 32'd2097152;
            random_state = next_random(random_state);
            noise = random_state;
            check(encode_j(value, noise), 3'd5, value);
            random_state = next_random(random_state);
            value = random_state & 32'hfffff000;
            check(encode_u(value, noise), 3'd4, value);
        end

        // SRAI uses I format: retain its upper immediate encoding bits.
        check(encode_i(32'h0000041f, 32'h00005013), 3'd1, 32'h0000041f);
        // Reserved selectors must clear a previously nonzero immediate.
        for (selector = 0; selector < 8; selector = selector + 1) begin
            if ((selector == 0) || (selector == 6) || (selector == 7)) begin
                for (iteration = 0; iteration < 32; iteration = iteration + 1) begin
                    check(32'hfffff000, 3'd4, 32'hfffff000);
                    random_state = next_random(random_state);
                    check(random_state, selector[2:0], 32'd0);
                end
            end
        end

        if (errors != 0)
            $fatal(1, "FAIL tb_imm_gen: %0d of %0d checks failed", errors, checks);
        $display("PASS tb_imm_gen: %0d checks", checks);
        $finish;
    end
endmodule
