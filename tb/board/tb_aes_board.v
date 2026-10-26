`timescale 1ns / 1ps
module tb_aes_board;
    reg clk=0;always #5 clk=~clk;
    wire [7:0] led;
    zedboard_aes_demo #(.HEARTBEAT_HALF_PERIOD(4),.TIMEOUT_CYCLES(20000)) board(.clk_100mhz(clk),.led(led));
    reg rst=1,mmio_valid=0,mmio_write=0,mmio_ready=1,mmio_error=0,halted=0,trace_valid=0,trace_rd_we=1;
    reg [31:0] mmio_addr=0,mmio_wdata=0,mmio_rdata=0,trace_wdata=0;
    reg [3:0] mmio_wstrb=0,fault_code=0;
    reg [1:0] mmio_size=2;
    reg [4:0] trace_rd=31;
    wire done,failed;
    wire [3:0] first_failure;
    aes_smoke_monitor #(.TIMEOUT_CYCLES(200)) checker_dut(.*);
    reg board_checked=0,prev;
    integer checks=0,b,w,i,changes;
    reg [127:0] ct;
    task reset_checker;
        begin
            @(negedge clk);rst=1;mmio_valid=0;trace_valid=0;halted=0;mmio_error=0;fault_code=0;
            mmio_size=2;mmio_ready=1;mmio_wstrb=0;trace_rd=31;trace_rd_we=1;
            repeat(2) @(negedge clk);
            if({done,failed,first_failure}!==0) $fatal(1,"FAIL AES checker reset");
            rst=0;
        end
    endtask
    task transfer;
        input wr;
        input [31:0] address,data;
        begin
            @(negedge clk);mmio_valid=1;mmio_write=wr;mmio_addr=address;
            mmio_wdata=data;mmio_rdata=data;mmio_wstrb=wr?15:0;
            @(posedge clk);#1;@(negedge clk);mmio_valid=0;
        end
    endtask
    task report_status;
        input [31:0] status;
        begin @(negedge clk);trace_valid=1;trace_wdata=status;@(posedge clk);#1;@(negedge clk);trace_valid=0;end
    endtask
    task expect_failure;
        input [3:0] wanted;
        begin
            if(done!==1 || failed!==1 || first_failure!==wanted) $fatal(1,"FAIL AES monitor expected %h got %h",wanted,first_failure);
            checks=checks+1;
        end
    endtask
    task healthy;
        integer lane;
        reg [31:0] value;
        begin
            for(b=0;b<4;b=b+1) begin
                transfer(1,32'h40000000,1);
                case(b)
                    0,1:ct=128'h69c4e0d86a7b0430d8cdb78070b4c55a;
                    2:ct=128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
                    3:ct=128'h3925841d02dc09fbdc118597196a0b32;
                endcase
                for(w=0;w<4;w=w+1) begin
                    for(lane=0;lane<4;lane=lane+1) value[8*lane +: 8]=ct[127-8*(4*w+lane) -: 8];
                    transfer(0,32'h40000030+4*w,value);
                end
            end
            if(done!==0) $fatal(1,"FAIL early AES monitor pass");
            report_status(1);
            if(done!==1 || failed!==0 || first_failure!==0) $fatal(1,"FAIL healthy AES monitor");
            checks=checks+1;
        end
    endtask
    initial begin
        reset_checker;healthy;
        repeat(210) @(negedge clk);
        if(failed!==0) $fatal(1,"FAIL timeout after pass");
        transfer(1,32'h40000000,1);expect_failure(10);
        halted=1;fault_code=7;@(posedge clk);#1;expect_failure(10);
        reset_checker;report_status(1);expect_failure(10);
        reset_checker;report_status(2);expect_failure(12);
        reset_checker;report_status(3);expect_failure(13);
        reset_checker;transfer(1,32'h40000000,1);transfer(0,32'h40000030,0);expect_failure(9);
        reset_checker;transfer(0,32'h40000030,32'hd8e0c469);expect_failure(9);
        reset_checker;transfer(1,32'h40000000,1);transfer(0,32'h40000034,32'hd8e0c469);expect_failure(9);
        reset_checker;mmio_error=1;transfer(0,32'h40000004,0);expect_failure(8);
        reset_checker;halted=1;fault_code=6;@(posedge clk);#1;expect_failure(6);
        reset_checker;repeat(201) @(negedge clk);expect_failure(11);
        reset_checker;
        @(negedge clk);mmio_valid=1;mmio_write=1;mmio_addr=32'h40000000;mmio_wdata=1;mmio_wstrb=15;mmio_ready=0;
        repeat(5) @(negedge clk);
        if(checker_dut.starts!==0) $fatal(1,"FAIL monitor counted uncompleted request");
        reset_checker;healthy;
        wait(board_checked);
        $display("PASS tb_aes_board: four actual CPU-driven blocks, reset/restart, heartbeat/LEDs, %0d monitor scenarios",checks);$finish;
    end
    initial begin
        wait(led[1]);@(negedge clk);
        if(led[7:1]!==7'b0000001 || board.soc.system.ram.words[16]!==1) $fatal(1,"FAIL actual AES board");
        prev=led[0];changes=0;
        repeat(16) begin @(negedge clk);if(led[0]!==prev) changes=changes+1;prev=led[0];end
        if(changes!=4) $fatal(1,"FAIL AES heartbeat");
        @(negedge clk);force board.halted=1;force board.fc=7;
        @(posedge clk);#1;
        if(led[7:1]!==7'b0111010) $fatal(1,"FAIL AES failure LEDs");
        @(negedge clk);release board.halted;release board.fc;force board.rst=1;
        repeat(3) @(negedge clk);
        if(led[7:1]!==0) $fatal(1,"FAIL AES board reset");
        release board.rst;wait(led[1]);@(negedge clk);
        if(led[7:1]!==7'b0000001) $fatal(1,"FAIL AES restart");
        board_checked=1;
    end
    initial begin #500000;$fatal(1,"FAIL AES board watchdog");end
endmodule
