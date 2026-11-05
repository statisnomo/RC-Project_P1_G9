`timescale 1ns/1ps
module tb_benchmark_timer;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,v=0,w=0;reg [31:0] a=32'h40000380;reg [3:0] ws=0;reg [1:0] size=2;
    wire ready,err;wire [31:0] data;
    benchmark_timer dut(clk,rst,v,w,a,ws,size,ready,err,data);
    integer reads=0;
    task read_tick(input bit expected_error);
        reg [31:0] snapshot;
        @(negedge clk);v=1;snapshot=dut.cycles;
        @(posedge clk);#1;
        if(ready!==1 || err!==expected_error || data!==snapshot) $fatal(1,"FAIL timer snapshot");
        reads++;
        @(negedge clk);v=0;
        @(posedge clk);#1;if(ready!==0) $fatal(1,"FAIL timer cancellation");
    endtask
    initial begin
        repeat(3) @(negedge clk);rst=0;
        read_tick(0);repeat(19) @(negedge clk);read_tick(0);
        w=1;read_tick(1);w=0;
        a=32'h40000384;read_tick(1);a=32'h40000380;
        size=0;read_tick(1);size=2;ws=1;read_tick(1);ws=0;
        // Continuous valid: one response every second edge, snapshots remain stable.
        @(negedge clk);v=1;
        repeat(4) begin
            @(posedge clk);#1;if(!ready || err) $fatal(1,"FAIL timer held request");
            @(posedge clk);#1;if(ready) $fatal(1,"FAIL timer duplicate response");
        end
        @(negedge clk);v=0;rst=1;
        @(posedge clk);#1;if(ready || data!=0 || dut.cycles!=0) $fatal(1,"FAIL timer reset");
        @(negedge clk);rst=0;
        // Force only the initial count, then let the counter wrap naturally.
        dut.cycles=32'hfffffffe;
        read_tick(0);read_tick(0);
        if(dut.cycles>10) $fatal(1,"FAIL timer wrap");
        $display("PASS tb_benchmark_timer: snapshots, invalid accesses, held requests, cancellation, reset and 32-bit wrap");$finish;
    end
    initial begin #10000;$fatal(1,"FAIL timer watchdog");end
endmodule
