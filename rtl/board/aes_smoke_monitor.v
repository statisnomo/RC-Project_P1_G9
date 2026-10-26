`timescale 1ns / 1ps
// Independent observer for the four known blocks in fw/aes_smoke.hex.
// It does not drive the bus or compute AES; every returned word is checked.
module aes_smoke_monitor #(parameter integer TIMEOUT_CYCLES=1000000) (
    input wire clk,input wire rst,
    input wire mmio_valid,input wire mmio_write,input wire mmio_ready,input wire mmio_error,
    input wire [31:0] mmio_addr,input wire [31:0] mmio_wdata,input wire [31:0] mmio_rdata,
    input wire [3:0] mmio_wstrb,input wire [1:0] mmio_size,
    input wire halted,input wire [3:0] fault_code,
    input wire trace_valid,input wire trace_rd_we,input wire [4:0] trace_rd,input wire [31:0] trace_wdata,
    output reg done,output reg failed,output reg [3:0] first_failure
);
    reg [31:0] elapsed;
    reg [2:0] starts;
    reg [4:0] words_read;
    reg [31:0] expected_word;
    wire transfer=mmio_valid && mmio_ready;
    wire start_event=transfer && mmio_write && mmio_addr==32'h40000000 && mmio_wstrb[0] && mmio_wdata[0];
    wire ct_event=transfer && !mmio_write && mmio_addr[31:4]==28'h4000003;
    wire report_event=trace_valid && trace_rd_we && trace_rd==31 && trace_wdata!=0;
    reg [3:0] detected;
    always @* begin
        case(words_read)
            0,4:expected_word=32'hd8e0c469;
            1,5:expected_word=32'h30047b6a;
            2,6:expected_word=32'h80b7cdd8;
            3,7:expected_word=32'h5ac5b470;
            8:expected_word=32'hd44be966;
            9:expected_word=32'h3b2c8aef;
            10:expected_word=32'h59fa4c88;
            11:expected_word=32'h2e2b34ca;
            12:expected_word=32'h1d842539;
            13:expected_word=32'hfb09dc02;
            14:expected_word=32'h978511dc;
            15:expected_word=32'h320b6a19;
            default:expected_word=0;
        endcase
        detected=0;
        if(halted) detected=(fault_code!=0)?fault_code:4'hf;
        else if(transfer && mmio_error) detected=8;
        else if(ct_event && (words_read>=16 || mmio_size!=2 || mmio_wstrb!=0 ||
                mmio_addr[3:0]!={words_read[1:0],2'b00} || mmio_rdata!=expected_word ||
                starts!={1'b0,words_read[3:2]}+3'd1)) detected=9;
        else if(start_event && (starts>=4 || mmio_size!=2 || mmio_wstrb!=15 || mmio_wdata!=1)) detected=10;
        else if(report_event) begin
            if(trace_wdata==2) detected=12;
            else if(trace_wdata==3) detected=13;
            else if(trace_wdata!=1 || starts!=4 || words_read!=16) detected=10;
        end
        if(detected==0 && !done && elapsed>=TIMEOUT_CYCLES-1) detected=11;
    end
    always @(posedge clk) begin
        if(rst) begin elapsed<=0;starts<=0;words_read<=0;done<=0;failed<=0;first_failure<=0;end
        else begin
            if(!done) elapsed<=elapsed+1'b1;
            if(start_event && starts<7) starts<=starts+1'b1;
            if(ct_event && words_read<31) words_read<=words_read+1'b1;
            if(report_event && trace_wdata==1 && starts==4 && words_read==16 && detected==0) done<=1;
            if(!failed && detected!=0) begin done<=1;failed<=1;first_failure<=detected;end
        end
    end
endmodule
