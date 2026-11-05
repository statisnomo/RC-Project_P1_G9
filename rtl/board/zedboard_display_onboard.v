`timescale 1ns/1ps
// Same tested SoC and firmware as the JA/JC demo, routed to onboard DISP1.
// DISP1 CS# is tied low on the PCB: do not export or constrain a CS port.
module zedboard_display_onboard #(
    parameter ROM_FILE="display.hex",COLUMN_CYCLES=25000,DEBOUNCE_FRAMES=20,
    RESET_CYCLES=100000,PANEL_CYCLES=10000000,HALF_SPI=20
)(input wire clk_100mhz,input wire [3:0] rows_n,output wire [3:0] cols_n,
    output wire mosi,sclk,dc,res_n,vbat_n,vdd_n,tx,output wire [7:0] led);
    zedboard_display #(.ROM_FILE(ROM_FILE),.COLUMN_CYCLES(COLUMN_CYCLES),
        .DEBOUNCE_FRAMES(DEBOUNCE_FRAMES),.RESET_CYCLES(RESET_CYCLES),
        .PANEL_CYCLES(PANEL_CYCLES),.HALF_SPI(HALF_SPI)) demo(
        .clk_100mhz(clk_100mhz),.rows_n(rows_n),.cols_n(cols_n),.cs_n(),
        .mosi(mosi),.sclk(sclk),.dc(dc),.res_n(res_n),.vbat_n(vbat_n),
        .vdd_n(vdd_n),.tx(tx),.led(led));
endmodule
