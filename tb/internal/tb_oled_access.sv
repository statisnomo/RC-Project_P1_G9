`timescale 1ns/1ps
module tb_oled_access;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,v=0,w=0;reg [31:0] a=0,d=0;reg [1:0] size=2;reg [3:0] lanes=0;
    wire ready,err,cs,sd,dc,res,vbat,vdd,sck;wire [31:0] rd;
    oled_hex_mmio #(.RESET_CYCLES(12),.PANEL_CYCLES(32),.DISCHARGE_CYCLES(37),.HALF_SPI(2))
        dut(clk,rst,v,w,a,d,lanes,size,ready,rd,err,cs,sd,dc,res,vbat,vdd,sck);
    localparam BASE=32'h40000200;
    integer ops=0,edge_count=0,panel_edge,last_reset; reg [7:0] byte_rx,last_cmd;integer bits=0;
    always @(posedge clk) edge_count++;
    always @(posedge sck) if(!rst) begin byte_rx={byte_rx[6:0],sd};bits++;end
    always @(posedge cs) if(!rst && bits) begin
        if(bits!=8) $fatal(1,"FAIL partial command");
        if(!dc) begin last_cmd=byte_rx;
            if(last_cmd==8'haf && edge_count-panel_edge<32) $fatal(1,"FAIL panel on delay");end
        bits=0;
    end
    always @(negedge vbat) panel_edge=edge_count;
    always @(posedge vbat) if(!rst) begin
        if(last_cmd!==8'hae || vdd!==0) $fatal(1,"FAIL shutdown ordering");panel_edge=edge_count;
    end
    always @(posedge vdd) if(!rst && edge_count-panel_edge<37) $fatal(1,"FAIL discharge");
    always @(negedge res) last_reset=edge_count;
    always @(posedge res) if(!rst && vdd===0 && edge_count-last_reset<12) $fatal(1,"FAIL short reset");
    task automatic access_bus(input bit wr,input [31:0] addr,input [31:0] data,input [3:0] strobes,
        input [1:0] sz,input bit bad,input [31:0] expected);
        @(negedge clk);v=1;w=wr;a=addr;d=data;lanes=strobes;size=sz;
        @(negedge clk);
        if(ready!==1 || err!==bad || (!wr && !bad && rd!==expected)) $fatal(1,"FAIL MMIO addr=%h read=%h err=%b",a,rd,err);
        @(negedge clk);v=0;ops++;
    endtask
    initial begin
        repeat(3) @(negedge clk);rst=0;
        access_bus(1,BASE+4,1,15,2,1,0); // cannot start during init
        access_bus(0,BASE,0,0,2,0,0);
        access_bus(1,BASE+16,32'h11223344,15,2,0,0);
        access_bus(1,BASE+16,0,3,2,1,0);
        access_bus(1,BASE+16,0,15,0,1,0);
        access_bus(1,BASE+17,0,15,2,1,0);
        access_bus(1,BASE+256+16,0,15,2,1,0);
        access_bus(1,BASE+8,0,15,2,1,0);
        access_bus(1,BASE,0,15,2,1,0);
        @(negedge clk);v=1;w=1;a=BASE+16;d=0;lanes=15;size=2;
        @(negedge clk);v=0; // cancel before completion edge
        access_bus(0,BASE+16,0,0,2,0,32'h11223344);
        wait(dut.idle);access_bus(0,BASE,0,0,2,0,1);
        access_bus(1,BASE+4,3,15,2,1,0);
        access_bus(1,BASE+4,1,15,2,0,0);
        access_bus(1,BASE+4,2,15,2,1,0);
        access_bus(1,BASE+4,1,15,2,1,0);
        wait(dut.idle);access_bus(1,BASE+4,2,15,2,0,0);
        wait(vdd===1);access_bus(0,BASE,0,0,2,0,2);
        access_bus(1,BASE+4,1,15,2,1,0);
        access_bus(1,BASE+4,4,15,2,0,0);
        wait(dut.idle);access_bus(0,BASE,0,0,2,0,1);
        $display("PASS tb_oled_access: %0d bus operations, cancellation, busy/invalid writes, discharge and restart",ops);$finish;
    end
    initial begin #1900000;$fatal(1,"FAIL MMIO timeout");end
endmodule
