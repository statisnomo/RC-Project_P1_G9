`timescale 1ns/1ps
// Combined development image: JA keypad, JC external OLED, JD1 UART TX.
module zedboard_display #(
    parameter ROM_FILE="display.hex",COLUMN_CYCLES=25000,DEBOUNCE_FRAMES=20,
    RESET_CYCLES=100000,PANEL_CYCLES=10000000,HALF_SPI=20
)(input wire clk_100mhz,input wire [3:0] rows_n,output wire [3:0] cols_n,
    output wire cs_n,mosi,sclk,dc,res_n,vbat_n,vdd_n,tx,output wire [7:0] led);
    reg [15:0] startup=16'hffff;
    wire rst=startup[15];
    wire [3:0] drive,digit;
    wire key_event,block_event,halted;
    reg [26:0] ticks=0;
    reg [3:0] saved_digit=0;
    reg key_toggle=0,block_toggle=0;
    genvar c;
    generate for(c=0;c<4;c=c+1) begin:pads
        assign cols_n[c]=drive[c] ? 1'b0 : 1'bz;
    end endgenerate
    soc_display #(.ROM_FILE(ROM_FILE),.COLUMN_CYCLES(COLUMN_CYCLES),.DEBOUNCE_FRAMES(DEBOUNCE_FRAMES),
        .RESET_CYCLES(RESET_CYCLES),.PANEL_CYCLES(PANEL_CYCLES),.HALF_SPI(HALF_SPI)) soc(
        .clk(clk_100mhz),.rst(rst),.rows_n(rows_n),.col_drive_low(drive),
        .cs_n(cs_n),.mosi(mosi),.sclk(sclk),.dc(dc),.res_n(res_n),.vbat_n(vbat_n),.vdd_n(vdd_n),
        .tx(tx),.halted(halted),.key_event(key_event),.block_event(block_event),.last_digit(digit));
    always @(posedge clk_100mhz) begin
        startup<={startup[14:0],1'b0};
        if(rst) begin ticks<=0;saved_digit<=0;key_toggle<=0;block_toggle<=0;end
        else begin
            ticks<=ticks+1'b1;
            if(key_event) begin saved_digit<=digit;key_toggle<=~key_toggle;end
            if(block_event) block_toggle<=~block_toggle;
        end
    end
    // While powered off, LD1 is the shutdown-complete indicator.
    assign led=(!rst && vdd_n) ? {halted,ticks[26],4'b0,2'b10} :
                               {halted,ticks[26],block_toggle,key_toggle,saved_digit};
endmodule

