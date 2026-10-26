`timescale 1ns / 1ps
module tb_cpu_board;
    reg clk=0;
    always #5 clk=~clk;
    wire [7:0] led;
    zedboard_cpu_demo #(.HEARTBEAT_HALF_PERIOD(4), .TIMEOUT_CYCLES(2000)) board (
        .clk_100mhz(clk), .led(led));

    // A separately driven monitor verifies that the checker can reject faults.
    reg rst=1, mv=0, mw=1, halted=0, tv=0, twe=0;
    reg [31:0] ma=32'h40000000, md=56, tp=0, tw=0;
    reg [3:0] ms=15, fc=0;
    reg [1:0] size=2;
    reg [4:0] tr=0;
    wire ready, done, failed;
    wire [3:0] failure;
    cpu_smoke_monitor #(.TIMEOUT_CYCLES(100)) monitor_under_test (
        .clk(clk), .rst(rst), .mmio_valid(mv), .mmio_write(mw), .mmio_addr(ma),
        .mmio_wdata(md), .mmio_wstrb(ms), .mmio_size(size), .mmio_ready(ready),
        .halted(halted), .fault_code(fc), .trace_valid(tv), .trace_pc(tp),
        .trace_rd_we(twe), .trace_rd(tr), .trace_wdata(tw),
        .done(done), .failed(failed), .first_failure(failure));
    integer checks=0, transfers=0, board_transfers=0, board_cycles=0;
    integer i, changes;
    reg previous_heartbeat;
    reg board_checked=0;
    always @(posedge clk) begin
        if (rst) transfers=0;
        else if (mv && ready) transfers=transfers+1;
        if (!board.rst && board.mv && board.mr) board_transfers=board_transfers+1;
    end

    task reset_checker;
        begin
            @(negedge clk); rst=1; mv=0; tv=0; halted=0; fc=0;
            ma=32'h40000000; md=56; mw=1; ms=15; size=2;
            repeat(2) @(negedge clk);
            if (done !== 0 || failed !== 0 || failure !== 0 || ready !== 0)
                $fatal(1,"FAIL checker reset");
            rst=0;
        end
    endtask
    task retire;
        input [31:0] pc, value;
        input [4:0] rd;
        input we;
        begin
            @(negedge clk); tv=1; tp=pc; tw=value; tr=rd; twe=we;
            @(posedge clk); #1;
            @(negedge clk); tv=0;
        end
    endtask
    task signature;
        integer waited;
        begin
            @(negedge clk); mv=1; waited=0;
            while (ready !== 1) begin
                @(negedge clk); waited=waited+1;
                if (waited>10) $fatal(1,"FAIL response stuck");
            end
            if (waited!=5) $fatal(1,"FAIL expected five wait cycles, got %0d",waited);
            @(posedge clk); #1;
            @(negedge clk); mv=0;
        end
    endtask
    task expect_failure;
        input [3:0] expected;
        begin
            if (done !== 1 || failed !== 1 || failure !== expected)
                $fatal(1,"FAIL expected diagnostic %h got %h",expected,failure);
            checks=checks+1;
        end
    endtask
    task good_run;
        begin
            retire(32'h1c,55,4,1);
            retire(32'h20,56,5,1);
            signature;
            repeat(4) retire(32'h30,0,0,0);
            if (done !== 0) $fatal(1,"FAIL premature PASS");
            retire(32'h30,0,0,0);
            if (done !== 1 || failed !== 0 || failure !== 0 || transfers!=1)
                $fatal(1,"FAIL healthy monitor");
            checks=checks+1;
        end
    endtask

    initial begin
        reset_checker; good_run;
        // Continuing to execute the final loop must not duplicate the MMIO write.
        repeat(110) @(negedge clk);
        if (failed !== 0) $fatal(1,"FAIL timeout after successful completion");
        signature; expect_failure(9);
        @(negedge clk); halted=1; fc=3;
        @(posedge clk); #1; expect_failure(9); // preserve the first failure

        reset_checker; md=57; signature; expect_failure(8);
        reset_checker; ma=32'h40000100; signature; expect_failure(8);
        reset_checker; mw=0; signature; expect_failure(8);
        reset_checker; ms=4'h3; signature; expect_failure(8);
        reset_checker; size=1; signature; expect_failure(8);
        reset_checker; retire(32'h1c,54,4,1); expect_failure(10);
        reset_checker; retire(32'h20,56,6,1); expect_failure(10);
        reset_checker; retire(32'h1c,55,4,0); expect_failure(10);
        reset_checker; retire(32'h30,0,0,0); expect_failure(12);
        reset_checker;
        @(negedge clk); halted=1; fc=6;
        @(posedge clk); #1; expect_failure(6);
        reset_checker;
        repeat(101) @(negedge clk);
        expect_failure(11);
        // Reset before a delayed write completes cancels it and resets wait age.
        reset_checker;
        @(negedge clk); mv=1;
        repeat(3) @(negedge clk);
        if (ready !== 0 || transfers!=0) $fatal(1,"FAIL early MMIO completion");
        reset_checker; good_run;
        wait(board_checked);
        $display("PASS tb_cpu_board: actual CPU/ROM/RAM, LED mapping, heartbeat, reset/restart, %0d checker scenarios",checks);
        $finish;
    end

    initial begin
        wait(!board.rst);
        while (led[1] !== 1 && board_cycles<2000) begin
            @(negedge clk); board_cycles=board_cycles+1;
            if (led[2]) $fatal(1,"FAIL healthy board diagnostic %h",led[7:4]);
        end
        if (led[7:1] !== 7'b0000001 || board_transfers!=1 ||
            board.soc.ram.words[0] !== 55 || board.soc.ram.words[1] !== 56)
            $fatal(1,"FAIL actual board program or LEDs");
        previous_heartbeat=led[0]; changes=0;
        for(i=0;i<16;i=i+1) begin
            @(negedge clk);
            if(led[0] !== previous_heartbeat) changes=changes+1;
            previous_heartbeat=led[0];
        end
        if(changes!=4) $fatal(1,"FAIL board heartbeat");
        // Feed a real CPU fault into the board status after PASS.
        @(negedge clk); force board.halted=1; force board.fc=7;
        @(posedge clk); #1;
        if(led[7:1] !== 7'b0111010) $fatal(1,"FAIL board failure LEDs");
        @(negedge clk); release board.halted; release board.fc;
        // Same synchronous reset source is shared by CPU, RAM handshake and monitor.
        force board.rst=1;
        repeat(3) @(negedge clk);
        if(led[7:1] !== 0) $fatal(1,"FAIL LEDs during reset");
        release board.rst; board_transfers=0;
        wait(led[1]); @(negedge clk);
        if(led[7:1] !== 7'b0000001 || board_transfers!=1)
            $fatal(1,"FAIL board restart");
        board_checked=1;
    end
    initial begin #100000; $fatal(1,"FAIL board test watchdog"); end
endmodule
