`timescale 1ns / 1ps
module tb_alu_selftest;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1;
    wire done, failed;
    wire [3:0] first_failure;
    wire bad_done, bad_failed;
    wire [3:0] bad_first;
    wire zero_done, zero_failed;
    wire [3:0] zero_first;
    wire [7:0] led;
    integer i, transitions, tested_vectors;
    reg last_heartbeat;

    alu_selftest good (.clk(clk), .rst(rst), .done(done), .failed(failed),
                       .first_failure(first_failure));
    alu_selftest bad (.clk(clk), .rst(rst), .done(bad_done), .failed(bad_failed),
                      .first_failure(bad_first));
    alu_selftest bad_zero (.clk(clk), .rst(rst), .done(zero_done), .failed(zero_failed),
                           .first_failure(zero_first));
    zedboard_alu_demo #(.HEARTBEAT_HALF_PERIOD(4)) board (.clk_100mhz(clk), .led(led));

    // Count real CHECK phases to catch early-done and skipped-vector bugs.
    always @(posedge clk) begin
        if (rst)
            tested_vectors = 0;
        else if (good.check_phase && !done)
            tested_vectors = tested_vectors + 1;
    end

    initial begin
        // Inject two bad results; the first index must remain latched.
        wait (!rst);
        wait (bad.check_phase && bad.test_index == 8);
        @(negedge clk);
        force bad.alu_result = 32'hdeadbeef;
        @(posedge clk); #1;
        release bad.alu_result;
        wait (bad.check_phase && bad.test_index == 12);
        @(negedge clk);
        force bad.alu_result = 32'hdeadbeef;
        @(posedge clk); #1;
        release bad.alu_result;
    end

    initial begin
        wait (!rst);
        wait (bad_zero.check_phase && bad_zero.test_index == 1);
        @(negedge clk);
        force bad_zero.alu_zero = 1'b0;
        @(posedge clk); #1;
        release bad_zero.alu_zero;
    end

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        wait (done && bad_done && zero_done);
        #1;
        if (failed !== 0 || first_failure !== 0 || tested_vectors != 16)
            $fatal(1, "FAIL healthy selftest or vector count");
        if (bad_failed !== 1 || bad_first !== 8)
            $fatal(1, "FAIL sticky first result-failure detection");
        if (zero_failed !== 1 || zero_first !== 1)
            $fatal(1, "FAIL zero-flag fault detection");

        // Reset must clear done/failure and allow a clean rerun.
        @(negedge clk); rst = 1;
        @(posedge clk); #1;
        if (done !== 0 || failed !== 0 || bad_failed !== 0 || bad_first !== 0)
            $fatal(1, "FAIL synchronous reset");
        @(negedge clk); rst = 0;
        wait (done && bad_done && zero_done); #1;
        if (failed !== 0 || bad_failed !== 0 || zero_failed !== 0 || tested_vectors != 16)
            $fatal(1, "FAIL clean rerun after reset");

        wait (board.done); #1;
        if (led[7:1] !== 7'b0000001)
            $fatal(1, "FAIL board pass/fail/busy LED mapping");
        transitions = 0;
        last_heartbeat = led[0];
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk); #1;
            if (led[0] !== last_heartbeat) transitions = transitions + 1;
            last_heartbeat = led[0];
        end
        if (transitions != 4)
            $fatal(1, "FAIL heartbeat period");
        $display("PASS tb_alu_selftest: 16 vectors, result/zero fault injection, sticky failure, reset rerun, board LEDs, heartbeat");
        $finish;
    end

    initial begin
        #20000;
        $fatal(1, "FAIL selftest timeout");
    end
endmodule
