`timescale 1ns / 1ps
// CPU/BRAM subsystem plus the real AES window. Other peripherals return errors.
module soc_aes #(parameter ROM_FILE="aes_smoke.hex", parameter integer AES_WAIT_CYCLES=1) (
    input wire clk, input wire rst,
    output wire mmio_valid, output wire mmio_write,
    output wire [31:0] mmio_addr, output wire [31:0] mmio_wdata,
    output wire [3:0] mmio_wstrb, output wire [1:0] mmio_size,
    output wire mmio_ready, output wire [31:0] mmio_rdata, output wire mmio_error,
    output wire aes_busy, output wire aes_done,
    output wire halted, output wire [3:0] fault_code,
    output wire [31:0] fault_pc, output wire [31:0] fault_value,
    output wire trace_valid, output wire [31:0] trace_pc,
    output wire [31:0] trace_instr, output wire trace_rd_we,
    output wire [4:0] trace_rd, output wire [31:0] trace_wdata
);
    // The AES wrapper validates the complete address during its wait cycle.
    // Until other peripherals exist, all four exported windows use that
    // registered responder; accesses outside AES complete with an error.
    soc_minimal #(.ROM_FILE(ROM_FILE)) system (
        .clk(clk),.rst(rst),.mmio_valid(mmio_valid),.mmio_write(mmio_write),
        .mmio_addr(mmio_addr),.mmio_wdata(mmio_wdata),.mmio_wstrb(mmio_wstrb),.mmio_size(mmio_size),
        .mmio_ready(mmio_ready),.mmio_rdata(mmio_rdata),.mmio_error(mmio_error),
        .halted(halted),.fault_code(fault_code),.fault_pc(fault_pc),.fault_value(fault_value),
        .trace_valid(trace_valid),.trace_pc(trace_pc),.trace_instr(trace_instr),
        .trace_rd_we(trace_rd_we),.trace_rd(trace_rd),.trace_wdata(trace_wdata));
    aes_mmio #(.WAIT_CYCLES(AES_WAIT_CYCLES)) aes (
        .clk(clk),.rst(rst),.valid(mmio_valid),.write(mmio_write),
        .addr(mmio_addr),.wdata(mmio_wdata),.wstrb(mmio_wstrb),.size(mmio_size),
        .ready(mmio_ready),.rdata(mmio_rdata),.error(mmio_error),.busy(aes_busy),.done(aes_done));
endmodule
