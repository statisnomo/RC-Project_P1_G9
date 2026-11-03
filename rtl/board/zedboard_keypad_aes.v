`timescale 1ns / 1ps
// PL-only lab top. JA signals indexed by logical ROW/COL number minus one.
module zedboard_keypad_aes #(
    parameter ROM_FILE="keypad_aes.hex", parameter COLUMN_CYCLES=25000,
    parameter DEBOUNCE_FRAMES=20, parameter WAIT_CYCLES=1
)(input wire clk_100mhz,input wire [3:0] rows_n,output wire [3:0] cols_n,output wire [7:0] led);
    reg [15:0] startup=16'hffff;
    wire rst=startup[15];
    wire clk=clk_100mhz;
    wire v,w,kr,ke,ar,ae,tv,we,halted;
    wire [31:0] addr,wd,kd,ad,trace_data;
    wire [3:0] ws,drive;
    wire [1:0] size;
    wire [4:0] rd;
    wire ksel=addr[31:8]==24'h400001, asel=addr[31:8]==24'h400000;
    genvar c;
    generate for(c=0;c<4;c=c+1) begin: pads
        assign cols_n[c]=drive[c]?1'b0:1'bz;
    end endgenerate
    soc_minimal #(.ROM_FILE(ROM_FILE)) system (.clk(clk),.rst(rst),
        .mmio_valid(v),.mmio_write(w),.mmio_addr(addr),.mmio_wdata(wd),.mmio_wstrb(ws),.mmio_size(size),
        .mmio_ready(ksel?kr:asel?ar:1'b1),.mmio_rdata(ksel?kd:asel?ad:32'b0),.mmio_error(ksel?ke:asel?ae:1'b1),
        .halted(halted),.trace_valid(tv),.trace_rd_we(we),.trace_rd(rd),.trace_wdata(trace_data));
    keypad_mmio #(.COLUMN_CYCLES(COLUMN_CYCLES),.DEBOUNCE_FRAMES(DEBOUNCE_FRAMES),.WAIT_CYCLES(WAIT_CYCLES))
        keypad(.clk(clk),.rst(rst),.valid(v&&ksel),.write(w),.addr(addr),.wdata(wd),.wstrb(ws),.size(size),
               .ready(kr),.rdata(kd),.error(ke),.rows_n(rows_n),.col_drive_low(drive));
    aes_mmio #(.WAIT_CYCLES(WAIT_CYCLES)) aes(.clk(clk),.rst(rst),.valid(v&&asel),.write(w),.addr(addr),
        .wdata(wd),.wstrb(ws),.size(size),.ready(ar),.rdata(ad),.error(ae));
    reg [26:0] ticks=0;
    reg [3:0] digit;
    reg event_toggle,block_toggle;
    always @(posedge clk) begin
        startup<={startup[14:0],1'b0};
        if(rst) begin ticks<=0;digit<=0;event_toggle<=0;block_toggle<=0;end
        else begin
            ticks<=ticks+1'b1;
            if(tv && we && rd==12) begin digit<=trace_data[3:0];event_toggle<=~event_toggle;end
            if(tv && we && rd==31) block_toggle<=~block_toggle;
        end
    end
    assign led={halted,ticks[26],block_toggle,event_toggle,digit};
endmodule
