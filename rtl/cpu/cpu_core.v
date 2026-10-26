`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Three logical stages: fetch, decode/read, execute/memory/writeback.
// Both buses complete exactly once at a rising edge with valid && ready.
// Request fields stay stable until completion; reset cancels pending work.
module cpu_core #(
    parameter [31:0] RESET_PC = 32'h00000000
) (
    input wire clk, input wire rst,
    output wire imem_valid, output wire [31:0] imem_addr,
    input wire imem_ready, input wire [31:0] imem_rdata, input wire imem_error,
    output wire dmem_valid, output wire dmem_write,
    output wire [31:0] dmem_addr, output wire [31:0] dmem_wdata,
    output wire [3:0] dmem_wstrb, output wire [1:0] dmem_size,
    input wire dmem_ready, input wire [31:0] dmem_rdata, input wire dmem_error,
    output reg halted, output reg [3:0] fault_code,
    output reg [31:0] fault_pc, output reg [31:0] fault_value,
    output reg trace_valid, output reg [31:0] trace_pc,
    output reg [31:0] trace_instr, output reg trace_rd_we,
    output reg [4:0] trace_rd, output reg [31:0] trace_wdata
);
    reg [31:0] next_pc, f_pc;
    reg f_active, f_discard;
    reg d_valid, d_fetch_error;
    reg [31:0] d_pc, d_instr;
    reg e_valid, e_fetch_error, e_illegal;
    reg [31:0] e_pc, e_instr, e_rs1, e_rs2, e_imm;
    reg [4:0] e_rd;
    reg [3:0] e_alu_op;
    reg [1:0] e_a_sel, e_wb_sel, e_mem_size;
    reg [2:0] e_branch_op;
    reg e_b_imm, e_reg_write, e_mem_read, e_mem_write, e_mem_unsigned;
    reg e_jump, e_jalr;

    wire [4:0] d_rs1, d_rs2, d_rd;
    wire d_rs1_used, d_rs2_used, d_b_imm, d_reg_write;
    wire d_mem_read, d_mem_write, d_mem_unsigned, d_jump, d_jalr, d_illegal;
    wire [3:0] d_alu_op;
    wire [1:0] d_a_sel, d_wb_sel, d_mem_size;
    wire [2:0] d_imm_sel, d_branch_op;
    wire [31:0] d_imm, rf_rs1, rf_rs2;
    decode decoder (
        .instr(d_instr), .rs1(d_rs1), .rs2(d_rs2), .rd(d_rd),
        .rs1_used(d_rs1_used), .rs2_used(d_rs2_used), .alu_op(d_alu_op),
        .alu_a_sel(d_a_sel), .alu_b_imm(d_b_imm), .imm_sel(d_imm_sel),
        .reg_write(d_reg_write), .wb_sel(d_wb_sel), .mem_read(d_mem_read),
        .mem_write(d_mem_write), .mem_size(d_mem_size), .mem_unsigned(d_mem_unsigned),
        .branch_op(d_branch_op), .jump(d_jump), .jalr(d_jalr), .illegal(d_illegal)
    );
    imm_gen immediates (.instr(d_instr), .imm_sel(d_imm_sel), .imm(d_imm));
    wire [31:0] alu_a = (e_a_sel == `CPU_A_PC) ? e_pc :
                             (e_a_sel == `CPU_A_ZERO) ? 32'b0 : e_rs1;
    wire [31:0] alu_b = e_b_imm ? e_imm : e_rs2;
    wire [31:0] alu_result;
    alu execution_alu (.operand_a(alu_a), .operand_b(alu_b),
                       .alu_op(e_alu_op), .result(alu_result), .zero());

    // Branch decisions do not need the general ALU's operation/result mux.
    // Separate address addition also keeps shifts/logic out of memory control.
    wire [31:0] data_address = e_rs1 + e_imm;
    wire [31:0] pc_relative_target = e_pc + e_imm;
    wire compare_equal = e_rs1 == e_rs2;
    wire compare_signed_less = $signed(e_rs1) < $signed(e_rs2);
    wire compare_unsigned_less = e_rs1 < e_rs2;
    reg branch_taken;
    always @* begin
        case (e_branch_op)
            `CPU_BR_EQ:  branch_taken = compare_equal;
            `CPU_BR_NE:  branch_taken = !compare_equal;
            `CPU_BR_LT:  branch_taken = compare_signed_less;
            `CPU_BR_GE:  branch_taken = !compare_signed_less;
            `CPU_BR_LTU: branch_taken = compare_unsigned_less;
            `CPU_BR_GEU: branch_taken = !compare_unsigned_less;
            default: branch_taken = 1'b0;
        endcase
    end
    wire control_taken = e_jump || branch_taken;
    wire [31:0] target = e_jalr ? (data_address & 32'hfffffffe) : pc_relative_target;
    wire data_misaligned = (e_mem_size == `CPU_MEM_WORD && data_address[1:0] != 0) ||
                           (e_mem_size == `CPU_MEM_HALF && data_address[0]);
    // Prioritize fetch errors over decoding an invalid/unavailable word.
    reg [3:0] local_fault;
    reg [31:0] local_fault_value;
    always @* begin
        local_fault = 0;
        local_fault_value = 0;
        if (e_pc[1:0] != 0) begin
            local_fault = 2; local_fault_value = e_pc;
        end else if (e_fetch_error) begin
            local_fault = 3; local_fault_value = e_pc;
        end else if (e_illegal) begin
            local_fault = 1; local_fault_value = e_instr;
        end else if (control_taken && target[1:0] != 0) begin
            local_fault = 2; local_fault_value = target;
        end else if ((e_mem_read || e_mem_write) && data_misaligned) begin
            local_fault = e_mem_write ? 5 : 4; local_fault_value = data_address;
        end
    end
    assign imem_valid = f_active && !rst;
    assign imem_addr = f_pc;
    // Decode guarantees memory instructions cannot also be branches/jumps.
    // Gate requests with memory-relevant faults, not branch-target checks.
    assign dmem_valid = e_valid && !halted && !rst &&
                        (e_pc[1:0] == 0) && !e_fetch_error && !e_illegal &&
                        !data_misaligned && (e_mem_read || e_mem_write);
    assign dmem_write = e_mem_write;
    assign dmem_addr = data_address; // Byte address; slave returns the containing word.
    assign dmem_size = e_mem_size;
    wire [3:0] lane_mask = (e_mem_size == `CPU_MEM_BYTE) ? 4'b0001 :
                           (e_mem_size == `CPU_MEM_HALF) ? 4'b0011 : 4'b1111;
    assign dmem_wstrb = e_mem_write ? (lane_mask << data_address[1:0]) : 4'b0000;
    assign dmem_wdata = e_rs2 << {data_address[1:0], 3'b000};
    wire [31:0] shifted_load = dmem_rdata >> {data_address[1:0], 3'b000};
    reg [31:0] load_value;
    always @* begin
        case (e_mem_size)
            `CPU_MEM_BYTE: load_value = {{24{!e_mem_unsigned && shifted_load[7]}}, shifted_load[7:0]};
            `CPU_MEM_HALF: load_value = {{16{!e_mem_unsigned && shifted_load[15]}}, shifted_load[15:0]};
            default: load_value = shifted_load;
        endcase
    end
    wire [31:0] wb_value = (e_wb_sel == `CPU_WB_PC4) ? e_pc + 32'd4 :
                           (e_wb_sel == `CPU_WB_MEM) ? load_value : alu_result;
    wire bus_fault = dmem_valid && dmem_ready && dmem_error;
    wire e_fault = e_valid && ((local_fault != 0) || bus_fault);
    wire e_complete = e_valid && ((local_fault != 0) ||
                          !(e_mem_read || e_mem_write) || dmem_ready);
    wire commit = e_complete && !e_fault && !halted && !rst;
    wire rf_we = commit && e_reg_write && (e_rd != 0);
    regfile registers (.clk(clk), .rst(rst), .we(rf_we), .waddr(e_rd), .wdata(wb_value),
                        .raddr1(d_rs1), .rdata1(rf_rs1), .raddr2(d_rs2), .rdata2(rf_rs2));
    // A completing load can feed decode on this very edge. While it waits,
    // execute and decode are held, so no consumer can see an old register value.
    wire [31:0] d_value1 = (d_rs1_used && rf_we && e_rd == d_rs1) ? wb_value : rf_rs1;
    wire [31:0] d_value2 = (d_rs2_used && rf_we && e_rd == d_rs2) ? wb_value : rf_rs2;
    wire redirect = commit && control_taken;
    wire d_advance = d_valid && (!e_valid || e_complete) && !e_fault && !redirect && !halted && !rst;

    always @(posedge clk) begin
        if (rst) begin
            next_pc <= RESET_PC; f_pc <= RESET_PC;
            f_active <= 0; f_discard <= 0;
            d_valid <= 0; d_fetch_error <= 0; d_pc <= 0; d_instr <= 0;
            e_valid <= 0; e_fetch_error <= 0; e_illegal <= 0;
            e_pc <= 0; e_instr <= 0; e_rs1 <= 0; e_rs2 <= 0; e_imm <= 0; e_rd <= 0;
            e_alu_op <= 0; e_a_sel <= 0; e_wb_sel <= 0; e_mem_size <= 0;
            e_branch_op <= 0; e_b_imm <= 0; e_reg_write <= 0;
            e_mem_read <= 0; e_mem_write <= 0; e_mem_unsigned <= 0; e_jump <= 0; e_jalr <= 0;
            halted <= 0; fault_code <= 0; fault_pc <= 0; fault_value <= 0;
            trace_valid <= 0; trace_pc <= 0; trace_instr <= 0;
            trace_rd_we <= 0; trace_rd <= 0; trace_wdata <= 0;
        end else begin
            trace_valid <= commit;
            trace_rd_we <= rf_we;
            if (commit) begin
                trace_pc <= e_pc; trace_instr <= e_instr;
                trace_rd <= e_rd; trace_wdata <= wb_value;
            end
            // Reserve the decode slot before issuing a single fetch request.
            if (!f_active && (!d_valid || d_advance) && !halted && !e_fault && !redirect) begin
                f_active <= 1; f_discard <= 0; f_pc <= next_pc;
                next_pc <= next_pc + 32'd4;
            end
            if (d_advance) d_valid <= 0;
            if (f_active && imem_ready) begin
                f_active <= 0;
                if (!f_discard && !halted && !e_fault && !redirect) begin
                    d_valid <= 1; d_pc <= f_pc;
                    d_instr <= imem_rdata; d_fetch_error <= imem_error;
                end
            end
            if (e_complete) e_valid <= 0;
            if (d_advance) begin
                e_valid <= 1; e_pc <= d_pc; e_instr <= d_instr;
                e_fetch_error <= d_fetch_error; e_illegal <= d_illegal;
                e_rs1 <= d_value1; e_rs2 <= d_value2; e_imm <= d_imm; e_rd <= d_rd;
                e_alu_op <= d_alu_op; e_a_sel <= d_a_sel; e_wb_sel <= d_wb_sel;
                e_mem_size <= d_mem_size; e_branch_op <= d_branch_op;
                e_b_imm <= d_b_imm; e_reg_write <= d_reg_write;
                e_mem_read <= d_mem_read; e_mem_write <= d_mem_write;
                e_mem_unsigned <= d_mem_unsigned; e_jump <= d_jump; e_jalr <= d_jalr;
            end
            if (redirect || (e_fault && !halted)) begin
                d_valid <= 0; e_valid <= 0;
                // Never withdraw an outstanding fetch: drain and discard it.
                if (f_active && !imem_ready) f_discard <= 1;
                if (redirect) next_pc <= target;
            end
            if (e_fault && !halted) begin
                halted <= 1; fault_pc <= e_pc;
                fault_code <= (local_fault != 0) ? local_fault : (e_mem_write ? 7 : 6);
                fault_value <= (local_fault != 0) ? local_fault_value : data_address;
            end
        end
    end
endmodule
