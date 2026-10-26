`timescale 1ns / 1ps
// CPU + 4 KB instruction ROM + 4 KB RAM. Four approved peripheral windows
// are exported on one MMIO port; no AES or other peripheral is implemented here.
module soc_minimal #(parameter ROM_FILE = "") (
    input wire clk, input wire rst,
    output wire mmio_valid, output wire mmio_write,
    output wire [31:0] mmio_addr, output wire [31:0] mmio_wdata,
    output wire [3:0] mmio_wstrb, output wire [1:0] mmio_size,
    input wire mmio_ready, input wire [31:0] mmio_rdata, input wire mmio_error,
    output wire halted, output wire [3:0] fault_code,
    output wire [31:0] fault_pc, output wire [31:0] fault_value,
    output wire trace_valid, output wire [31:0] trace_pc,
    output wire [31:0] trace_instr, output wire trace_rd_we,
    output wire [4:0] trace_rd, output wire [31:0] trace_wdata
);
    wire iv, ir, ie, dv, dw, dr, de, rr, re;
    wire [31:0] ia, idata, da, wd, rd, ram_data;
    wire [3:0] ws;
    wire [1:0] size;
    wire ram_selected = da[31:12] == 20'h00001;
    wire mmio_selected = da[31:10] == 22'h100000;
    assign mmio_valid = dv && mmio_selected;
    assign mmio_write = dw; assign mmio_addr = da;
    assign mmio_wdata = wd; assign mmio_wstrb = ws; assign mmio_size = size;
    assign dr = ram_selected ? rr : mmio_selected ? mmio_ready : 1'b1;
    assign rd = ram_selected ? ram_data : mmio_selected ? mmio_rdata : 32'b0;
    assign de = ram_selected ? re : mmio_selected ? mmio_error : 1'b1;
    instr_rom #(.INIT_FILE(ROM_FILE)) rom (.clk(clk), .rst(rst), .valid(iv), .addr(ia),
                                          .ready(ir), .rdata(idata), .error(ie));
    data_ram ram (.clk(clk), .rst(rst), .valid(dv && ram_selected), .write(dw),
                  .addr(da), .wdata(wd), .wstrb(ws), .ready(rr), .rdata(ram_data), .error(re));
    cpu_core cpu (.clk(clk), .rst(rst), .imem_valid(iv), .imem_addr(ia),
        .imem_ready(ir), .imem_rdata(idata), .imem_error(ie),
        .dmem_valid(dv), .dmem_write(dw), .dmem_addr(da), .dmem_wdata(wd),
        .dmem_wstrb(ws), .dmem_size(size), .dmem_ready(dr), .dmem_rdata(rd), .dmem_error(de),
        .halted(halted), .fault_code(fault_code), .fault_pc(fault_pc), .fault_value(fault_value),
        .trace_valid(trace_valid), .trace_pc(trace_pc), .trace_instr(trace_instr),
        .trace_rd_we(trace_rd_we), .trace_rd(trace_rd), .trace_wdata(trace_wdata));
endmodule
