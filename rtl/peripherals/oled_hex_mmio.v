`timescale 1ns/1ps
// Ciphertext display for the 128x32 external Pmod. Word-only MMIO; see docs/oled_hex.md.
module oled_hex_mmio #(parameter RESET_CYCLES=100000,PANEL_CYCLES=10000000,
                        DISCHARGE_CYCLES=350000000,HALF_SPI=20)(
    input wire clk,rst,valid,write,input wire [31:0] addr,wdata,
    input wire [3:0] wstrb,input wire [1:0] size,
    output reg ready,output reg [31:0] rdata,output reg error,
    output wire cs_n,mosi,dc,res_n,vbat_n,vdd_n,output reg sclk
);
    localparam RESET_LOW=0,SETTLE=1,INIT=2,CLEAR=3,WAIT_PANEL=4,ON=5,
               IDLE=6,FRAME=7,STOP=8,DISCHARGE=9,OFF=10;
    localparam LOAD=0,SHIFT=1,HOLD=2,GAP=3;
    reg [3:0] state;
    reg [1:0] spi;
    reg [8:0] index;
    reg [31:0] delay_count;
    reg [2:0] bitno;
    reg [7:0] shift;
    reg [127:0] staging,frame;
    reg request_bad,request_write,request_data,request_ctrl,request_status;
    reg [1:0] request_index;
    reg [31:0] request_value;
    reg bad_access;
    wire idle=state==IDLE, off=state==OFF;
    wire send=state==INIT || state==CLEAR || state==ON || state==FRAME || state==STOP;
    wire data_reg=addr[7:4]==1;
    wire complete=valid && ready && !error && !rst;
    wire ctrl=complete && request_ctrl;
    // Power switches must not pulse while the multibit FSM changes state.
    reg logic_off,panel_off;
    assign vdd_n=rst || logic_off;
    assign vbat_n=rst || panel_off;
    always @(posedge clk) begin
        if(rst) begin logic_off<=0;panel_off<=1;end
        else begin
            if(state==CLEAR && spi==GAP && index==511) panel_off<=0;
            if(state==STOP && spi==GAP) panel_off<=1;
            if(state==DISCHARGE && delay_count==DISCHARGE_CYCLES-1) logic_off<=1;
            if(off && ctrl) logic_off<=0;
        end
    end
    assign res_n=vdd_n ? 1'bz : state!=RESET_LOW;
    assign cs_n=vdd_n ? 1'bz : !(send && (spi==SHIFT || spi==HOLD));
    assign dc=vdd_n ? 1'bz : state==CLEAR || state==FRAME;
    assign mosi=vdd_n ? 1'bz : shift[7];

    always @* begin
        rdata=0;
        bad_access=addr[31:8]!=24'h400002 || addr[1:0]!=0 || size!=2 ||
              (write ? wstrb!=4'hf : wstrb!=0);
        if(!data_reg) case(addr[7:0])
            0:if(write) bad_access=1;
            4:if(write && wdata!=1 && wdata!=2 && wdata!=4) bad_access=1;
            default:bad_access=1;
        endcase
        error=request_bad || (request_ctrl && !((idle && (request_value==1 || request_value==2)) ||
                                               (off && request_value==4)));
        if(!request_write && !error) begin
            if(request_data) rdata=staging[32*request_index+:32];
            else if(request_status) rdata={30'b0,off,idle};
        end
    end
    always @(posedge clk) begin
        if(rst) begin
            ready<=0;staging<=0;frame<=0;request_bad<=0;request_write<=0;
            request_data<=0;request_ctrl<=0;request_status<=0;request_index<=0;request_value<=0;
        end
        else begin
            ready<=valid && !ready;
            if(valid && !ready) begin
                request_bad<=bad_access;request_write<=write;request_data<=data_reg;
                request_ctrl<=write && addr[7:0]==4;request_status<=addr[7:0]==0;
                request_index<=addr[3:2];request_value<=wdata;
            end
            if(complete && request_write && request_data) staging[32*request_index+:32]<=request_value;
            if(ctrl && request_value==1) frame<=staging;
        end
    end

    function [7:0] init_byte(input [4:0] i);
        reg [175:0] seq;
        begin
            // Horizontal addressing: columns 0..127, pages 0..3, wraps each 512 bytes.
            seq=176'hae8d14d9f1a81fda02a1c8813fa6200021007f220003;
            init_byte=seq[175-8*i-:8];
        end
    endfunction
    function [39:0] columns(input [3:0] n);
        case(n) // five columns left-to-right, bit 0 at the top
            0:columns=40'h3e5149453e; 1:columns=40'h00427f4000;
            2:columns=40'h4261514946; 3:columns=40'h2141454b31;
            4:columns=40'h1814127f10; 5:columns=40'h2745454539;
            6:columns=40'h3c4a494930; 7:columns=40'h0171090503;
            8:columns=40'h3649494936; 9:columns=40'h064949291e;
            10:columns=40'h7e0909097e; 11:columns=40'h7f49494936;
            12:columns=40'h3e41414122; 13:columns=40'h7f4141221c;
            14:columns=40'h7f49494941; default:columns=40'h7f09090901;
        endcase
    endfunction
    wire [3:0] byte_index={index[8],index[6:4]}; // pages 1,2: bytes 0..7,8..15
    wire [7:0] current_byte=frame[8*byte_index+:8];
    wire [39:0] glyph=columns(index[3] ? current_byte[3:0] : current_byte[7:4]);
    wire text_page=index[8]^index[7];
    wire [7:0] bitmap=(text_page && index[2:0]<5) ? glyph[39-8*index[2:0]-:8] : 0;
    wire [7:0] payload=state==INIT ? init_byte(index[4:0]) : state==FRAME ? bitmap :
                       state==ON ? 8'haf : state==STOP ? 8'hae : 0;

    always @(posedge clk) begin
        if(rst) begin state<=RESET_LOW;spi<=LOAD;index<=0;sclk<=0;shift<=0;bitno<=0;delay_count<=0;end
        else if(send) case(spi)
            LOAD:begin shift<=payload;bitno<=0;spi<=SHIFT;end
            SHIFT:if(delay_count==HALF_SPI-1) begin
                delay_count<=0;sclk<=~sclk;
                if(sclk) begin
                    if(bitno==7) spi<=HOLD;
                    else begin bitno<=bitno+1'b1;shift<={shift[6:0],1'b0};end
                end
            end else delay_count<=delay_count+1'b1;
            HOLD:spi<=GAP;
            GAP:begin
                spi<=LOAD;index<=index+1'b1;
                case(state)
                    INIT:if(index==21) begin index<=0;state<=CLEAR;end
                    CLEAR:if(index==511) state<=WAIT_PANEL;
                    ON,FRAME:if(state==ON || index==511) begin state<=IDLE;index<=0;end
                    STOP:begin state<=DISCHARGE;index<=0;end
                endcase
            end
        endcase
        else case(state)
            RESET_LOW,SETTLE,WAIT_PANEL,DISCHARGE:begin
                if(delay_count==(state==WAIT_PANEL ? PANEL_CYCLES : state==DISCHARGE ? DISCHARGE_CYCLES : RESET_CYCLES)-1) begin
                    delay_count<=0;
                    case(state)
                        RESET_LOW:state<=SETTLE; SETTLE:state<=INIT;
                        WAIT_PANEL:state<=ON; DISCHARGE:state<=OFF;
                    endcase
                end else delay_count<=delay_count+1'b1;
            end
            IDLE:if(ctrl) state<=request_value==1 ? FRAME : STOP;
            OFF:if(ctrl) state<=RESET_LOW;
        endcase
    end
endmodule
