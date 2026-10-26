`timescale 1ns / 1ps

// Golden instruction rules use literal ISA masks and numeric control values,
// independently of cpu_defs.vh. All datapath checks here are combinational;
// they do not model a pipeline, memory transactions, or architectural traps.
module tb_decode;
    reg [31:0] instr;
    wire [4:0] rs1, rs2, rd;
    wire rs1_used, rs2_used;
    wire [3:0] alu_op;
    wire [1:0] alu_a_sel;
    wire alu_b_imm;
    wire [2:0] imm_sel;
    wire reg_write;
    wire [1:0] wb_sel;
    wire mem_read, mem_write;
    wire [1:0] mem_size;
    wire mem_unsigned;
    wire [2:0] branch_op;
    wire jump, jalr, illegal;
    wire [25:0] actual_controls;

    reg [31:0] masks [0:36];
    reg [31:0] encodings [0:36];
    reg [25:0] controls [0:36];
    integer rule_hits [0:36];
    integer rule_count;
    integer checks;
    integer execution_checks;
    integer errors;
    integer rule_index;
    integer iteration;
    integer function3;
    integer function7;
    integer opcode;
    reg [31:0] random_state;
    reg [31:0] word;

    reg [31:0] pc;
    reg [31:0] rs1_value;
    reg [31:0] rs2_value;
    reg [31:0] memory_value;
    wire [31:0] immediate;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire alu_zero;
    wire [31:0] writeback_value;
    wire [31:0] target;
    reg branch_taken;

    decode dut (
        .instr(instr), .rs1(rs1), .rs2(rs2), .rd(rd),
        .rs1_used(rs1_used), .rs2_used(rs2_used),
        .alu_op(alu_op), .alu_a_sel(alu_a_sel), .alu_b_imm(alu_b_imm),
        .imm_sel(imm_sel), .reg_write(reg_write), .wb_sel(wb_sel),
        .mem_read(mem_read), .mem_write(mem_write), .mem_size(mem_size),
        .mem_unsigned(mem_unsigned), .branch_op(branch_op),
        .jump(jump), .jalr(jalr), .illegal(illegal)
    );

    assign actual_controls = {rs1_used, rs2_used, alu_op, alu_a_sel,
                              alu_b_imm, imm_sel, reg_write, wb_sel,
                              mem_read, mem_write, mem_size, mem_unsigned,
                              branch_op, jump, jalr, illegal};
    imm_gen immediates (.instr(instr), .imm_sel(imm_sel), .imm(immediate));
    assign alu_a = (alu_a_sel == 2'd1) ? pc :
                   (alu_a_sel == 2'd2) ? 32'd0 : rs1_value;
    assign alu_b = alu_b_imm ? immediate : rs2_value;
    alu execution_alu (.operand_a(alu_a), .operand_b(alu_b),
                       .alu_op(alu_op), .result(alu_result), .zero(alu_zero));
    assign writeback_value = (wb_sel == 2'd1) ? memory_value :
                             (wb_sel == 2'd2) ? pc + 32'd4 : alu_result;
    assign target = (branch_op != 0) ? pc + immediate :
                    jalr ? (alu_result & 32'hfffffffe) : alu_result;
    always @* begin
        case (branch_op)
            3'd1: branch_taken = alu_zero;
            3'd2: branch_taken = !alu_zero;
            3'd3, 3'd5: branch_taken = alu_result[0];
            3'd4, 3'd6: branch_taken = !alu_result[0];
            default: branch_taken = 1'b0;
        endcase
    end

    function [31:0] next_random;
        input [31:0] state;
        reg [31:0] mixed;
        begin
            mixed = state ^ (state << 13);
            mixed = mixed ^ (mixed >> 17);
            next_random = mixed ^ (mixed << 5);
        end
    endfunction

    // Arguments follow the documented control contract, not implementation.
    function [25:0] control;
        input use1, use2;
        input [3:0] operation;
        input [1:0] a_select;
        input b_immediate;
        input [2:0] immediate_select;
        input write_register;
        input [1:0] writeback_select;
        input read_memory, write_memory;
        input [1:0] size;
        input unsigned_load;
        input [2:0] branch;
        input is_jump, indirect_jump;
        begin
            control = {use1, use2, operation, a_select, b_immediate,
                       immediate_select, write_register, writeback_select,
                       read_memory, write_memory, size, unsigned_load,
                       branch, is_jump, indirect_jump, 1'b0};
        end
    endfunction

    task add_rule;
        input [31:0] mask;
        input [31:0] encoding;
        input [25:0] expected_controls;
        begin
            masks[rule_count] = mask;
            encodings[rule_count] = encoding;
            controls[rule_count] = expected_controls;
            rule_hits[rule_count] = 0;
            rule_count = rule_count + 1;
        end
    endtask

    task check_decode;
        input [31:0] instruction;
        reg [25:0] expected;
        integer index;
        integer rule_matches;
        begin
            // Illegal: all controls zero except word memory size and flag.
            expected = {1'b0, 1'b0, 4'd0, 2'd0, 1'b0, 3'd0, 1'b0,
                        2'd0, 1'b0, 1'b0, 2'd2, 1'b0, 3'd0, 1'b0, 1'b0, 1'b1};
            rule_matches = 0;
            for (index = 0; index < rule_count; index = index + 1) begin
                if ((instruction & masks[index]) == encodings[index]) begin
                    expected = controls[index];
                    rule_matches = rule_matches + 1;
                    rule_hits[index] = rule_hits[index] + 1;
                end
            end
            if (rule_matches > 1)
                $fatal(1, "Invalid test oracle: overlapping rules for %h", instruction);
            instr = instruction;
            #1;
            checks = checks + 1;
            if ((actual_controls !== expected) ||
                (rs1 !== instruction[19:15]) ||
                (rs2 !== instruction[24:20]) ||
                (rd !== instruction[11:7])) begin
                errors = errors + 1;
                $display("FAIL decode check=%0d instr=%h controls=%h expected=%h rs1=%0d rs2=%0d rd=%0d",
                         checks, instruction, actual_controls, expected, rs1, rs2, rd);
            end
        end
    endtask

    function [31:0] encode_i;
        input [31:0] immediate_value;
        input [2:0] funct3;
        input [6:0] instruction_opcode;
        begin
            encode_i = {immediate_value[11:0], 5'd3, funct3, 5'd5, instruction_opcode};
        end
    endfunction

    function [31:0] encode_b;
        input [31:0] offset;
        input [2:0] funct3;
        begin
            encode_b = {offset[12], offset[10:5], 5'd4, 5'd3, funct3,
                        offset[4:1], offset[11], 7'h63};
        end
    endfunction

    task check_execution;
        input [31:0] instruction;
        input [31:0] instruction_pc;
        input [31:0] source1, source2;
        input [31:0] expected_alu;
        input [31:0] expected_writeback;
        input expected_branch;
        input [31:0] expected_target;
        begin
            pc = instruction_pc;
            rs1_value = source1;
            rs2_value = source2;
            memory_value = 32'hcafe1234;
            check_decode(instruction);
            execution_checks = execution_checks + 1;
            if ((illegal !== 1'b0) || (alu_result !== expected_alu) ||
                (writeback_value !== expected_writeback) ||
                (branch_taken !== expected_branch) ||
                (((jump === 1'b1) || (branch_op !== 3'd0)) &&
                 (target !== expected_target))) begin
                errors = errors + 1;
                $display("FAIL combinational execution instr=%h alu=%h/%h wb=%h/%h branch=%b/%b target=%h/%h",
                         instruction, alu_result, expected_alu,
                         writeback_value, expected_writeback, branch_taken,
                         expected_branch, target, expected_target);
            end
        end
    endtask

    initial begin
        instr = 0;
        pc = 0;
        rs1_value = 0;
        rs2_value = 0;
        memory_value = 0;
        rule_count = 0;
        checks = 0;
        execution_checks = 0;
        errors = 0;
        random_state = 32'hdec0de37;

        // control(use1,use2,ALU,A,Bimm,imm,regwr,WB,read,write,size,unsigned,branch,jump,jalr)
        // R arithmetic: ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND.
        add_rule(32'hfe00707f, 32'h00000033, control(1,1,0,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h40000033, control(1,1,1,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00001033, control(1,1,5,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00002033, control(1,1,8,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00003033, control(1,1,9,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00004033, control(1,1,4,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00005033, control(1,1,6,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h40005033, control(1,1,7,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00006033, control(1,1,3,0,0,0,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00007033, control(1,1,2,0,0,0,1,0,0,0,2,0,0,0,0));
        // Nonshift OP-IMM ignores all 12 immediate bits in its rule mask.
        add_rule(32'h0000707f, 32'h00000013, control(1,0,0,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00002013, control(1,0,8,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00003013, control(1,0,9,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00004013, control(1,0,4,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00006013, control(1,0,3,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00007013, control(1,0,2,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00001013, control(1,0,5,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h00005013, control(1,0,6,0,1,1,1,0,0,0,2,0,0,0,0));
        add_rule(32'hfe00707f, 32'h40005013, control(1,0,7,0,1,1,1,0,0,0,2,0,0,0,0));
        // LUI, AUIPC, JAL, JALR.
        add_rule(32'h0000007f, 32'h00000037, control(0,0,0,2,1,4,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000007f, 32'h00000017, control(0,0,0,1,1,4,1,0,0,0,2,0,0,0,0));
        add_rule(32'h0000007f, 32'h0000006f, control(0,0,0,1,1,5,1,2,0,0,2,0,0,1,0));
        add_rule(32'h0000707f, 32'h00000067, control(1,0,0,0,1,1,1,2,0,0,2,0,0,1,1));
        // BEQ/BNE/BLT/BGE/BLTU/BGEU compare register operands.
        add_rule(32'h0000707f, 32'h00000063, control(1,1,1,0,0,3,0,0,0,0,2,0,1,0,0));
        add_rule(32'h0000707f, 32'h00001063, control(1,1,1,0,0,3,0,0,0,0,2,0,2,0,0));
        add_rule(32'h0000707f, 32'h00004063, control(1,1,8,0,0,3,0,0,0,0,2,0,3,0,0));
        add_rule(32'h0000707f, 32'h00005063, control(1,1,8,0,0,3,0,0,0,0,2,0,4,0,0));
        add_rule(32'h0000707f, 32'h00006063, control(1,1,9,0,0,3,0,0,0,0,2,0,5,0,0));
        add_rule(32'h0000707f, 32'h00007063, control(1,1,9,0,0,3,0,0,0,0,2,0,6,0,0));
        // LB/LH/LW/LBU/LHU and SB/SH/SW.
        add_rule(32'h0000707f, 32'h00000003, control(1,0,0,0,1,1,1,1,1,0,0,0,0,0,0));
        add_rule(32'h0000707f, 32'h00001003, control(1,0,0,0,1,1,1,1,1,0,1,0,0,0,0));
        add_rule(32'h0000707f, 32'h00002003, control(1,0,0,0,1,1,1,1,1,0,2,0,0,0,0));
        add_rule(32'h0000707f, 32'h00004003, control(1,0,0,0,1,1,1,1,1,0,0,1,0,0,0));
        add_rule(32'h0000707f, 32'h00005003, control(1,0,0,0,1,1,1,1,1,0,1,1,0,0,0));
        add_rule(32'h0000707f, 32'h00000023, control(1,1,0,0,1,2,0,0,0,1,0,0,0,0,0));
        add_rule(32'h0000707f, 32'h00001023, control(1,1,0,0,1,2,0,0,0,1,1,0,0,0,0));
        add_rule(32'h0000707f, 32'h00002023, control(1,1,0,0,1,2,0,0,0,1,2,0,0,0,0));
        if (rule_count != 37)
            $fatal(1, "Test oracle must contain exactly 37 instructions");

        // Every instruction with zero/all-one register fields and randomized
        // free bits. rd=x0 must retain reg_write and loads' memory effects;
        // operand-use flags likewise remain asserted for an x0 source.
        for (rule_index = 0; rule_index < 37; rule_index = rule_index + 1) begin
            check_decode(encodings[rule_index]);
            check_decode(encodings[rule_index] | ~masks[rule_index]);
            for (iteration = 0; iteration < 16; iteration = iteration + 1) begin
                random_state = next_random(random_state);
                word = encodings[rule_index] | (random_state & ~masks[rule_index]);
                check_decode(word);
                check_decode(word & 32'hfffff07f); // force raw rd to x0
            end
        end

        // Exhaust all funct7/funct3 combinations, with variable register/shamt
        // fields. R-type includes the M extension and reserved encodings.
        // OP-IMM sweep verifies that nonshift upper immediates remain data.
        for (function7 = 0; function7 < 128; function7 = function7 + 1) begin
            for (function3 = 0; function3 < 8; function3 = function3 + 1) begin
                random_state = next_random(random_state);
                word = {function7[6:0], random_state[24:15], function3[2:0],
                        random_state[11:7], 7'h33};
                check_decode(word);
                check_decode({word[31:7], 7'h13});
            end
        end
        for (function3 = 0; function3 < 8; function3 = function3 + 1) begin
            random_state = next_random(random_state);
            word = {random_state[31:15], function3[2:0], random_state[11:7], 7'h03};
            check_decode(word);
            check_decode({word[31:7], 7'h23});
            check_decode({word[31:7], 7'h63});
            check_decode({word[31:7], 7'h67});
        end

        // All opcode patterns, including compressed low-bit patterns, custom,
        // SYSTEM/CSR, FENCE, atomics, floating point and wider-word forms.
        for (opcode = 0; opcode < 128; opcode = opcode + 1) begin
            check_decode(32'hfff1c283); // legal LBU with nondefault effects
            random_state = next_random(random_state);
            check_decode({random_state[31:7], opcode[6:0]});
        end
        check_decode(32'h0000000f); // FENCE
        check_decode(32'h0000100f); // FENCE.I
        check_decode(32'h00000073); // ECALL
        check_decode(32'h00100073); // EBREAK
        check_decode(32'h300192f3); // CSRRW
        check_decode(32'h024182b3); // MUL
        check_decode(32'h0000000b); // custom-0
        check_decode(32'h0000002b); // custom-1
        check_decode(32'h0000005b); // custom-2
        check_decode(32'h0000007b); // custom-3
        check_decode(32'h00000001); // C.NOP pattern
        check_decode(32'h00008082); // C.JR pattern
        for (iteration = 0; iteration < 4096; iteration = iteration + 1) begin
            random_state = next_random(random_state);
            check_decode(random_state);
        end

        // Minimal integration of decode/immediate/ALU with explicit operand,
        // PC+4, branch-target and JALR bit-zero muxes in this testbench only.
        check_execution(32'h800012b7, 32'h100, 32'hdeadbeef, 32'hcafebabe,
                        32'h80001000, 32'h80001000, 0, 0); // LUI
        check_execution(32'hfffff297, 32'h1234, 0, 0,
                        32'h234, 32'h234, 0, 0); // AUIPC -4096
        check_execution(encode_i(-32'd7, 3'd0, 7'h13), 0, 32'd10, 32'hffffffff,
                        32'd3, 32'd3, 0, 0); // ADDI
        check_execution(encode_i(-32'd1, 3'd3, 7'h13), 0, 32'h80000000, 0,
                        32'd1, 32'd1, 0, 0); // SLTIU sign-extended -1
        check_execution(encode_i(32'h41f, 3'd5, 7'h13), 0, 32'h80000000, 0,
                        32'hffffffff, 32'hffffffff, 0, 0); // SRAI 31
        check_execution(encode_i(-32'd4, 3'd2, 7'h03), 0, 32'h1004, 0,
                        32'h1000, 32'hcafe1234, 0, 0); // LW address + WB mux
        check_execution({7'h7f,5'd4,5'd3,3'd2,5'd28,7'h23}, 0, 32'h1004, 32'hface1234,
                        32'h1000, 32'h1000, 0, 0); // SW -4
        check_execution(encode_b(-32'd8, 3'd0), 32'h100, 32'd5, 32'd5,
                        32'd0, 32'd0, 1, 32'hf8); // BEQ taken
        check_execution(encode_b(32'd8, 3'd1), 32'h100, 32'd5, 32'd5,
                        32'd0, 32'd0, 0, 32'h108); // BNE not taken
        check_execution(encode_b(-32'd8, 3'd4), 32'h100, 32'hffffffff, 32'd1,
                        32'd1, 32'd1, 1, 32'hf8); // BLT signed
        check_execution(encode_b(32'd8, 3'd5), 32'h100, 32'hffffffff, 32'd1,
                        32'd1, 32'd1, 0, 32'h108); // BGE signed
        check_execution(encode_b(32'd8, 3'd6), 32'h100, 32'hffffffff, 32'd1,
                        32'd0, 32'd0, 0, 32'h108); // BLTU unsigned
        check_execution(encode_b(-32'd8, 3'd7), 32'h100, 32'hffffffff, 32'd1,
                        32'd0, 32'd0, 1, 32'hf8); // BGEU unsigned
        check_execution(32'hff9ff2ef, 32'h100, 0, 0,
                        32'hf8, 32'h104, 0, 32'hf8); // JAL -8
        check_execution(encode_i(-32'd2, 3'd0, 7'h67), 32'h100, 32'h107, 0,
                        32'h105, 32'h104, 0, 32'h104); // JALR clears bit zero

        for (rule_index = 0; rule_index < 37; rule_index = rule_index + 1)
            if (rule_hits[rule_index] == 0)
                $fatal(1, "Missing supported instruction coverage: rule %0d", rule_index);
        if (errors != 0)
            $fatal(1, "FAIL tb_decode: %0d failures in %0d decode / %0d execution checks",
                   errors, checks, execution_checks);
        $display("PASS tb_decode: %0d decode checks, all 37 instructions, %0d combinational execution checks",
                 checks, execution_checks);
        $finish;
    end
endmodule
