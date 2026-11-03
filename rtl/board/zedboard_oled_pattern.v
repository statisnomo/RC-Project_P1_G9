`timescale 1ns/1ps
// Standalone external Pmod OLED bring-up. One frame, then timed shutdown.
module zedboard_oled_pattern #(
    parameter RESET_CYCLES=100000, PANEL_CYCLES=10000000,
    parameter VIEW_CYCLES=800000000, DISCHARGE_CYCLES=350000000,
    parameter HALF_SPI=20
)(input wire clk_100mhz,output wire cs_n,mosi,output reg sclk=0,
  output wire dc,res_n,vbat_n,vdd_n,output wire [7:0] led);
    localparam POWER=0, RESET_LOW=1, SETTLE=2, LOAD=3,SHIFT=4,GAP=5,
               PANEL=6, VIEW=7, DISCHARGE=8, OFF=9, FINISH_BYTE=10;
    reg [3:0] state=POWER;
    reg [31:0] timer=0;
    reg [10:0] idx=0;
    reg [7:0] shift=0;
    reg [2:0] bitnum=0;
    reg panel_off=1;
    localparam INIT_BYTES=22, ON=INIT_BYTES+512, LAST=ON+513;
    function [7:0] command(input [4:0] i);
        case(i)
            0:command=8'hae; 1:command=8'h8d; 2:command=8'h14;
            3:command=8'hd9; 4:command=8'hf1; 5:command=8'ha8; 6:command=31;
            7:command=8'hda; 8:command=8'h02; 9:command=8'ha1; 10:command=8'hc8;
            11:command=8'h81; 12:command=8'h3f; 13:command=8'ha6;
            14:command=8'h20; 15:command=0; // Horizontal addressing, then entire window.
            16:command=8'h21; 17:command=0; 18:command=127;
            19:command=8'h22; 20:command=0; default:command=3;
        endcase
    endfunction
    wire [8:0] pixel_byte=idx-(ON+1);
    wire [7:0] payload=idx<INIT_BYTES ? command(idx[4:0]) :
        idx<ON ? 8'h00 : idx==ON ? 8'haf : idx==LAST ? 8'hae :
        (pixel_byte[3]^pixel_byte[7]) ? 8'hff : 8'h00;
    wire sending=state==SHIFT || state==FINISH_BYTE;
    assign vdd_n=(state==POWER || state==OFF);
    assign vbat_n=panel_off;
    assign cs_n=vdd_n ? 1'bz : !sending;
    assign mosi=vdd_n ? 1'bz : shift[7];
    assign dc=vdd_n ? 1'bz : ((idx>=INIT_BYTES && idx<ON) || (idx>ON && idx<LAST));
    assign res_n=vdd_n ? 1'bz : state!=RESET_LOW;
    assign led={6'b0,state==OFF,state==VIEW};
    always @(posedge clk_100mhz) begin
        case(state)
            POWER: state<=RESET_LOW;
            RESET_LOW,SETTLE,PANEL,VIEW,DISCHARGE:begin
                if(timer==(state==VIEW ? VIEW_CYCLES : state==PANEL ? PANEL_CYCLES :
                           state==DISCHARGE ? DISCHARGE_CYCLES : RESET_CYCLES)-1) begin
                    timer<=0;
                    case(state)
                        RESET_LOW:state<=SETTLE;
                        DISCHARGE:state<=OFF;
                        default:state<=LOAD;
                    endcase
                end else timer<=timer+1'b1;
            end
            LOAD:begin shift<=payload;state<=SHIFT;bitnum<=0;timer<=0;end
            SHIFT:if(timer==HALF_SPI-1) begin
                timer<=0;sclk<=~sclk;
                if(sclk) begin
                    if(bitnum==7) state<=FINISH_BYTE;
                    else begin shift<={shift[6:0],1'b0};bitnum<=bitnum+1'b1;end
                end
            end else timer<=timer+1'b1;
            FINISH_BYTE:state<=GAP;
            GAP:begin
                idx<=idx+1'b1;
                if(idx==ON-1) begin panel_off<=0;state<=PANEL;end
                else if(idx==LAST-1) state<=VIEW;
                else if(idx==LAST) begin panel_off<=1;state<=DISCHARGE;end
                else state<=LOAD;
            end
            default:state<=OFF;
        endcase
    end
endmodule
