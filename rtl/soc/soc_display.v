`timescale 1ns/1ps
// Development integration top; external keypad pad enables are active high.
// Physical wrappers for the November lab deliberately remain independent.
module soc_display #(parameter ROM_FILE="display.hex",parameter COLUMN_CYCLES=25000,
    DEBOUNCE_FRAMES=20,WAIT_CYCLES=1,CLKS_PER_BIT=868,RESET_CYCLES=100000,
    PANEL_CYCLES=10000000,DISCHARGE_CYCLES=350000000,HALF_SPI=20)(
    input wire clk,rst,input wire [3:0] rows_n,output wire [3:0] col_drive_low,
    output wire cs_n,mosi,sclk,dc,res_n,vbat_n,vdd_n,tx,halted,
    output wire key_event,block_event,output wire [3:0] last_digit);
    wire v,w;wire [31:0] addr,wd;wire [3:0] ws;wire [1:0] size;
    wire [3:0] ready,err;
    wire [31:0] readback[0:3];
    wire [1:0] portnum=addr[9:8]; // soc_minimal qualifies v with full 1 KiB window
    wire trace_valid,trace_we;
    wire [4:0] trace_rd;
    wire [31:0] trace_data;
    assign key_event=trace_valid && trace_we && trace_rd==12;
    assign block_event=trace_valid && trace_we && trace_rd==31;
    assign last_digit=trace_data[3:0]; // Sample only when key_event is asserted.
    soc_minimal #(.ROM_FILE(ROM_FILE)) system(.clk(clk),.rst(rst),.halted(halted),
        .trace_valid(trace_valid),.trace_rd_we(trace_we),.trace_rd(trace_rd),.trace_wdata(trace_data),
        .mmio_valid(v),.mmio_write(w),.mmio_addr(addr),.mmio_wdata(wd),.mmio_wstrb(ws),
        .mmio_size(size),.mmio_ready(ready[portnum]),.mmio_error(err[portnum]),.mmio_rdata(readback[portnum]));
    aes_mmio #(.WAIT_CYCLES(WAIT_CYCLES)) aes(.clk(clk),.rst(rst),.valid(v && portnum==0),.write(w),
        .addr(addr),.wdata(wd),.wstrb(ws),.size(size),.ready(ready[0]),.error(err[0]),.rdata(readback[0]));
    keypad_mmio #(.COLUMN_CYCLES(COLUMN_CYCLES),.DEBOUNCE_FRAMES(DEBOUNCE_FRAMES),.WAIT_CYCLES(WAIT_CYCLES))
        keypad(.clk(clk),.rst(rst),.valid(v && portnum==1),.write(w),.addr(addr),.wdata(wd),.wstrb(ws),
            .size(size),.ready(ready[1]),.error(err[1]),.rdata(readback[1]),.rows_n(rows_n),.col_drive_low(col_drive_low));
    oled_hex_mmio #(.RESET_CYCLES(RESET_CYCLES),.PANEL_CYCLES(PANEL_CYCLES),
        .DISCHARGE_CYCLES(DISCHARGE_CYCLES),.HALF_SPI(HALF_SPI)) oled(
        .clk(clk),.rst(rst),.valid(v && portnum==2),.write(w),.addr(addr),.wdata(wd),.wstrb(ws),
        .size(size),.ready(ready[2]),.error(err[2]),.rdata(readback[2]),
        .cs_n(cs_n),.mosi(mosi),.sclk(sclk),.dc(dc),.res_n(res_n),.vbat_n(vbat_n),.vdd_n(vdd_n));
    uart_mmio #(.CLKS_PER_BIT(CLKS_PER_BIT),.WAIT_CYCLES(WAIT_CYCLES)) uart(
        .clk(clk),.rst(rst),.valid(v && portnum==3),.write(w),.addr(addr),.wdata(wd),.wstrb(ws),
        .size(size),.ready(ready[3]),.error(err[3]),.rdata(readback[3]),.tx(tx));
endmodule
