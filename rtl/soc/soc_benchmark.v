`timescale 1ns/1ps
// Development-only firmware comparison. No change to the working display SoC.
module soc_benchmark #(parameter ROM_FILE="benchmark.hex",WAIT_CYCLES=1)(
    input wire clk,rst,output wire halted);
    wire valid,write,ready,error;wire [31:0] addr,wd,rd;wire [3:0] ws;wire [1:0] size;
    wire aes_sel=addr[31:8]==24'h400000;
    wire timer_sel=addr==32'h40000380;
    wire ar,ae,tr,te;wire [31:0] ad,td;
    assign ready=aes_sel?ar:timer_sel?tr:1'b1;
    assign error=aes_sel?ae:timer_sel?te:1'b1;
    assign rd=aes_sel?ad:timer_sel?td:32'b0;
    soc_minimal #(.ROM_FILE(ROM_FILE)) system(.clk(clk),.rst(rst),.halted(halted),
        .mmio_valid(valid),.mmio_write(write),.mmio_addr(addr),.mmio_wdata(wd),
        .mmio_wstrb(ws),.mmio_size(size),.mmio_ready(ready),.mmio_error(error),.mmio_rdata(rd));
    aes_mmio #(.WAIT_CYCLES(WAIT_CYCLES)) aes(.clk(clk),.rst(rst),.valid(valid && aes_sel),
        .write(write),.addr(addr),.wdata(wd),.wstrb(ws),.size(size),.ready(ar),.error(ae),.rdata(ad));
    benchmark_timer timer(.clk(clk),.rst(rst),.valid(valid && timer_sel),.write(write),
        .addr(addr),.wstrb(ws),.size(size),.ready(tr),.error(te),.rdata(td));
endmodule
